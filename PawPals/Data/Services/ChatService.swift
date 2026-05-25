import Foundation
import FirebaseFirestore

final class ChatService: ChatRepository {
    private let db = Firestore.firestore()

    func fetchConversations(for userId: String) async throws -> [Conversation] {
        let snapshot = try await db.collection("conversations")
            .whereField("participantIDs", arrayContains: userId)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try doc.data(as: Conversation.self)
        }
    }

    func sendMessage(_ message: Message, to conversationID: String) async throws {
        let ref = db.collection("conversations")
            .document(conversationID)
            .collection("messages")
            .document(message.id)

        let data: [String: Any] = [
            "id": message.id,
            "senderID": message.senderID,
            "receiverID": message.receiverID,
            "text": message.text,
            "timestamp": Timestamp(date: message.timestamp)
        ]
        try await ref.setData(data)
    }

    func observeMessages(
        conversationID: String,
        onUpdate: @escaping ([Message]) -> Void
    ) -> (() -> Void) {
        let listener = db.collection("conversations")
            .document(conversationID)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }

                let messages = documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                }

                onUpdate(messages)
            }

        return { listener.remove() }
    }
    
    func createOrFetchConversation(between userId1: String, and userId2: String) async throws -> Conversation {
        // PP-020: Query Firestore for existing conversation — blocked by Firebase Auth (PP-002)
        fatalError("Not implemented yet")
    }
    
    
    func markAsRead(conversationID: String, userID: String) async throws {
        try await db.collection("conversations")
            .document(conversationID)
        .updateData(["unreadCount": 0])
    }
}
