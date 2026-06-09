import Foundation
import UIKit

protocol ConversationRepository {
    func observeMessages(
        conversationID: String,
        onUpdate: @escaping ([Message]) -> Void
    ) -> (() -> Void)

    func sendMessage(_ message: Message, to conversationID: String) async throws

    func markAsRead(conversationID: String, userID: String) async throws

    func markAsDelivered(conversationID: String, userID: String) async throws

    func uploadImage(_ image: UIImage, conversationId: String) async throws -> URL
}
