import SwiftUI
import PhotosUI

struct ProfileView: View {

    let user: User
    let isOwner: Bool
    @Binding var selectedTab: Tab

    @Environment(\.dismiss) private var dismiss
    @Environment(ChatViewModel.self) private var chatViewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showSidebar = false
    @State private var showEditProfile = false

    var body: some View {
        @Bindable var chatVM = chatViewModel

        NavigationStack {
            ZStack(alignment: .trailing) {
                Theme.appBackground
                    .ignoresSafeArea()

                List {
                    HStack(spacing: Spacing.medium) {
                        if isOwner {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                avatarCircle
                            }
                        } else {
                            avatarCircle
                        }

                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(user.dogs.first != nil ? "\(user.name) / \(user.dogs.first!.name)" : user.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.darkBrown)

                            HStack(spacing: Spacing.xSmall) {
                                Image(systemName: "pawprint")
                                    .font(.caption2)
                                Text(user.city)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Theme.warmBrown)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, Spacing.small)

                    Section {
                        Text(user.bio)
                            .font(.callout)
                            .foregroundStyle(Theme.darkBrown)
                            .listRowBackground(Theme.offWhite.opacity(0.6))
                    } header: {
                        Text("profile.aboutUs")
                            .font(.subheadline)
                            .foregroundStyle(Theme.darkBrown)
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
                                .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
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
                    }
                    .padding(.top, Spacing.sidebarTop)
                    .padding(.horizontal, Spacing.large)
                    .containerRelativeFrame(.horizontal, count: 3, span: 2, spacing: Spacing.none)
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
                            Label("menu", systemImage: showSidebar ? "xmark" : "line.3.horizontal")
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
            }
            .navigationDestination(isPresented: $showEditProfile) {
                AddProfileSheet()
            }
            .navigationDestination(item: $chatVM.activeConversation) { conversation in
                ConversationView(conversation: conversation, currentUserID: authViewModel.currentUserId)
            }
        }
    }

    private var avatarCircle: some View {
        Circle()
            .fill(Theme.lightPeach)
            .frame(width: IconSize.avatar, height: IconSize.avatar)
            .overlay {
                Image(systemName: "person")
                    .font(.system(size: IconSize.avatarIcon))
                    .foregroundStyle(Theme.offWhite)
            }
    }
}

#Preview("Owner") {
    ProfileView(user: .mock, isOwner: true, selectedTab: .constant(.profile))
        .environment(ChatViewModel(repository: MockChatRepository()))
        .environment(AuthViewModel(repository: MockAuthRepository()))
}

#Preview("Visitor") {
    NavigationStack {
        ProfileView(user: .mock, isOwner: false, selectedTab: .constant(.profile))
    }
    .environment(ChatViewModel(repository: MockChatRepository()))
    .environment(AuthViewModel(repository: MockAuthRepository()))
}

private struct MockAuthRepository: AuthRepository {
    func signUp(email: String, password: String) async throws -> User {
        User(id: "preview", name: "", photoURL: nil, bio: "", city: "",
             dogs: [], preferences: UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10),
             distance: nil)
    }
    func signUpWithGoogle() async throws {}
}

private struct MockChatRepository: ChatRepository {
    func fetchConversations(for userId: String) async throws -> [Conversation] { [] }
    func sendMessage(_ message: Message, to conversationID: String) async throws {}
    func observeMessages(conversationID: String, onUpdate: @escaping ([Message]) -> Void) -> (() -> Void) { return {} }
    func createOrFetchConversation(between userId1: String, and userId2: String) async throws -> Conversation {
        Conversation(id: "mock", participantIDs: [userId1, userId2], lastMessage: "", lastMessageTimestamp: Date())
    }
}
