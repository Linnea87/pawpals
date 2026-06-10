import Foundation
import UIKit

/// Handles message-level operations for a single open conversation.
/// Conversation creation and listing is in ChatRepository.
protocol ConversationRepository {
    func observeMessages(
        conversationID: String,
        onUpdate: @escaping ([Message]) -> Void
    ) -> (() -> Void)

    func sendMessage(_ message: Message, to conversationID: String) async throws
    
    /// Resets the unread badge to 0 and marks all received messages as read.
    func markAsRead(conversationID: String, userID: String) async throws
    
    /// Marks all undelivered messages as delivered — triggers the second checkmark.
    func markAsDelivered(conversationID: String, userID: String) async throws

    func uploadImage(_ image: UIImage, conversationId: String) async throws -> URL
}
