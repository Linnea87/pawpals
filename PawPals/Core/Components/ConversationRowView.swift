import SwiftUI

/// A single row in the chat list showing the other participant's avatar, name,
/// message preview, timestamp, and unread badge.
///
/// Previously this view used conversation.participantIDs.first as the display name,
/// which showed the raw Firebase UID string instead of the actual user's name.
/// It now receives otherUserName and otherUserPhotoURL from ChatView, which resolves
/// them from the participants cache in ChatViewModel before passing them in.
struct ConversationRowView: View {
    let conversation: Conversation
    let timestampText: String
    let otherUserName: String
    let otherUserPhotoURL: String?

    var body: some View {
        HStack(spacing: Spacing.medium) {
            AvatarView(photoURL: otherUserPhotoURL, size: IconSize.chatAvatar, iconSize:
             IconSize.avatarIcon)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(otherUserName)
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
    ConversationRowView(conversation: mockConversation, timestampText: "Today", otherUserName: "Anna", otherUserPhotoURL: nil)
           .padding()
}
