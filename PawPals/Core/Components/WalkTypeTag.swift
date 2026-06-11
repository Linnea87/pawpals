import SwiftUI

struct WalkTypeTag: View {
    let walkType: WalkType

    var body: some View {
        Text(walkType.displayName)
            .font(.caption)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(Theme.terracotta)
            .foregroundStyle(Theme.offWhite)
            .clipShape(Capsule())
    }
}
