import SwiftUI

struct ConversationRowView: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Circle()
                .fill(Theme.surface)
                .frame(width: IconSize.chatAvatar, height: IconSize.chatAvatar)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(conversation.participantIDs.first ?? "Unknown")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)

                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }
            Spacer()

            Text(conversation.lastMessageTimestamp, style: .time)
                .font(.caption)
                .foregroundStyle(Theme.muted)
        }
        .padding(Spacing.xSmall)
    }
}

#Preview {
    let mockConversation = Conversation(
        id: "1",
        participantIDs: ["Anna", "Patrik"],
        lastMessage: "Hey, want to go for a walk?",
        lastMessageTimestamp: Date()
    )
    ConversationRowView(conversation: mockConversation)
        .padding()
}
