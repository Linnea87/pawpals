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
    var isLoading: Bool = false
    var errorMessage: String?
    var activeConversation: Conversation?
    var pendingConversationID: String? /// Set when the user taps a push notification for a new message.
    var isActiveConversationNew: Bool = false /// True when activeConversation is a local draft not yet saved to Firestore.
    var selectedFilter: ChatFilter = .all
    var savedUserIds: Set<String> = []
    private(set) var currentUserID: String = ""

    var filteredConversations: [Conversation] {
        switch selectedFilter {
        case .all: return conversations
        case .unread: return conversations.filter { $0.unreadCount > 0 }
        case .favorite: return conversations.filter { conversation in
            conversation.participantIDs.contains { $0 != currentUserID && savedUserIds.contains($0) }
        }
        }
    }

    /// Cache of resolved User objects keyed by their Firestore user ID.
    var participants: [String: User] = [:]

    /// Sum of unread counts across all conversations — drives the tab bar badge.
    var totalUnread: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    private let chatRepository: ChatRepository
    private let profileRepository: ProfileRepository
    private let meetRepository: MeetRepository


    private var stopConversationsListener: (() -> Void)? /// Holds the Firestore cleanup closure


    private var stopObservingConversations: (() -> Void)?

    init(chatRepository: ChatRepository, profileRepository: ProfileRepository, meetRepository: MeetRepository) {
        self.chatRepository = chatRepository
        self.profileRepository = profileRepository
        self.meetRepository = meetRepository
    }

    /// Navigates to an existing conversation or creates a local draft if none exists yet.
    /// Nothing is written to Firestore until the first message is sent.
    func startConversation(with user: User, currentUserId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            if let existing = try await chatRepository.fetchConversationIfExists(
                between: currentUserId,
                and: user.id
            ) {
                
                activeConversation = existing
                participants[user.id] = user
                isActiveConversationNew = false
            } else {
                /// Build a local draft with the deterministic ID — no Firestore write yet.
                let conversationID = [currentUserId, user.id].sorted().joined(separator: "_")
                let draft = Conversation(
                    id: conversationID,
                    participantIDs: [currentUserId, user.id],
                    lastMessage: "",
                    lastMessageTimestamp: Date(),
                    unreadCount: 0
                )
                activeConversation = draft
                participants[user.id] = user
                isActiveConversationNew = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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

    

    /// Starts a real-time Firestore listener for the full conversations list.
    /// Each update also triggers a participant fetch so names and avatars stay current.
    func observeConversations(for userID: String) {
        currentUserID = userID
        stopObservingConversations = chatRepository.observeConversations(for: userID) { [weak self] updated in
            guard let self else { return }
            self.conversations = updated
            Task { await self.loadParticipants(for: updated, currentUserID: userID) }
        }
    }

    /// Removes the conversations Firestore listener.
    func stopObservingConversations() {
        stopConversationsListener?()
        stopConversationsListener = nil
    }


    /// Fetches Firestore user documents for all participants we don't have cached yet.
    private func loadParticipants(for conversations: [Conversation], currentUserID: String) async {
        let otherIDs = Set(
            conversations.flatMap { $0.participantIDs.filter { $0 != currentUserID } }
        ).filter { participants[$0] == nil }

        await withTaskGroup(of: (String, User)?.self) { group in
            for id in otherIDs {
                group.addTask {
                    guard let user = try? await self.profileRepository.fetchUser(userId: id)
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
    
    func loadFavorites(for userId: String) async {
        do {
            savedUserIds = try await meetRepository.fetchSavedProfileIds(for: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Creates the active conversation in Firestore.
    /// Called by ConversationViewModel on the first message send for a new conversation.
    func createActiveConversation() async throws {
        guard let conversation = activeConversation else { return }
        _ = try await chatRepository.createOrFetchConversation(
            between: conversation.participantIDs[0],
            and: conversation.participantIDs[1]
        )
        isActiveConversationNew = false
    }
    
}
