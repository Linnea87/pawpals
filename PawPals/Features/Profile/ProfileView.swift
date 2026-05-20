import SwiftUI
import PhotosUI

struct ProfileView: View {

    let user: User
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.appBackground
                    .ignoresSafeArea()

                List {
                    HStack(spacing: Spacing.medium) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Circle()
                                .fill(Theme.muted)
                                .frame(width: IconSize.avatar, height: IconSize.avatar)
                                .overlay {
                                    Image(systemName: "person")
                                        .font(.system(size: IconSize.avatarIcon))
                                        .foregroundStyle(.white)
                                }
                        }

                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(user.displayName)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.textPrimary)

                            HStack(spacing: Spacing.xSmall) {
                                Image(systemName: "pawprint")
                                    .font(.caption2)
                                Text(user.city)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Theme.textPrimary.opacity(0.5))
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, Spacing.small)

                    Section {
                        Text(user.bio)
                            .font(.callout)
                            .foregroundStyle(Theme.textPrimary)
                            .listRowBackground(Color.white.opacity(0.6))
                    } header: {
                        Text("profile.aboutUs")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

#Preview {
    ProfileView(user: User(
        id: "preview-1",
        displayName: "Sara",
        photoURL: nil,
        city: "Gothenburg",
        bio: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin metus odio, dapibus et ornare in, malesuada et mauris."
    ))
}
