import SwiftUI

struct SavedProfilesSection: View {
    let savedUsers: [User]
    let onSelect: (User) -> Void

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
                    .listRowBackground(Theme.offWhite.opacity(Opacity.xSmall))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(savedUser)
                    }
                }
            } header: {
                SectionHeader(title: "profile.savedProfiles")
            }
        }
    }
}
