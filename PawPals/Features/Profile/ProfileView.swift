import PhotosUI
import SwiftUI

struct ProfileView: View {

    let user: User
    let isOwner: Bool
    @Binding var selectedTab: Tab

    @Environment(\.dismiss) private var dismiss
    @Environment(ChatViewModel.self) private var chatViewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(ProfileViewModel.self) private var profileViewModel
    @Environment(MeetViewModel.self) private var meetViewModel
    @State private var conversationViewModel = ConversationViewModel(conversationRepository: ConversationService())
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
                    HStack(spacing: Spacing.medium) {
                        if isOwner {
                            PhotosPicker(
                                selection: $selectedPhoto,
                                matching: .images
                            ) {
                                AvatarView(
                                    photoURL: displayUser.photoURL,
                                    size: IconSize.avatar,
                                    iconSize:
                                        IconSize.avatarIcon
                                )
                            }
                            .buttonStyle(.plain)
                            .contentShape(Circle())

                        } else {
                            AvatarView(
                                photoURL: displayUser.photoURL,
                                size: IconSize.avatar,
                                iconSize:
                                    IconSize.avatarIcon
                            )
                        }

                        VStack(alignment: .leading, spacing: Spacing.xSmall) {

                            Text(displayUser.name)

                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.darkBrown)

                            HStack(spacing: Spacing.xSmall) {
                                Image(systemName: "pawprint")
                                    .font(.caption2)
                                Text(displayUser.city)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Theme.warmBrown)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, Spacing.small)

