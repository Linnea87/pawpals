import PhotosUI
import SwiftUI

struct ProfileView: View {

    let user: User
    let isOwner: Bool
    let cameFromMeet: Bool
    
    @Binding var selectedTab: Tab

    @Environment(\.dismiss) private var dismiss
    @Environment(ChatViewModel.self) private var chatVM
    @Environment(AuthViewModel.self) private var authVM
    @Environment(ProfileViewModel.self) private var profileVM
    @Environment(MeetViewModel.self) private var meetVM
    
    @State private var conversationVM = ConversationViewModel(
        conversationRepository: ConversationService()
    )
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showSidebar = false
    @State private var showEditProfile = false
    @State private var showDeleteConfirm = false
    @State private var showLogoutConfirm = false
    @State private var selectedSavedUser: User?

    private var displayUser: User {
        isOwner ? profileVM.user : user
    }

    var body: some View {
        @Bindable var chatVM = chatVM

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
                        SavedProfilesSection(savedUsers: meetVM.savedUsers) { user in
                            selectedSavedUser = user
                        }
                    }

                    /// Only show when arriving from Meet (new contact) — hidden when
                    /// opening a profile from an existing Conversation.
                    if !isOwner && cameFromMeet {
                        StartChatButton {
                            Task {
                                await chatVM.startConversation(
                                    with: user,
                                    currentUserID: authVM.currentUserID
                                )
                                /// If the conversation is new, configure ConversationViewModel for lazy creation.
                                if chatVM.isActiveConversationNew {
                                    conversationVM.isNew = true
                                    conversationVM.onCreate = {
                                        try await chatVM.createActiveConversation()
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
                        await profileVM.loadPreferences()
                        await meetVM.loadSavedProfiles(currentUserID: authVM.currentUserID)
                    }
                }
                .task(id: selectedPhoto) {
                    guard let selectedPhoto,
                        let data = try? await selectedPhoto.loadTransferable(type: Data.self)
                    else { return }
                    await profileVM.uploadProfilePhoto(data)
                }
                .safeAreaInset(edge: .bottom, spacing: Spacing.none) {
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
                AddProfileSheet(user: profileVM.user)
            }
            .sheet(item: $selectedSavedUser) { savedUser in
                ProfileView(user: savedUser, isOwner: false, cameFromMeet: false, selectedTab: $selectedTab)
                    .environment(meetVM)
            }
            .navigationDestination(item: $chatVM.activeConversation) { conversation in
                ConversationView(
                    conversation: conversation,
                    currentUserID: authVM.currentUserID,
                    otherUser: chatVM.otherUser(
                        in: conversation,
                        currentUserID: authVM.currentUserID
                    ) ?? .mock,
                    isModal: true,
                    selectedTab: $selectedTab
                )
                .environment(conversationVM)
            }
            .onChange(of: chatVM.activeConversation) { _, newValue in
                /// User navigated back without sending — clean up the draft state.
                if newValue == nil {
                    chatVM.isActiveConversationNew = false
                    conversationVM.isNew = false
                    conversationVM.onCreate = nil
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
                    Task { await authVM.deleteAccount() }
                },
                onLogout: {
                    authVM.signOut()
                }
            )
        }
        .environment(profileVM)
    }

    @ToolbarContentBuilder
    private var profileToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if isOwner {
                Button {
                    withAnimation { showSidebar.toggle() }
                } label: {
                    Label(
                        "common.menu",
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
                        await meetVM.toggleSave(targetID: user.id, currentUserID: authVM.currentUserID)
                    }
                } label: {
                    Image(
                        systemName: meetVM.savedUserIDs.contains(user.id)
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
