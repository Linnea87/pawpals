import Foundation

protocol ChatRepository {
    func fetchConversations(for userId: String) async throws -> [Conversation]
}

