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
            /// Oldest → newest so messages render in the correct order.
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let messages = documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                    /// Silently skip malformed message documents.
                }
                onUpdate(messages)
            }
        return { listener.remove() }
    }

    func sendMessage(_ message: Message, to conversationID: String) async throws
    {
        let ref = db.collection("conversations")
            .document(conversationID)
            .collection("messages")
            .document(message.id)

        /// Manual dictionary instead of Codable — Timestamp requires explicit conversion.
        var data: [String: Any] = [
            "id": message.id,
            "senderID": message.senderID,
            "receiverID": message.receiverID,
            "text": message.text,
            "timestamp": Timestamp(date: message.timestamp),
            "isRead": false,
            "isDelivered": false,
        ]

        if let imageURL = message.imageURL {
            data["imageURL"] = imageURL
        }
        try await ref.setData(data)

        /// Update the conversation document so the chat list shows the correct preview and unread badge.
        let conversationRef = db.collection("conversations").document(
            conversationID
        )
        try await conversationRef.updateData([
            "lastMessage": message.text.isEmpty
                ? String(localized: "chat.lastMessage.photo") : message.text,
            "lastMessageTimestamp": Timestamp(date: message.timestamp),
            /// Server-side increment prevents race conditions when two messages arrive simultaneously.
            "unreadCounts.\(message.receiverID)": FieldValue.increment(
                Int64(1)
            ),
        ])
    }

    func markAsRead(conversationID: String, userID: String) async throws {
        /// Reset the badge on the conversation document first.
        try await db.collection("conversations")
            .document(conversationID)
            .updateData(["unreadCounts.\(userID)": 0])

        let snapshot = try await db.collection("conversations")
            .document(conversationID)
            .collection("messages")
            .whereField("receiverID", isEqualTo: userID)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        /// Batch write so all messages are marked read in a single Firestore round-trip.
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
        /// Nothing to update — skip the batch write.

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["isDelivered": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    func uploadImage(_ image: UIImage, conversationID: String) async throws
        -> URL
    {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw URLError(.badServerResponse)
        }
        guard imageData.count < 5_000_000 else {
            throw URLError(.dataLengthExceedsMaximum)
        }

        let storageRef = Storage.storage()
            .reference()
            .child("conversations/\(conversationID)/\(UUID().uuidString).jpg")

        _ = try await storageRef.putDataAsync(imageData)
        return try await storageRef.downloadURL()
    }
}
