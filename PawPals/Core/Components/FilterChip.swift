import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.medium)
                .background(isSelected ? Theme.sageGreen : Theme.offWhite)
                .foregroundStyle(isSelected ? Theme.offWhite : Theme.darkBrown)
                .clipShape(Capsule())
        }
    }
}
