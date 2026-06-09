import Foundation
import UIKit

@Observable
final class ConversationViewModel {
    var messages: [Message] = []
    var messageText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var isUploadingImage: Bool = false

    private let chatRepository: ChatRepository
    private var stopObserving: (() -> Void)?

    init(chatRepository: ChatRepository) {
        self.chatRepository = chatRepository
    }

    /// Starts the Firestore listener for messages in a single conversation.
    func observeMessages(conversationID: String, currentUserID: String) {
        messages = []
        isLoading = true
        stopObserving = chatRepository.observeMessages(
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
            try await chatRepository.sendMessage(message, to: conversation.id)
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
            let url = try await chatRepository.uploadImage(
                image,
                conversationId: conversation.id
            )

            let message = Message(
                id: UUID().uuidString,
                senderID: senderID,
                receiverID: receiverID,
                text: "",
                imageURL: url.absoluteString,
                timestamp: Date()
            )

            try await chatRepository.sendMessage(message, to: conversation.id)
        } catch {
            errorMessage = error.localizedDescription
        }

        isUploadingImage = false
    }

    func markAsDelivered(conversationID: String, userID: String) async {
        do {
            try await chatRepository.markAsDelivered(
                conversationID: conversationID,
                userID: userID
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markAsRead(conversationID: String, userID: String) async {
        do {
            try await chatRepository.markAsRead(
                conversationID: conversationID,
                userID: userID
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

}
