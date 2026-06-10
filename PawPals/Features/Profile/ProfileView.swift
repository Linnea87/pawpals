import PhotosUI
import SwiftUI

struct ProfileView: View {

    let user: User
    let isOwner: Bool
    let cameFromMeet: Bool
    @Binding var selectedTab: Tab

    @Environment(\.dismiss) private var dismiss
    @Environment(ChatViewModel.self) private var chatViewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(MeetViewModel.self) private var meetViewModel
    @State private var conversationViewModel = ConversationViewModel(
        conversationRepository: ConversationService()
    )
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showSidebar = false
    @State private var showEditProfile = false
    @State private var showDeleteConfirm = false
    @State private var showLogoutConfirm = false

    private var displayUser: User {
        isOwner ? profileViewModel.user : user
    }

    var body: some View {
        @Bindable var chatVM = chatViewModel

        NavigationStack {
            ZStack(alignment: .trailing) {
                Theme.appBackground
                    .ignoresSafeArea()

                List {
                    ProfileHeaderView(
                        user: displayUser,
                        isOwner: isOwner,
                        selectedPhoto: $selectedPhoto
                    )

                    AboutSection(user: displayUser)

                    DogsSection(dogs: displayUser.dogs)

                    if isOwner {
                        SavedProfilesSection(savedUsers: meetViewModel.savedUsers)
                    }

                    /// Only show when arriving from Meet (new contact) — hidden when
                    /// opening a profile from an existing Conversation.
                    if !isOwner && cameFromMeet {
                        StartChatButton {
                            Task {
                                await chatViewModel.startConversation(
                                    with: user,
                                    currentUserID: authViewModel.currentUserID
                                )
                                /// If the conversation is new, configure ConversationViewModel for lazy creation.
                                if chatViewModel.isActiveConversationNew {
                                    conversationViewModel.isNew = true
                                    conversationViewModel.onCreate = {
                                        try await chatViewModel.createActiveConversation()
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .task {
                    if isOwner {
                        await profileViewModel.loadPreferences()
                        await meetViewModel.loadSavedProfiles()
                    }
                }
                .task(id: selectedPhoto) {
                    guard let selectedPhoto,
                        let data = try? await selectedPhoto.loadTransferable(type: Data.self)
                    else { return }
                    await profileViewModel.uploadProfilePhoto(data)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if isOwner {
                        TabBarView(selectedTab: $selectedTab)
                    }
                }

                if showSidebar {
                    SideBarView(
                        onEditProfile: {
                            showSidebar = false
                            showEditProfile = true
                        },
                        onLogout: {
                            showSidebar = false
                            showLogoutConfirm = true
                        },
                        onDeleteAccount: {
                            showSidebar = false
                            showDeleteConfirm = true
                        }
                    )
                }
            }
            .toolbar {
                profileToolbar
            }
            .navigationDestination(isPresented: $showEditProfile) {
                AddProfileSheet(user: profileViewModel.user)
            }
            .navigationDestination(item: $chatVM.activeConversation) { conversation in
                ConversationView(
                    conversation: conversation,
                    currentUserID: authViewModel.currentUserID,
                    otherUser: chatViewModel.otherUser(
                        in: conversation,
                        currentUserID: authViewModel.currentUserID
                    ) ?? .mock,
                    isModal: true,
                    selectedTab: $selectedTab
                )
                .environment(conversationViewModel)
            }
            .onChange(of: chatViewModel.activeConversation) { _, newValue in
                /// User navigated back without sending — clean up the draft state.
                if newValue == nil {
                    chatViewModel.isActiveConversationNew = false
                    conversationViewModel.isNew = false
                    conversationViewModel.onCreate = nil
                    if !isOwner {
                        selectedTab = .chat
                        dismiss()
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(400))
                            selectedTab = .chat
                        }
                    }
                }
            }
            .profileAlerts(
                showDeleteConfirm: $showDeleteConfirm,
                showLogoutConfirm: $showLogoutConfirm,
                onDelete: {
                    Task { await authViewModel.deleteAccount() }
                },
                onLogout: {
                    authViewModel.signOut()
                }
            )
        }
        .environment(profileViewModel)
    }

    @ToolbarContentBuilder
    private var profileToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if isOwner {
                Button {
                    withAnimation { showSidebar.toggle() }
                } label: {
                    Label(
                        "menu",
                        systemImage: showSidebar ? "xmark" : "line.3.horizontal"
                    )
                    .labelStyle(.iconOnly)
                }
            } else {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(Theme.warmBrown)
                }
            }
        }
        if !isOwner {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task {
                        await meetViewModel.toggleSave(targetID: user.id)
                    }
                } label: {
                    Image(
                        systemName: meetViewModel.savedUserIDs.contains(user.id)
                            ? "heart.fill" : "heart"
                    )
                    .foregroundStyle(Theme.terracotta)
                }
            }
        }
    }
}

#Preview("Owner") {
    ProfileView(user: .mock, isOwner: true, cameFromMeet: false, selectedTab: .constant(.profile))
        .profilePreviewEnvironments()
}

#Preview("Visitor") {
    NavigationStack {
        ProfileView(user: .mock, isOwner: false, cameFromMeet: true, selectedTab: .constant(.profile))
    }
    .profilePreviewEnvironments()
}
