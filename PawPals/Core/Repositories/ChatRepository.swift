import Foundation

/// Handles conversation-level operations — listing and creating conversations.
protocol ChatRepository {
    func observeConversations(
        for userID: String,
        onUpdate: @escaping ([Conversation]) -> Void
    ) -> (() -> Void)
    
    /// Creates a conversation in Firestore if none exists, otherwise returns the existing one.
    func createOrFetchConversation(between userID1: String, and userID2: String) async throws -> Conversation

    /// Returns the existing conversation without creating one — nil =  no conversation yet.
    func fetchConversationIfExists(between userID1: String, and userID2: String) async throws -> Conversation?
    
    /// Fetches the IDs of all users the current user already has a conversation with.
    func fetchConnectedUserIDs(for userID: String) async throws -> Set<String>
}
