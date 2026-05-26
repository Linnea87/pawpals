import Foundation
import FirebaseFirestore

final class ChatService: ChatRepository {
    private let db = Firestore.firestore()

    func fetchConversations(for userId: String) async throws -> [Conversation] {
        let snapshot = try await db.collection("conversations")
            .whereField("participantIDs", arrayContains: userId)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Conversation.self) }
    }

    func createOrFetchConversation(between userId1: String, and userId2: String) async throws -> Conversation {
        let snapshot = try await db.collection("conversations")
            .whereField("participantIDs", arrayContains: userId1)
            .getDocuments()

        if let existing = snapshot.documents.first(where: { doc in
            let ids = doc.data()["participantIDs"] as? [String] ?? []
            return ids.contains(userId2)
        }) {
            return try existing.data(as: Conversation.self)
        }

        let ref = db.collection("conversations").document()
        let conversation = Conversation(
            id: ref.documentID,
            participantIDs: [userId1, userId2],
            lastMessage: "",
            lastMessageTimestamp: Date(),
            unreadCount: 0
        )
        try ref.setData(from: conversation)
        return conversation
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
  
    func markAsRead(conversationID: String, userID: String) async throws {
        try await db.collection("conversations")
            .document(conversationID)
        .updateData(["unreadCount": 0])
    }
}
