import SwiftUI

private enum ChatFilter: CaseIterable {
    case all, unread, favorite

    var label: LocalizedStringKey {
        switch self {
        case .all: return "chat.filter.all"
        case .unread: return "chat.filter.unread"
        case .favorite: return "chat.filter.favorite"
        }
    }
}

struct ChatView: View {
    @Binding var selectedTab: Tab
    @Environment(ChatViewModel.self) private var chatViewModel
    @State private var selectedFilter: ChatFilter = .all
    @State private var navigationPath = NavigationPath() /// Controls which conversation is currently pushed onto the navigation stack.
    var currentUserID: String = ""

    private var filteredConversations: [Conversation] {
        switch selectedFilter {
        case .all: return chatViewModel.conversations
        case .unread:
            return chatViewModel.conversations.filter { $0.unreadCount > 0 }
        case .favorite: return []
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Theme.appBackground
                    .ignoresSafeArea()

                VStack(spacing: Spacing.none) {
                    filterTabs

                    if chatViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredConversations.isEmpty {
                        ContentUnavailableView(
                            "chat.noConversations",
                            systemImage: "bubble.left.and.bubble.right"
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(filteredConversations) { conversation in
                            ZStack {
                                NavigationLink(value: conversation) {
                                    EmptyView()
                                }
                                .opacity(0)
                                ConversationRowView(
                                    conversation: conversation,
                                    timestampText:
                                        chatViewModel.formattedTimeStamp(
                                            for: conversation
                                        )
                                )
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(
                                EdgeInsets(
                                    top: Spacing.small,
                                    leading: Spacing.medium,
                                    bottom: Spacing.small,
                                    trailing: Spacing.medium
                                )
                            )
                        }
                        .scrollContentBackground(.hidden)
                        .navigationDestination(for: Conversation.self) {
                            conversation in
                            ConversationView(
                                conversation: conversation,
                                currentUserID: currentUserID
                            )
                        }

                    }

                }

            }
            .safeAreaInset(edge: .bottom, spacing: Spacing.none) {
                TabBarView(
                    selectedTab: $selectedTab,
                    chatUnreadCount: chatViewModel.totalUnread
                )
            }
            .navigationTitle(Text("chat.title"))
            .alert(
                "common.error",
                isPresented: .constant(chatViewModel.errorMessage != nil)
            ) {
                Button("common.ok") {}
            } message: {
                Text(chatViewModel.errorMessage ?? "")
            }
        }
        // Handles the case where the notification tap arrives while the app is already open
        .onChange(of: chatViewModel.pendingConversationID) { _, _ in
            navigateToPendingConversationIfNeeded()
        }
        // Handles the case where the notification tap arrived before conversations were loaded
        .onChange(of: chatViewModel.conversations) { _, _ in
            navigateToPendingConversationIfNeeded()
        }
    }

    private var filterTabs: some View {
        HStack(spacing: Spacing.small) {
            ForEach(ChatFilter.allCases, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter.label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(
                            selectedFilter == filter ? .white : Theme.darkBrown
                        )
                        .padding(.horizontal, Spacing.large)
                        .padding(.vertical, Spacing.small)
                        .background(
                            selectedFilter == filter
                                ? Theme.sageGreen : Theme.offWhite
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.medium)
    }

    // Navigates to the pending conversation if one is waiting AND conversations are loaded.
    private func navigateToPendingConversationIfNeeded() {
        guard let pendingID = chatViewModel.pendingConversationID,
            let conversation = chatViewModel.conversations.first(where: {
                $0.id == pendingID
            })
        else { return }
        navigationPath.append(conversation)
        chatViewModel.pendingConversationID = nil
    }

}

private struct MockChatRepository: ChatRepository {
    func fetchConversations(for userId: String) async throws -> [Conversation] {
        []
    }
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
            id: "mock-conv",
            participantIDs: [userId1, userId2],
            lastMessage: "",
            lastMessageTimestamp: Date()
        )
    }

    func markAsRead(conversationID: String, userID: String) async throws {}
    
    func markAsDelivered(conversationID: String, userID: String) async throws {}
    // Mock implementation — required by ChatRepository protocol (PP-028)
    // Not used in ChatView, added only to satisfy protocol conformance
    func uploadImage(_ image: UIImage, conversationId: String) async throws -> URL {
            return URL(string: "https://mock-image-url.com/image.jpg")!
        }
}

private func makePreviewChatViewModel() -> ChatViewModel {
    let mockConversations = [
        Conversation(
            id: "1",
            participantIDs: ["Anna", "Patrik"],
            lastMessage: "Hey, want to go for a walk?",
            lastMessageTimestamp: Date(),
            unreadCount: 3

        ),
        Conversation(
            id: "2",
            participantIDs: ["Sara", "Patrik"],
            lastMessage: "My dog loved meeting yours!",
            lastMessageTimestamp: Date().addingTimeInterval(-3600),
            unreadCount: 1

        ),
        Conversation(
            id: "3",
            participantIDs: ["Johan", "Patrik"],
            lastMessage: "See you at the park!",
            lastMessageTimestamp: Date().addingTimeInterval(-7200),

        ),
    ]
    func uploadImage(_ image: UIImage, conversationId: String) async throws -> URL {
        return URL(string: "https://mock-image-url.com/image.jpg")!
    }

    let viewModel = ChatViewModel(repository: MockChatRepository())
    viewModel.conversations = mockConversations
    return viewModel
}

#Preview {
    ChatView(selectedTab: .constant(.chat), currentUserID: "Patrik")
        .environment(makePreviewChatViewModel())
}
