import FirebaseFirestore
import FirebaseStorage
import Foundation
import UIKit

final class ChatService: ChatRepository {
    private let db = Firestore.firestore()

    /// Returns an existing conversation between two users, or creates a new one.
    func createOrFetchConversation(between userID1: String, and userID2: String)
        async throws -> Conversation
    {
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

    /// Writes the message to the messages subcollection, then updates the parent
    /// conversation document with the latest preview text, timestamp, and unread count.
    func sendMessage(_ message: Message, to conversationID: String) async throws
    {
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
            "imageURL": message.imageURL as Any
        ]
        try await ref.setData(data)

        /// Update the conversation document so the chat list shows the correct preview, and the receiver's unread badge increments in real time.
        let conversationRef = db.collection("conversations").document(
            conversationID
        )
        try await conversationRef.updateData([
            "lastMessage": message.text.isEmpty
                ? String(localized: "chat.lastMessage.photo") : message.text,
            "lastMessageTimestamp": Timestamp(date: message.timestamp),
            "unreadCount": FieldValue.increment(Int64(1)),/// Firestore increments this on the server so two messages arriving at the same time never cancel each other out. Int64 is just what the SDK expects for whole numbers.
        ])
    }

    /// Attaches a real-time Firestore listener to the messages subcollection for one conversation.
    func observeMessages(
        conversationID: String,
        onUpdate: @escaping ([Message]) -> Void
    ) -> (() -> Void) {
        let listener = db.collection("conversations")
            .document(conversationID)
            .collection("messages")
            /// Order by timestamp so messages always render oldest → newest
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }

                /// Decode each message document — silently skip any that fail to decode
                let messages = documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                }

                onUpdate(messages)
            }

        return { listener.remove() }
    }

    /// Attaches a real-time Firestore listener to the conversations collection.
    func observeConversations(
        for userID: String,
        onUpdate: @escaping ([Conversation]) -> Void
    ) -> (() -> Void) {
        let listener = db.collection("conversations")
            /// Only listen to conversations this user is part of
            .whereField("participantIDs", arrayContains: userID)
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                /// Decode each conversation document — silently skip any that fail
                let conversations = documents.compactMap {
                    try? $0.data(as: Conversation.self)
                }
                /// Sort newest-first so the most recent conversation always appears at the top
                onUpdate(
                    conversations.sorted {
                        $0.lastMessageTimestamp > $1.lastMessageTimestamp
                    }
                )
            }
        return { listener.remove() }
    }

    /// Resets the unread badge to 0 and marks all messages sent to this user as read.
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

    /// Marks all undelivered messages sent to this user as delivered (second checkmark).
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

        let url = try await storageRef.downloadURL()
        return url
    }
}
