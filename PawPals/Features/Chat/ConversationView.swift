import SwiftUI

struct ConversationView: View {
    @Environment(ChatViewModel.self) private var chatViewModel
    let conversation: Conversation
    let currentUserID: String

    var body: some View {
        @Bindable var chatViewModel = chatViewModel

        ZStack {
            Theme.appBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.none) {
                if chatViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: Spacing.small) {
                                DateSeparatorView(date: Date())

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
                    Task {
                        await chatViewModel.sendMessage(
                            in: conversation,
                            senderID: currentUserID
                        )
                    }
                }
            }
        }
        .navigationTitle(
            chatViewModel.otherParticipantName(
                in: conversation,
                currentUserID: currentUserID
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            chatViewModel.observeMessages(conversationID: conversation.id)
        }
        .onDisappear {
            chatViewModel.stopListening()
        }
        .alert(
            String(localized: "common.error"),
            isPresented: .constant(chatViewModel.errorMessage != nil)
        ) {
            Button(String(localized: "common.ok")) {
                chatViewModel.errorMessage = nil
            }
        } message: {
            Text(chatViewModel.errorMessage ?? "")
        }
    }
}

private struct DateSeparatorView: View {
    let date: Date

    private var label: LocalizedStringKey {
        if Calendar.current.isDateInToday(date) { return "date.today" }
        if Calendar.current.isDateInYesterday(date) { return "date.yesterday" }
        return LocalizedStringKey(date.formatted(date: .abbreviated, time: .omitted))
    }

    var body: some View {
        Text(label)
            .font(.caption)
            .foregroundStyle(Theme.muted)
            .padding(.vertical, Spacing.small)
    }
}

private struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if !isFromCurrentUser {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(message.text)
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, Spacing.small)
                        .background(Theme.surface)
                        .foregroundStyle(Theme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
            } else {
                Spacer()
                VStack(alignment: .trailing, spacing: Spacing.xSmall) {
                    Text(message.text)
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, Spacing.small)
                        .background(Theme.brand)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }
            }
        }
    }
}

private struct MessageInputBar: View {
    @Binding var text: String
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "face.smiling")
                    .foregroundStyle(Theme.muted)

                TextField("chat.messagePlaceholder", text: $text)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(Theme.inputBackground)
            .clipShape(Capsule())

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: Spacing.large, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(Spacing.medium)
                    .background(
                        text.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Theme.muted
                            : Theme.brand
                    )
                    .clipShape(Circle())
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.medium)
        .background(Theme.surface)
    }
}

// ------------------- Preview --------------------------//

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
                text: "Hey! Bella would love to meet May 🐾",
                timestamp: Date().addingTimeInterval(-300)
            ),
            Message(
                id: "2",
                senderID: "user1",
                receiverID: "user2",
                text: "Oh that sounds perfect! When are you free?",
                timestamp: Date().addingTimeInterval(-240)
            ),
            Message(
                id: "3",
                senderID: "user2",
                receiverID: "user1",
                text: "How about Saturday morning at Humlegården?",
                timestamp: Date().addingTimeInterval(-180)
            ),
            Message(
                id: "4",
                senderID: "user1",
                receiverID: "user2",
                text: "Yes! 10am works great for us 🐕",
                timestamp: Date().addingTimeInterval(-120)
            ),
            Message(
                id: "5",
                senderID: "user2",
                receiverID: "user1",
                text: "Can't wait! See you there 🌿",
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
        lastMessage: "Can't wait! See you there",
        lastMessageTimestamp: Date().addingTimeInterval(-60)
    )
    NavigationStack {
        ConversationView(conversation: conversation, currentUserID: "user1")
    }
    .environment(viewModel)
}
