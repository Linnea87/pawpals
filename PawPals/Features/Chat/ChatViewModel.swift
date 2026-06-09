import Foundation
import UIKit

enum ChatFilter: CaseIterable {
    case all, unread, favorite

    var label: String {
        switch self {
        case .all: return "chat.filter.all"
        case .unread: return "chat.filter.unread"
        case .favorite: return "chat.filter.favorite"
        }
    }
}

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
    var selectedFilter: ChatFilter = .all

    var filteredConversations: [Conversation] {
        switch selectedFilter {
        case .all: return conversations
        case .unread: return conversations.filter { $0.unreadCount > 0 }
        case .favorite: return []
        }
    }

    /// Cache of resolved User objects keyed by their Firestore user ID.
    var participants: [String: User] = [:]

    var totalUnread: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    private let chatRepository: ChatRepository
    private let userRepository: ProfileRepository


    private var stopObserving: (() -> Void)?


    private var stopObservingConversations: (() -> Void)?

    init(chatRepository: ChatRepository, userRepository: ProfileRepository) {
        self.chatRepository = chatRepository
        self.userRepository = userRepository
    }

    /// Creates or fetches a conversation with another user and navigates to it.
    /// Also stores the other user in the participants cache immediately so the conversation header shows the correct name and photo.
    func startConversation(with user: User, currentUserId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let conversation = try await chatRepository.createOrFetchConversation(
                between: currentUserId,
                and: user.id
            )
            activeConversation = conversation
            participants[user.id] = user
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

    /// Optimistically resets the unread badge in the local array before writing to Firestore.
    /// If the Firestore write fails, the previous count is restored so the UI stays accurate.
    func markAsRead(conversationID: String, userID: String) async {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID })
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
        let receiverID = conversation.participantIDs.first { $0 != senderID } ?? ""
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

    /// Looks up the other participant in the local participants cache.
    /// Returns nil if the user hasn't been fetched yet — callers fall back to .mock.
    func otherUser(in conversation: Conversation, currentUserID: String) -> User? {
        let otherID = conversation.participantIDs.first { $0 != currentUserID }
        return otherID.flatMap { participants[$0] }
    }

    // ================= Helpers =================

    func formattedTimeStamp(for conversation: Conversation) -> String {
        let calendar = Calendar.current
        let date = conversation.lastMessageTimestamp

        if calendar.isDateInToday(date) {
            return String(localized: "date.today")
        }

        let days = calendar.dateComponents([.day], from: date, to: .now).day ?? 0
        if days < 7 {
            return String(localized: "\(days) days ago")
        }

        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
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

    /// Starts a real-time Firestore listener for the full conversations list.
    /// Each update also triggers a participant fetch so names and avatars stay current.
    func observeConversations(for userID: String) {
        stopObservingConversations = chatRepository.observeConversations(for: userID) { [weak self] updated in
            guard let self else { return }
            self.conversations = updated
            Task { await self.fetchParticipants(for: updated, currentUserID: userID) }
        }
    }

    /// Removes the conversations Firestore listener.
    func stopListeningToConversations() {
        stopObservingConversations?()
        stopObservingConversations = nil
    }

    /// Removes the messages Firestore listener.
    func stopListening() {
        stopObserving?()
        stopObserving = nil
    }

    func sendImage(_ image: UIImage, in conversation: Conversation, senderID: String) async {
        isUploadingImage = true
        errorMessage = nil

        let receiverID = conversation.participantIDs.first { $0 != senderID } ?? ""

        do {
            let url = try await chatRepository.uploadImage(image, conversationId: conversation.id)

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

    /// Fetches Firestore user documents for all participants we don't have cached yet.
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
