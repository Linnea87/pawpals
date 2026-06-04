import Foundation
import UIKit 

@Observable
final class ChatViewModel {
    var conversations: [Conversation] = []
    var messages: [Message] = []
    var messageText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var activeConversation: Conversation?
    var pendingConversationID: String? /// Set when the user taps a push notification for a new message.
    var isUploadingImage: Bool = false
    var participants: [String: User] = [:]


    var totalUnread: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    private let chatRepository: ChatRepository
    private let userRepository: UserRepository
    private var stopObserving: (() -> Void)?

    init(chatRepository: ChatRepository, userRepository: UserRepository) {
        self.chatRepository = chatRepository
        self.userRepository = userRepository
    }

    func fetchConversations(for userID: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await chatRepository.fetchConversations(
                for: userID
            )
            conversations = result.sorted {
                $0.lastMessageTimestamp > $1.lastMessageTimestamp
            }
            
            await fetchParticipants(for: result, currentUserID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false

    }

    func startConversation(with user: User, currentUserId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let conversation =
                try await chatRepository.createOrFetchConversation(
                    between: currentUserId,
                    and: user.id
                )
            activeConversation = conversation
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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
        guard
            let index = conversations.firstIndex(where: {
                $0.id == conversationID
            })
        else { return }

        let previous = conversations[index].unreadCount
        conversations[index].unreadCount = 0

        do {
            try await chatRepository.markAsRead(
                conversationID: conversationID,
                userID: userID
            )
        } catch {
            conversations[index].unreadCount = previous
            errorMessage = error.localizedDescription
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
            try await chatRepository.sendMessage(message, to: conversation.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func otherUser(in conversation: Conversation, currentUserID: String) -> User? {
        let otherID = conversation.participantIDs.first { $0 != currentUserID }
        return otherID.flatMap { participants[$0] }
    }

    //========== HELPERS =============================================

    func formattedTimeStamp(for conversation: Conversation) -> String {
        let calendar = Calendar.current
        let date = conversation.lastMessageTimestamp

        if calendar.isDateInToday(date) {
            return String(localized: "date.today")
        }

        let days =
            calendar.dateComponents([.day], from: date, to: .now).day ?? 0
        if days < 7 {
            return String(localized: "\(days) days ago")
        }

        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }

    func observeMessages(conversationID: String, currentUserID: String) {
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

    func sendImage(_ image: UIImage, in conversation: Conversation, senderID: String) async {
        isUploadingImage = true
        errorMessage = nil

        let receiverID = conversation.participantIDs.first { $0 != senderID } ?? ""

        do {
            // Upload image to Firebase Storage via repository
            let url = try await repository.uploadImage(image, conversationId: conversation.id)

            // Create message with image URL — text is empty for image messages
            let message = Message(
                id: UUID().uuidString,
                senderID: senderID,
                receiverID: receiverID,
                text: "",
                imageURL: url.absoluteString,
                timestamp: Date()
            )

            // Send message to Firestore
            try await repository.sendMessage(message, to: conversation.id)

        } catch {
            errorMessage = error.localizedDescription
        }

        isUploadingImage = false
    }
    
    private func fetchParticipants(for conversations: [Conversation], currentUserID: String) async {
        
        let otherIDs = Set(
            conversations.flatMap { $0.participantIDs.filter { $0 != currentUserID } }
        ).filter { participants[$0] == nil } 


        await withTaskGroup(of: (String, User)?.self) { group in
            for id in otherIDs {
                group.addTask {

                    guard let user = try? await self.userRepository.fetchUser(userId: id)
                    else { return nil }
                    return (id, user)
                }
            }
            for await result in group {
                if let (id, user) = result {
                    participants[id] = user
                }
            }
        }
    }
}
