import SwiftUI

struct SectionHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.subheadline)
            .foregroundStyle(Theme.darkBrown)
    }
}
