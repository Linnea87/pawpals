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
}
