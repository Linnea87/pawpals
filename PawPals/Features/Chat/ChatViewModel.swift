import Foundation

@Observable
final class ChatViewModel {
    var conversations: [Conversation] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let repository: ChatRepository

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
}
