import SwiftUI

private enum AuthOption {
    case signIn, signUp
}

struct AuthView: View {
    @State private var showSignIn = false
    @State private var showSignUp = false
    @State private var activeOption: AuthOption = .signIn

    var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(minHeight: 60)
                logoSection
                Spacer()
                    .frame(minHeight: 40)
                welcomeCard
                Spacer()
                    .frame(minHeight: 250)
            }
            .padding(.horizontal, Spacing.large)
        }
        // TODO: PP-002 — uncomment when SignInView and SignUpView are coded
        // .sheet(isPresented: $showSignIn) {
        //     SignInView()
        // }
        // .sheet(isPresented: $showSignUp) {
        //     SignUpView()
        // }
    }

    private var logoSection: some View {
        VStack(spacing: Spacing.small) {
            Circle()
                .fill(Theme.offWhite.opacity(0.5))
                .frame(width: 90, height: 90)
                .overlay {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.terracotta)
                }

            Text("PawPals")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Theme.darkBrown)

            Text(String(localized: "auth.tagline"))
                .font(.caption)
                .foregroundStyle(Theme.creamWhite)
        }
    }

    private var welcomeCard: some View {
        VStack(spacing: Spacing.small) {
            VStack(spacing: Spacing.small) {
                Text(String(localized: "auth.welcome"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.darkBrown)

                Text(String(localized: "auth.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(Theme.darkBrown)
            }

            HStack(spacing: Spacing.medium) {
                Button(String(localized: "auth.sign.in")) {
                    activeOption = .signIn
                    // TODO: PP-002 — showSignIn = true
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.small)
                .background(activeOption == .signIn ? Theme.terracotta : Theme.offWhite)
                .foregroundStyle(activeOption == .signIn ? Theme.offWhite : Theme.darkBrown)
                .fontWeight(activeOption == .signIn ? .semibold : .regular)
                .clipShape(Capsule())

                Button(String(localized: "auth.sign.up")) {
                    activeOption = .signUp
                    // TODO: PP-002 — showSignUp = true
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.small)
                .background(activeOption == .signUp ? Theme.terracotta : Theme.offWhite)
                .foregroundStyle(activeOption == .signUp ? Theme.offWhite : Theme.darkBrown)
                .fontWeight(activeOption == .signUp ? .semibold : .regular)
                .clipShape(Capsule())
            }
            .padding(.top, Spacing.large)
        }
        .padding(Spacing.large)
        .background(Theme.offWhite.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.large)
                .stroke(Theme.creamWhite, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
       

    }
}

#Preview {
    AuthView()
}