                    Section {
                        Text(displayUser.bio)
                            .font(.callout)
                            .foregroundStyle(Theme.darkBrown)
                            .listRowBackground(Theme.offWhite.opacity(0.6))

                        if !displayUser.preferences.walkTypes.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Spacing.small) {
                                    ForEach(displayUser.preferences.walkTypes) {
                                        walkType in
                                        WalkTypeTag(walkType: walkType)
                                    }
                                }
                            }
                            .listRowBackground(Theme.offWhite.opacity(0.6))
                        }
                    } header: {
                        SectionHeader(title: "profile.aboutUs")
                    }

                    if !displayUser.dogs.isEmpty {
                        Section {
                            ForEach(displayUser.dogs) { dog in
                                VStack(
                                    alignment: .leading,
                                    spacing: Spacing.xSmall
                                ) {
                                    Text(dog.name)
                                        .fontWeight(.medium)
                                    Text(dog.breed)
                                        .font(.caption)
                                        .foregroundStyle(Theme.warmBrown)
                                }
                                .listRowBackground(Theme.offWhite.opacity(0.6))
                            }
                        } header: {
                            SectionHeader(title: displayUser.dogs.count == 1 ? "profile.dog" : "profile.dogs")
                        }
                    }

                    if isOwner && !meetViewModel.savedUsers.isEmpty {
                        Section {
                            ForEach(meetViewModel.savedUsers) { savedUser in
                                HStack(spacing: Spacing.medium) {
                                    AvatarView(
                                        photoURL: savedUser.photoURL,
                                        size: IconSize.savedAvatar,
                                        iconSize:
                                            IconSize.avatarIcon
                                    )
                                    VStack(
                                        alignment: .leading,
                                        spacing: Spacing.xSmall
                                    ) {
                                        Text(savedUser.name).fontWeight(.medium)
                                        Text(savedUser.city)
                                            .font(.caption)
                                            .foregroundStyle(Theme.warmBrown)
                                    }
                                }
                                .listRowBackground(Theme.offWhite.opacity(0.6))
                            }
                        } header: {
                            SectionHeader(title: "profile.savedProfiles")                        }
                    }

                    if !isOwner {
                        Button {
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
                        } label: {
                            Text("profile.start.chat")
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.offWhite)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.terracotta)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: Radius.medium
                                    )
                                )
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
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
                        let data = try? await selectedPhoto.loadTransferable(
                            type: Data.self
                        )
                    else { return }
                    await profileViewModel.uploadProfilePhoto(data)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if isOwner {
                        TabBarView(selectedTab: $selectedTab)
                    }
                }

                if showSidebar {
                    VStack(alignment: .leading, spacing: Spacing.large) {
                        Text("profile.editProfile")
                            .foregroundStyle(Theme.darkBrown)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showSidebar = false
                                showEditProfile = true
                            }

                        Divider()

                        Spacer()

                        Divider()

                        Text("profile.logOut")
                            .foregroundStyle(Theme.terracotta)
                            .contentShape(Rectangle())
                            .onTapGesture {

                                showSidebar = false
                                showLogoutConfirm = true
                            }

                        Text("profile.deleteAccount")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showSidebar = false
                                showDeleteConfirm = true
                            }
                        Spacer()
                    }
                    .padding(.top, Spacing.sidebarTop)
                    .padding(.horizontal, Spacing.large)
                    .containerRelativeFrame(
                        .horizontal,
                        count: 3,
                        span: 2,
                        spacing: Spacing.none
                    )
                    .frame(maxHeight: .infinity)
                    .background(Theme.offWhite)
                    .ignoresSafeArea()
                    .transition(.move(edge: .trailing))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isOwner {
                        Button {
                            withAnimation { showSidebar.toggle() }
                        } label: {
                            Label(
                                "menu",
                                systemImage: showSidebar
                                    ? "xmark" : "line.3.horizontal"
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
                                await meetViewModel.toggleSave(
                                    targetID: user.id
                                )
                            }
                        } label: {
                            Image(
                                systemName: meetViewModel.savedUserIDs.contains(
                                    user.id
                                ) ? "heart.fill" : "heart"
                            )
                            .foregroundStyle(Theme.terracotta)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showEditProfile) {
                AddProfileSheet(user: profileViewModel.user)
            }
            .navigationDestination(item: $chatVM.activeConversation) {
                conversation in
                ConversationView(
                    conversation: conversation,
                    currentUserID: authViewModel.currentUserID,
                    otherUser: chatViewModel.otherUser(
                        in: conversation,
                        currentUserID: authViewModel.currentUserID
                    ) ?? .mock
                )
                .environment(conversationViewModel)
            }
            .onChange(of: chatViewModel.activeConversation) { _, newValue in
                /// User navigated back without sending — clean up the draft state.
                if newValue == nil {
                    chatViewModel.isActiveConversationNew = false
                    conversationViewModel.isNew = false
                    conversationViewModel.onCreate = nil
                }
            }
            .alert(
                "profile.deleteAccount.title",
                isPresented: $showDeleteConfirm
            ) {
                Button("profile.deleteAccount.confirm", role: .destructive) {
                    Task { await authViewModel.deleteAccount() }
                }
                Button("sheet.cancel", role: .cancel) {}
            } message: {
                Text("profile.deleteAccount.message")
            }
            .alert(
                "profile.logout.title",
                isPresented: $showLogoutConfirm
            ) {
                Button("profile.logout.confirm", role: .destructive) {
                    authViewModel.signOut()
                }
                Button("sheet.cancel", role: .cancel) {}
            } message: {
                Text("profile.logout.message")
            }
        }
        .environment(profileViewModel)
    }
}

#Preview("Owner") {
    ProfileView(user: .mock, isOwner: true, selectedTab: .constant(.profile))
        .environment(
            ChatViewModel(
                chatRepository: MockChatRepository(),
                profileRepository: MockProfileRepository(),
                meetRepository: MockMeetRepository()
            )
        )
        .environment(
            AuthViewModel(
                repository: MockAuthRepository(),
                profileRepository: MockProfileRepository()
            )
        )
        .environment(
            ProfileViewModel(profileRepository: MockProfileRepository(), user: .mock)
        )
        .environment(MeetViewModel(locationViewModel: LocationViewModel()))
}

#Preview("Visitor") {
    NavigationStack {
        ProfileView(
            user: .mock,
            isOwner: false,
            selectedTab: .constant(.profile)
        )
    }
    .environment(
        ChatViewModel(
            chatRepository: MockChatRepository(),
            profileRepository: MockProfileRepository(),
            meetRepository: MockMeetRepository()
        )
    )
    .environment(
        AuthViewModel(
            repository: MockAuthRepository(),
            profileRepository: MockProfileRepository()
        )
    )
    .environment(
        ProfileViewModel(profileRepository: MockProfileRepository(), user: .mock)
    )
    .environment(MeetViewModel(locationViewModel: LocationViewModel()))
}
