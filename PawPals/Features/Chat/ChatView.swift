import SwiftUI

struct ChatView: View {
    @Environment(ChatViewModel.self) private var chatViewModel
    var currentUserID: String = ""

    var body: some View {
        Group {
            if chatViewModel.isLoading {
                ProgressView()
            } else if chatViewModel.conversations.isEmpty {
                ContentUnavailableView(
                    String(localized: "chat.noConversations"),
                    systemImage: "bubble.left.and.bubble.right"
                )
            } else {
                List(chatViewModel.conversations) { conversation in
                    NavigationLink {
                        ConversationView(
                            conversation: conversation,
                            currentUserID: currentUserID
                        )
                    } label: {
                        ConversationRowView(conversation: conversation)
                    }
                }
                .listStyle(.plain)
            }
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
}

#Preview {
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

    return ChatView(currentUserID: "Patrik")
        .environment(viewModel)
}
