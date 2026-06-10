import SwiftUI

struct SavedProfilesSection: View {
    let savedUsers: [User]

    var body: some View {
        if !savedUsers.isEmpty {
            Section {
                ForEach(savedUsers) { savedUser in
                    HStack(spacing: Spacing.medium) {
                        AvatarView(
                            photoURL: savedUser.photoURL,
                            size: IconSize.savedAvatar,
                            iconSize: IconSize.avatarIcon
                        )
                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(savedUser.name).fontWeight(.medium)
                            Text(savedUser.city)
                                .font(.caption)
                                .foregroundStyle(Theme.warmBrown)
                        }
                    }
                    .listRowBackground(Theme.offWhite.opacity(0.6))
                }
            } header: {
                SectionHeader(title: "profile.savedProfiles")
            }
        }
    }
}
