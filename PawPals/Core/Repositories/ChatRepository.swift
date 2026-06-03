import Foundation
import UIKit 

protocol ChatRepository {
    func fetchConversations(for userId: String) async throws -> [Conversation]

    func sendMessage(_ message: Message, to conversationID: String) async throws

    func observeMessages(
        conversationID: String,
        onUpdate: @escaping ([Message]) -> Void
    ) -> (() -> Void)
    func createOrFetchConversation(between userId1: String, and userId2: String) async throws -> Conversation
    
    func markAsRead(conversationID: String, userID: String) async throws
    
    func markAsDelivered(conversationID: String, userID: String) async throws
    func uploadImage(_ image: UIImage, conversationId: String) async throws -> URL
}

