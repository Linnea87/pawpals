import Foundation
import UIKit

/// Defines all chat operations the app can perform.
/// ViewModels depend on this protocol, never on ChatService directly —
/// that keeps Firebase isolated to the Data layer and makes the code testable with mocks.
protocol ChatRepository {

    /// Writes a message to Firestore and updates the parent conversation document
    /// (lastMessage, lastMessageTimestamp, unreadCount).
    /// Previously only wrote the message — the conversation list never updated.
    func sendMessage(_ message: Message, to conversationID: String) async throws

    /// Attaches a real-time Firestore listener to the messages subcollection.
    /// Returns a closure — call it to detach the listener when the view disappears.
    func observeMessages(
        conversationID: String,
        onUpdate: @escaping ([Message]) -> Void
    ) -> (() -> Void)

    /// Attaches a real-time Firestore listener to the conversations collection.
    /// Added because fetchConversations was a one-time read — the chat list never
    /// updated when the other user sent a message or a new conversation was created.
    /// Returns a closure — call it to detach the listener when the view disappears.
    func observeConversations(
        for userID: String,
        onUpdate: @escaping ([Conversation]) -> Void
    ) -> (() -> Void)

    /// Returns an existing conversation between two users, or creates one if none exists.
    func createOrFetchConversation(between userId1: String, and userId2: String) async throws -> Conversation

    /// Resets unreadCount to 0 and marks all received messages as read.
    func markAsRead(conversationID: String, userID: String) async throws

    /// Marks all received messages as delivered (shown with a second checkmark).
    func markAsDelivered(conversationID: String, userID: String) async throws

    /// Uploads an image to Firebase Storage and returns its download URL.
    func uploadImage(_ image: UIImage, conversationID: String) async throws -> URL
}
