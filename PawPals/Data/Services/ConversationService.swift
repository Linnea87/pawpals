import FirebaseFirestore
import FirebaseStorage
import Foundation
import UIKit

final class ConversationService: ConversationRepository {
    private let db = Firestore.firestore()

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
            "timestamp": Timestamp(date: message.timestamp),
            "isRead": false,
            "isDelivered": false,
        ]
        try await ref.setData(data)

        let conversationRef = db.collection("conversations").document(conversationID)
        try await conversationRef.updateData([
            "lastMessage": message.text.isEmpty
                ? String(localized: "chat.lastMessage.photo") : message.text,
            "lastMessageTimestamp": Timestamp(date: message.timestamp),
            "unreadCount": FieldValue.increment(Int64(1)),
        ])
    }

    func markAsRead(conversationID: String, userID: String) async throws {
        try await db.collection("conversations")
            .document(conversationID)
            .updateData(["unreadCount": 0])

        let snapshot = try await db.collection("conversations")
            .document(conversationID)
            .collection("messages")
            .whereField("receiverID", isEqualTo: userID)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    func markAsDelivered(conversationID: String, userID: String) async throws {
        let snapshot = try await db.collection("conversations")
            .document(conversationID)
            .collection("messages")
            .whereField("receiverID", isEqualTo: userID)
            .whereField("isDelivered", isEqualTo: false)
            .getDocuments()

        guard !snapshot.documents.isEmpty else { return }

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["isDelivered": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    func uploadImage(_ image: UIImage, conversationId: String) async throws -> URL {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw URLError(.badServerResponse)
        }
        guard imageData.count < 5_000_000 else {
            throw URLError(.dataLengthExceedsMaximum)
        }

        let storageRef = Storage.storage()
            .reference()
            .child("conversations/\(conversationId)/\(UUID().uuidString).jpg")

        _ = try await storageRef.putDataAsync(imageData)
        return try await storageRef.downloadURL()
    }
}
