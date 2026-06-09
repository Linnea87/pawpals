import Foundation

protocol ChatRepository {
    func observeConversations(
        for userID: String,
        onUpdate: @escaping ([Conversation]) -> Void
    ) -> (() -> Void)
    
    func createOrFetchConversation(between userId1: String, and userId2: String) async throws -> Conversation
    
    func fetchConversationIfExists(between userID1: String, and userID2: String) async throws -> Conversation?
}
