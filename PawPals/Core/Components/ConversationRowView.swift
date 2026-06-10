import SwiftUI

/// A single row in the chat list showing the other participant's avatar, name,
/// message preview, timestamp, and unread badge.
struct ConversationRowView: View {
    let conversation: Conversation
    let timestampText: String
    let otherUser: User?

    var body: some View {
        HStack(spacing: Spacing.medium) {
            AvatarView(photoURL: otherUser?.photoURL, size: IconSize.chatAvatar, iconSize: IconSize.avatarIcon)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(otherUser?.name ?? String(localized: "common.unknown"))
                .font(.headline)
                .foregroundStyle(Theme.darkBrown)

                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundStyle(Theme.warmBrown)
                    .lineLimit(1)
            }

            Spacer()
            
            VStack(alignment: .trailing, spacing: Spacing.xSmall) {
                Text(timestampText)
                    .font(.caption)
                    .foregroundStyle(Theme.warmBrown)
                
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
        }
        .cardStyle()
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
    ConversationRowView(conversation: mockConversation, timestampText: "Today", otherUser: nil)
        .padding()
}
