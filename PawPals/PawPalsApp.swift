import SwiftUI

@main
struct PawPalsApp: App {
    @State private var authViewModel = AuthViewModel()
    @State private var meetViewModel = MeetViewModel()
    // TODO [PP-002]: Replace MockChatService with ChatService() when Firebase auth is wired
    @State private var chatViewModel = ChatViewModel(repository: MockChatService())
    var body: some Scene {
        WindowGroup {
            AppNavigationView()
                .environment(authViewModel)
                .environment(meetViewModel)
                .environment(chatViewModel)
        }
    }
}
// Temporary mock — remove when Firebase is wired in PP-002
private struct MockChatService: ChatRepository {
    func fetchConversations(for userId: String) async throws -> [Conversation] { [] }
    func sendMessage(_ message: Message, to conversationID: String) async throws {}
    func observeMessages(conversationID: String, onUpdate: @escaping ([Message]) -> Void) -> (() -> Void) { return {} }
    func createOrFetchConversation(between userId1: String, and userId2: String) async throws -> Conversation {
        Conversation(id: "mock", participantIDs: [userId1, userId2], lastMessage: "", lastMessageTimestamp: Date())
    }
    func markAsRead(conversationID: String, userID: String) async throws {}
}
