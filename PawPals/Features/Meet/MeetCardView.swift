import SwiftUI

struct MeetCardView: View {
    let user: User
    let isSaved: Bool
    
    var body: some View {
        HStack(spacing: Spacing.medium) {
            AvatarView(photoURL: user.photoURL, size: IconSize.chatAvatar, iconSize:
             IconSize.avatarIcon)
            
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(user.dogs.first.map { "\(user.name) / \($0.name)" } ?? user.name)
                    .font(.headline)
                    .foregroundStyle(Theme.darkBrown)
                
                if let distance = user.distance {
                    Label(String(format: "%.1f km", distance), systemImage: "pawprint")
                        .font(.caption)
                        .foregroundStyle(Theme.warmBrown)
                }
                
                Text(user.bio)
                    .font(.subheadline)
                    .foregroundStyle(Theme.sageGreen)
                    .lineLimit(1)
                    .padding(Spacing.xSmall)
                
                if let walkType = user.preferences.walkTypes.first {
                    WalkTypeTag(walkType: walkType)
                        .font(.caption2)
                }
            }
            
            VStack {
                if isSaved {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Theme.terracotta)
                }
                Spacer()
            }
        }
        .padding(Spacing.large)
        .background(Theme.offWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    MeetCardView(user: .mock, isSaved: false)
        .padding()
}
