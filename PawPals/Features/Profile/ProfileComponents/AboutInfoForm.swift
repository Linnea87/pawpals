import SwiftUI

struct AboutInfoForm: View {
    @Binding var name: String
    @Binding var bio: String

    var body: some View {
        Section {
            TextField("profile.name", text: $name)
                .listRowBackground(Theme.offWhite.opacity(Opacity.xSmall))
            TextField("profile.bio", text: $bio, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .listRowBackground(Theme.offWhite.opacity(Opacity.xSmall))
        } header: {
            SectionHeader(title: "profile.aboutUs")
        }
        .padding(.top, Spacing.large)
    }
}
