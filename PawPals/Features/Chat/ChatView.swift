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
                        String(localized: "chat.noConversations"),
                        systemImage: "bubble.left.and.bubble.right"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredConversations) { conversation in
                        ZStack {
                            NavigationLink(value: conversation) { EmptyView() }
                                .opacity(0)
                            ConversationRowView(conversation: conversation)
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TabBarView(selectedTab: $selectedTab)
        }
        .navigationTitle(Text("chat.title"))
        .alert(
            String(localized: "common.error"),
            isPresented: .constant(chatViewModel.errorMessage != nil)
        ) {
            Button(String(localized: "common.ok")) {}
        } message: {
            Text(chatViewModel.errorMessage ?? "")
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
    
    func createOrFetchConversation(between userId1: String, and userId2: String) async throws -> Conversation {
        Conversation(
            id: "mock-conv",
            participantIDs: [userId1, userId2],
            lastMessage: "",
            lastMessageTimestamp: Date()
        )
    }
}

private func makePreviewChatViewModel() -> ChatViewModel {
    let mockConversations = [
        Conversation(
            id: "1",
            participantIDs: ["Anna", "Patrik"],
            lastMessage: "Hey, want to go for a walk?",
            lastMessageTimestamp: Date()
        ),
        Conversation(
            id: "2",
            participantIDs: ["Sara", "Patrik"],
            lastMessage: "My dog loved meeting yours!",
            lastMessageTimestamp: Date().addingTimeInterval(-3600)
        ),
        Conversation(
            id: "3",
            participantIDs: ["Johan", "Patrik"],
            lastMessage: "See you at the park!",
            lastMessageTimestamp: Date().addingTimeInterval(-7200)
        ),
    ]

    let viewModel = ChatViewModel(repository: MockChatRepository())
    viewModel.conversations = mockConversations
    return viewModel
}

#Preview {
    ChatView(selectedTab: .constant(.chat), currentUserID: "Patrik")
        .environment(makePreviewChatViewModel())
}


