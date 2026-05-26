import Foundation

@Observable
final class ChatViewModel {
    var conversations: [Conversation] = []
    var messages: [Message] = []
    var messageText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var activeConversation: Conversation?
    var totalUnread: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

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

    func markAsRead(conversationID: String, userID: String) async {
        guard
            let index = conversations.firstIndex(where: {
                $0.id == conversationID
            })
        else { return }

        let previous = conversations[index].unreadCount
        conversations[index].unreadCount = 0

        do {
            try await repository.markAsRead(
                conversationID: conversationID,
                userID: userID
            )
        } catch {
            conversations[index].unreadCount = previous
            errorMessage = error.localizedDescription
        }
    }

    func startConversation(with user: User, currentUserId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let conversation = try await repository.createOrFetchConversation(
                between: currentUserId,
                and: user.id
            )
            activeConversation = conversation
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }


    func observeMessages(conversationID: String) {
        isLoading = true
        stopObserving = repository.observeMessages(
            conversationID: conversationID
        ) { [weak self] updatedMessages in
            guard let self else { return }
            self.messages = updatedMessages
            self.isLoading = false
        }
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
            try await repository.sendMessage(message, to: conversation.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func otherParticipantName(
        in conversation: Conversation,
        currentUserID: String
    ) -> String {
        conversation.participantIDs.first { $0 != currentUserID }
            ?? "common.unknown"
    }

    func stopListening() {
        stopObserving?()
        stopObserving = nil
    }
}
