import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.large)
            .background(Theme.offWhite)
            .clipShape(RoundedRectangle(cornerRadius: Radius.large))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

