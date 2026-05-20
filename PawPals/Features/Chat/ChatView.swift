import SwiftUI

struct ChatView: View {
    @Environment(ChatViewModel.self) private var chatViewModel

    var body: some View {
        NavigationStack {
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
                        ConversationRowView(conversation: conversation)
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
}

private struct MockChatRepository: ChatRepository {
    func fetchConversations(for userId: String) async throws -> [Conversation] {
        return []
    }
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

    return ChatView()
        .environment(viewModel)
}
