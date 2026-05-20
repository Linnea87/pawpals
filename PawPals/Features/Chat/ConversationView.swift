import SwiftUI

struct ConversationView: View {
    @Environment(ChatViewModel.self) private var chatViewModel
    let conversation: Conversation
    let currentUserID: String

    private var otherParticipantName: String {
        conversation.participantIDs.first { $0 != currentUserID } ?? "Unknown"
    }

    var body: some View {
        @Bindable var chatViewModel = chatViewModel

        VStack(spacing: 0) {
            if chatViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: Spacing.small) {
                            ForEach(chatViewModel.messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    isFromCurrentUser: message.senderID
                                        == currentUserID
                                )
                                .id(message.id)
                            }
                        }
                        .padding(Spacing.medium)
                    }
                    .onChange(of: chatViewModel.messages.count) { _, _ in
                        guard let last = chatViewModel.messages.last else {
                            return
                        }
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            MessageInputBar(text: $chatViewModel.messageText) {
                let receiverID =
                    conversation.participantIDs.first { $0 != currentUserID }
                    ?? ""
                Task {
                    await chatViewModel.sendMessage(
                        conversationID: conversation.id,
                        senderID: currentUserID,
                        receiverID: receiverID
                    )
                }
            }
        }
        .navigationTitle(otherParticipantName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            chatViewModel.observeMessages(conversationID: conversation.id)
        }
        .onDisappear {
            chatViewModel.stopListening()
        }
        .alert(
            "comon.Error",
            isPresented: .constant(chatViewModel.errorMessage != nil)
        ) {
            Button("common.OK") { chatViewModel.errorMessage = nil }
        } message: {
            Text(chatViewModel.errorMessage ?? "")
        }

    }
    private struct MessageBubbleView: View {
        let message: Message
        let isFromCurrentUser: Bool

        var body: some View {
            HStack {
                if isFromCurrentUser { Spacer() }

                VStack(
                    alignment: isFromCurrentUser ? .trailing : .leading,
                    spacing: Spacing.xSmall
                ) {
                    Text(message.text)
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, Spacing.small)
                        .background(
                            isFromCurrentUser ? Theme.brand : Theme.surface
                        )
                        .foregroundStyle(
                            isFromCurrentUser ? .white : Theme.textPrimary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }

                if !isFromCurrentUser { Spacer() }
            }
        }
    }

    private struct MessageInputBar: View {
        @Binding var text: String
        let onSend: () -> Void

        var body: some View {
            HStack(spacing: Spacing.small) {
                TextField("chat.messagePlaceholder", text: $text)
                    .padding(Spacing.small)
                    .background(Theme.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.large))

                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            text.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Theme.muted
                                : Theme.brand
                        )
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(Spacing.medium)
            .background(Theme.surface)
        }

    }

}

private struct MockThreadRepository: ChatRepository {
    func fetchConversations(for userId: String) async throws -> [Conversation] {
        []
    }
    func sendMessage(_ message: Message, to conversationID: String) async throws
    {}
    func observeMessages(
        conversationID: String,
        onUpdate: @escaping ([Message]) -> Void
    ) -> (() -> Void) {
        onUpdate([
            Message(
                id: "1",
                senderID: "user2",
                receiverID: "user1",
                text: "Hey! Is your dog friendly?",
                timestamp: Date().addingTimeInterval(-300)
            ),
            Message(
                id: "2",
                senderID: "user1",
                receiverID: "user2",
                text: "Yes, very! Want to meet at the park?",
                timestamp: Date().addingTimeInterval(-180)
            ),
            Message(
                id: "3",
                senderID: "user2",
                receiverID: "user1",
                text: "Perfect, see you at 3pm!",
                timestamp: Date().addingTimeInterval(-60)
            ),
        ])
        return {}
    }
}

#Preview {
    let viewModel = ChatViewModel(repository: MockThreadRepository())
    let conversation = Conversation(
        id: "conv1",
        participantIDs: ["user1", "user2"],
        lastMessage: "Perfect, see you at 3pm!",
        lastMessageTimestamp: Date().addingTimeInterval(-60)
    )
    NavigationStack {
        ConversationView(conversation: conversation, currentUserID: "user1")
    }
    .environment(viewModel)
}
