import SwiftUI

struct SocialAuthButtons: View {
    let label: LocalizedStringKey
    let action: () async -> Void

    var body: some View {
        VStack(spacing: Spacing.medium) {
            HStack {
                Rectangle()
                    .fill(Theme.creamWhite)
                    .frame(height: AuthLayout.borderWidth)
                Text("auth.or")
                    .font(.footnote)
                    .foregroundStyle(Theme.creamWhite)
                Rectangle()
                    .fill(Theme.creamWhite)
                    .frame(height: AuthLayout.borderWidth)
            }
            .padding(.top, Spacing.medium)

            Button {
                Task { await action() }
            } label: {
                HStack {
                    Image(systemName: "globe")
                    Text(label)
                }
                .fontWeight(.medium)
                .foregroundStyle(Theme.darkBrown)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.small)
            }
            .background(Theme.creamWhite)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    Theme.darkBrown.opacity(AuthLayout.borderOpacity),
                    lineWidth: AuthLayout.borderWidth
                )
            )
        }
    }
}
