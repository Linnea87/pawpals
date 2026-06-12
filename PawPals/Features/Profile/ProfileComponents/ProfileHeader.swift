import PhotosUI
import SwiftUI

struct ProfileHeaderView: View {
    let user: User
    let isOwner: Bool
    @Binding var selectedPhoto: PhotosPickerItem?

    var body: some View {
        HStack(spacing: Spacing.medium) {
            if isOwner {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    AvatarView(
                        photoURL: user.photoURL,
                        size: IconSize.avatar,
                        iconSize: IconSize.avatarIcon
                    )
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
            } else {
                AvatarView(
                    photoURL: user.photoURL,
                    size: IconSize.avatar,
                    iconSize: IconSize.avatarIcon
                )
            }

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(user.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.darkBrown)

                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "pawprint")
                        .font(.caption2)
                    Text(user.city)
                        .font(.subheadline)
                }
                .foregroundStyle(Theme.warmBrown)
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .padding(.vertical, Spacing.small)
    }
}
