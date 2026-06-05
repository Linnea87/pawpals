import SwiftUI

struct MeetCardView: View {
    let user: User
    let isSaved: Bool
    
    var body: some View {
        HStack(spacing: Spacing.medium) {
            Circle()
                .fill(Theme.lightPeach)
                .frame(width: IconSize.chatAvatar, height: IconSize.chatAvatar)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Theme.offWhite)
                }
            
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
                    Text(walkType.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, Spacing.xSmall)
                        .background(Theme.terracotta)
                        .foregroundStyle(Theme.offWhite)
                        .clipShape(Capsule())
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
