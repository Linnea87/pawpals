import Foundation

@Observable
final class ChatViewModel {
    var conversations: [Conversation] = []
    var messages: [Message] = []
    var messageText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    private let repository: ChatRepository
    private var stopObserving: (() -> Void)?

    init(repository: ChatRepository) {
        self.repository = repository
    }

    func fetchConversations(for userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await repository.fetchConversations(for: userId)
            conversations = result.sorted {
                $0.lastMessageTimestamp > $1.lastMessageTimestamp
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false

    }

    func observeMessages(conversationID: String) {
        isLoading = true
        stopObserving = repository.observeMessages(
            conversationID: conversationID
        ) { [weak self] message in
            guard let self else { return }
            self.messages = messages
            self.isLoading = false
        }
    }

    func sendMessage(
        conversationID: String,
        senderID: String,
        receiverID: String
    ) async {
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
            try await repository.sendMessage(message, to: conversationID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopListening() {
        stopObserving?()
        stopObserving = nil
    }
}
