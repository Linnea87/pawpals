import SwiftUI

struct ConversationRowView: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Circle()
                .fill(Theme.lightPeach)
                .frame(width: IconSize.chatAvatar, height: IconSize.chatAvatar)
                .overlay {
                    Image(systemName: "person")
                        .foregroundStyle(Theme.warmBrown)
                }

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(
                    conversation.participantIDs.first
                        ?? String(localized: "common.unknown")
                )
                .font(.headline)
                .foregroundStyle(Theme.darkBrown)

                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundStyle(Theme.warmBrown)
                    .lineLimit(1)
            }

            Spacer()

            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(Spacing.small)
                    .background(Theme.terracotta)
                    .clipShape(Circle())
            }
        }
        .padding(Spacing.large)
        .background(Theme.offWhite)
        .clipShape(RoundedRectangle(cornerRadius: Radius.large))
    }
}

#Preview {
    let mockConversation = Conversation(
        id: "1",
        participantIDs: ["Anna", "Patrik"],
        lastMessage: "Hey, want to go for a walk?",
        lastMessageTimestamp: Date(),
        unreadCount: 2
    )
    ConversationRowView(conversation: mockConversation)
        .padding()
}
