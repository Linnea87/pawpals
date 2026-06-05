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
                                avatarCircle
                            }
                            .buttonStyle(.plain)
                            .contentShape(Circle())

                        } else {
                            avatarCircle
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
                                        Text(walkType.rawValue)
                                            .font(.caption)
                                            .padding(.horizontal, Spacing.small)
                                            .padding(.vertical, Spacing.xSmall)
                                            .background(Theme.terracotta)
                                            .foregroundStyle(Theme.offWhite)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .listRowBackground(Theme.offWhite.opacity(0.6))
                        }
                    } header: {
                        Text("profile.aboutUs")
                            .font(.subheadline)
                            .foregroundStyle(Theme.darkBrown)
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
                            Text(
                                displayUser.dogs.count == 1
                                    ? "profile.dog" : "profile.dogs"
                            )
                            .font(.subheadline)
                            .foregroundStyle(Theme.darkBrown)
                        }
                    }

                    if isOwner && !profileViewModel.savedUsers.isEmpty {
                        Section {
                            ForEach(profileViewModel.savedUsers) { savedUser in
                                HStack(spacing: Spacing.medium) {
                                    Circle()
                                        .fill(Theme.lightPeach)
                                        .frame(width: 40, height: 40)
                                        .overlay {
                                            Image(systemName: "person.fill")
                                                .foregroundStyle(Theme.offWhite)
                                        }
                                    VStack(
                                        alignment: .leading,
                                        spacing: Spacing.xSmall
                                    ) {
                                        Text(
                                            "\(savedUser.name) / \(savedUser.dogs.first?.name ?? "")"
                                        )
                                        .fontWeight(.medium)
                                        Text(savedUser.city)
                                            .font(.caption)
                                            .foregroundStyle(Theme.warmBrown)
                                    }
                                }
                                .listRowBackground(Theme.offWhite.opacity(0.6))
                            }
                        } header: {
                            Text("profile.savedProfiles")
                                .font(.subheadline)
                                .foregroundStyle(Theme.darkBrown)
                        }
                    }

                    if !isOwner {
                        Button {
                            Task {
                                await chatViewModel.startConversation(
                                    with: user,
                                    currentUserId: authViewModel.currentUserId
                                )
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
                        await profileViewModel.loadSavedProfiles()
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
                                    targetId: user.id
                                )
                            }
                        } label: {
                            Image(
                                systemName: meetViewModel.savedUserIds.contains(
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
                    currentUserID: authViewModel.currentUserId,
                    otherUser: chatViewModel.otherUser(in: conversation, currentUserID: authViewModel.currentUserId) ?? .mock
                )
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

    private var avatarCircle: some View {
        Circle()
            .fill(Theme.lightPeach)
            .frame(width: IconSize.avatar, height: IconSize.avatar)
            .overlay {
                if let photoURL = displayUser.photoURL,
                    let url = URL(string: photoURL)
                {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person")
                            .font(.system(size: IconSize.avatarIcon))
                            .foregroundStyle(Theme.offWhite)
                    }
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person")
                        .font(.system(size: IconSize.avatarIcon))
                        .foregroundStyle(Theme.offWhite)
                }
            }
    }
}

#Preview("Owner") {
    ProfileView(user: .mock, isOwner: true, selectedTab: .constant(.profile))
        .environment(ChatViewModel(chatRepository: MockChatRepository(), userRepository: MockUserRepository()))
        .environment(AuthViewModel(repository: MockAuthRepository(), userRepository: MockUserRepository()))
        .environment(
            ProfileViewModel(userRepository: MockUserRepository(), user: .mock)
        )
        .environment(MeetViewModel(locationService: LocationService()))
}

#Preview("Visitor") {
    NavigationStack {
        ProfileView(
            user: .mock,
            isOwner: false,
            selectedTab: .constant(.profile)
        )
    }
    .environment(ChatViewModel(chatRepository: MockChatRepository(), userRepository: MockUserRepository()))
    .environment(AuthViewModel(repository: MockAuthRepository(), userRepository: MockUserRepository()))
    .environment(
        ProfileViewModel(userRepository: MockUserRepository(), user: .mock)
    )
    .environment(MeetViewModel(locationService: LocationService()))
}

private struct MockAuthRepository: AuthRepository {
    func signUp(email: String, password: String) async throws -> User {
        User(
            id: "preview",
            name: "",
            photoURL: nil,
            bio: "",
            city: "",
            dogs: [],
            preferences: UserPreferences(
                walkTypes: [],
                dogSize: .medium,
                searchRadius: 10
            ),
            distance: nil
        )
    }
    func signUpWithGoogle() async throws -> User {
        User(
            id: "preview",
            name: "",
            photoURL: nil,
            bio: "",
            city: "",
            dogs: [],
            preferences: UserPreferences(
                walkTypes: [],
                dogSize: .medium,
                searchRadius: 10
            ),
            distance: nil
        )
    }
    func signOut() throws {}
    func signIn(email: String, password: String) async throws -> User {
        User(
            id: "preview",
            name: "",
            photoURL: nil,
            bio: "",
            city: "",
            dogs: [],
            preferences: UserPreferences(
                walkTypes: [],
                dogSize: .medium,
                searchRadius: 10
            ),
            distance: nil
        )
    }
    func signInWithGoogle() async throws -> User {
        User(
            id: "preview",
            name: "",
            photoURL: nil,
            bio: "",
            city: "",
            dogs: [],
            preferences: UserPreferences(
                walkTypes: [],
                dogSize: .medium,
                searchRadius: 10
            ),
            distance: nil
        )
    }

    func deleteAccount() async throws {}
}

private struct MockChatRepository: ChatRepository {
    func sendMessage(_ message: Message, to conversationID: String) async throws
    {}
    func observeMessages(
        conversationID: String,
        onUpdate: @escaping ([Message]) -> Void
    ) -> (() -> Void) { return {} }
    func createOrFetchConversation(between userId1: String, and userId2: String)
        async throws -> Conversation
    {
        Conversation(
            id: "mock",
            participantIDs: [userId1, userId2],
            lastMessage: "",
            lastMessageTimestamp: Date()
        )
    }
    func markAsRead(conversationID: String, userID: String) async throws {}
    func markAsDelivered(conversationID: String, userID: String) async throws {}
    func observeConversations(for userID: String, onUpdate: @escaping ([Conversation]) -> Void) -> (() -> Void) { return {} }
    func signIn(email: String, password: String) async throws -> User {
        User(
            id: "preview",
            name: "",
            photoURL: nil,
            bio: "",
            city: "",
            dogs: [],
            preferences: UserPreferences(
                walkTypes: [],
                dogSize: .medium,
                searchRadius: 10
            ),
            distance: nil
        )
    }
    func signInWithGoogle() async throws -> User {
        User(
            id: "preview",
            name: "",
            photoURL: nil,
            bio: "",
            city: "",
            dogs: [],
            preferences: UserPreferences(
                walkTypes: [],
                dogSize: .medium,
                searchRadius: 10
            ),
            distance: nil
        )
    }

    // Mock implementation — required by ChatRepository protocol (PP-028)
    // Not used in ChatView, added only to satisfy protocol conformance
    func uploadImage(_ image: UIImage, conversationId: String) async throws -> URL {
        return URL(string: "https://mock-image-url.com/image.jpg")!
    }
    func deleteUserData(userId: String) async throws {}
    func uploadProfilePhoto(_ data: Data, userId: String) async throws -> String
    { "" }
}
