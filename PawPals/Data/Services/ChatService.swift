import FirebaseFirestore
import Foundation

final class ChatService: ChatRepository {
    private let db = Firestore.firestore()
    private let errorHandler = FirestoreErrorHandler.shared

    func createOrFetchConversation(between userID1: String, and userID2: String) async throws -> Conversation {
        /// Sorting guarantees the same ID regardless of which user initiates.
        let conversationID = [userID1, userID2].sorted().joined(separator: "_")
        let ref = db.collection("conversations").document(conversationID)
        let snapshot = try await errorHandler.execute {
            try await ref.getDocument()
        }

        /// Conversation already in Firestore — decode and return it.
        if snapshot.exists {
            return try snapshot.data(as: Conversation.self)
        }
        
        /// First time these two users connect — create the document.
        let conversation = Conversation(
            id: conversationID,
            participantIDs: [userID1, userID2],
            lastMessage: "",
            lastMessageTimestamp: Date()
        )
        try await errorHandler.execute {
                    try ref.setData(from: conversation)
                }
        return conversation
    }

    func fetchConversationIfExists(between userID1: String, and userID2: String) async throws -> Conversation? {
        let conversationID = [userID1, userID2].sorted().joined(separator: "_")
        let snapshot = try await errorHandler.execute {
            try await self.db.collection("conversations").document(conversationID).getDocument()
        }
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: Conversation.self)
    }

    func observeConversations(
        for userID: String,
        onUpdate: @escaping ([Conversation]) -> Void
    ) -> (() -> Void) {
        let listener = db.collection("conversations")
            .whereField("participantIDs", arrayContains: userID) /// Only conversations this user belongs to.
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let conversations = documents.compactMap {
                    try? $0.data(as: Conversation.self) /// Silently skip malformed documents
                }
                /// Sort newest-first so the most recent conversation appears at the top.
                onUpdate(
                    conversations.sorted {
                        $0.lastMessageTimestamp > $1.lastMessageTimestamp
                    }
                )
            }
        /// Caller stores this and calls it on view disappear to detach the listener.
        return { listener.remove() }
    }
    
    func fetchConnectedUserIDs(for userID: String) async throws -> Set<String> {
        let snapshot = try await errorHandler.execute {
            try await self.db.collection("conversations")
                .whereField("participantIDs", arrayContains: userID)
                .getDocuments()
        }
        let partnerIDs = snapshot.documents.compactMap { doc -> String? in
            let ids = doc.data()["participantIDs"] as? [String] ?? []
            return ids.first { $0 != userID }
        }
        return Set(partnerIDs)
    }
}
