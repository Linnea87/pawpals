import SwiftUI

struct AboutSection: View {
    let user: User

    var body: some View {
        Section {
            Text(user.bio)
                .font(.callout)
                .foregroundStyle(Theme.darkBrown)
                .listRowBackground(Theme.offWhite.opacity(0.6))

            if !user.preferences.walkTypes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.small) {
                        ForEach(user.preferences.walkTypes) { walkType in
                            WalkTypeTag(walkType: walkType)
                        }
                    }
                }
                .listRowBackground(Theme.offWhite.opacity(0.6))
            }
        } header: {
            SectionHeader(title: "profile.aboutUs")
        }
    }
}
