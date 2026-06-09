import FirebaseFirestore
import Foundation

final class ChatService: ChatRepository {
    private let db = Firestore.firestore()

    func createOrFetchConversation(between userID1: String, and userID2: String) async throws -> Conversation {
        let conversationID = [userID1, userID2].sorted().joined(separator: "_")
        let ref = db.collection("conversations").document(conversationID)
        let snapshot = try await ref.getDocument()

        if snapshot.exists {
            return try snapshot.data(as: Conversation.self)
        }

        let conversation = Conversation(
            id: conversationID,
            participantIDs: [userID1, userID2],
            lastMessage: "",
            lastMessageTimestamp: Date(),
            unreadCount: 0
        )
        try ref.setData(from: conversation)
        return conversation
    }
    
    func fetchConversationIfExists(between userID1: String, and userID2: String) async throws -> Conversation? {
        let conversationID = [userID1, userID2].sorted().joined(separator: "_")
        let snapshot = try await db.collection("conversations").document(conversationID).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: Conversation.self)
    }

    func observeConversations(
        for userID: String,
        onUpdate: @escaping ([Conversation]) -> Void
    ) -> (() -> Void) {
        let listener = db.collection("conversations")
            .whereField("participantIDs", arrayContains: userID)
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let conversations = documents.compactMap {
                    try? $0.data(as: Conversation.self)
                }
                onUpdate(
                    conversations.sorted {
                        $0.lastMessageTimestamp > $1.lastMessageTimestamp
                    }
                )
            }
        return { listener.remove() }
    }
}
