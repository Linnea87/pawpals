import Foundation

protocol ChatRepository {
    func fetchConversations(for userId: String) async throws -> [Conversation]

    func sendMessage(_ message: Message, to conversationID: String) async throws

    func observeMessages(
        conversationID: String,
        onUpdate: @escaping ([Message]) -> Void
    ) -> (() -> Void)
}

