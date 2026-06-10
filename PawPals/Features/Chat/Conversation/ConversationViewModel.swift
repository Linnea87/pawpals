import Foundation
import UIKit

@Observable
final class ConversationViewModel {
    var messages: [Message] = []
    var messageText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var isUploadingImage: Bool = false
    var isNew: Bool = false /// True when this conversation hasn't been written to Firestore yet.
  
    var onCreate: (() async throws -> Void)? /// Called once before the first message send to create the conversation in Firestore.

    private let conversationRepository: ConversationRepository
    private var stopObserving: (() -> Void)?

    init(conversationRepository: ConversationRepository) {
        self.conversationRepository = conversationRepository
    }

    /// Starts the Firestore listener for messages in a single conversation.
    func observeMessages(conversationID: String, currentUserID: String) {
        guard !isNew else { return }
        messages = []
        isLoading = true
        stopObserving = conversationRepository.observeMessages(
            conversationID: conversationID
        ) { [weak self] updatedMessages in
            guard let self else { return }
            self.messages = updatedMessages
            self.isLoading = false
            Task {
                await self.markAsDelivered(
                    conversationID: conversationID,
                    userID: currentUserID
                )
            }
        }
    }

    /// Removes the messages Firestore listener.
    func stopObservingMessages() {
        stopObserving?()
        stopObserving = nil
    }

    func sendMessage(in conversation: Conversation, senderID: String) async {
        let receiverID =
            conversation.participantIDs.first { $0 != senderID } ?? ""
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespaces)
        guard !trimmedMessage.isEmpty else { return }

        let message = Message(
            id: UUID().uuidString,
            senderID: senderID,
            receiverID: receiverID,
            text: trimmedMessage,
            timestamp: Date()
        )

        messageText = ""

        do {
                /// If this is a new conversation, create it in Firestore before sending.
                if isNew, let create = onCreate {
                    try await create()
                    isNew = false
                    onCreate = nil
                    /// Now the conversation exists — start observing messages.
                    observeMessages(conversationID: conversation.id, currentUserID: senderID)
                }
                try await conversationRepository.sendMessage(message, to: conversation.id)
            /// Reset unread count for the sender immediately — prevents the badge incrementing for your own messages.
                try await conversationRepository.markAsRead(conversationID: conversation.id, userID: senderID)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

    func sendImage(
        _ image: UIImage,
        in conversation: Conversation,
        senderID: String
    ) async {
        isUploadingImage = true
        errorMessage = nil

        let receiverID =
            conversation.participantIDs.first { $0 != senderID } ?? ""

        do {
            let url = try await chatRepository.uploadImage(image, conversationID: conversation.id)

            let message = Message(
                id: UUID().uuidString,
                senderID: senderID,
                receiverID: receiverID,
                text: messageText,
                imageURL: url.absoluteString,
                timestamp: Date()
            )

            try await conversationRepository.sendMessage(message, to: conversation.id)
                    messageText = "" 
        } catch {
            errorMessage = error.localizedDescription
        }

        isUploadingImage = false
    }

    func markAsDelivered(conversationID: String, userID: String) async {
        do {
            try await conversationRepository.markAsDelivered(
                conversationID: conversationID,
                userID: userID
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markAsRead(conversationID: String, userID: String) async {
        do {
            try await conversationRepository.markAsRead(
                conversationID: conversationID,
                userID: userID
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

}
