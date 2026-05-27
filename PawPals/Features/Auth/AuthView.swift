import SwiftUI

struct AuthView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @State private var showSignIn = false
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            VStack(spacing: Spacing.none) {
                Spacer()
                    .frame(minHeight: AuthLayout.topSpacing)
                logoSection
                Spacer()
                    .frame(minHeight: AuthLayout.middleSpacing)
                welcomeCard
                Spacer()
                    .frame(minHeight: AuthLayout.bottomSpacing)
            }
            .padding(.horizontal, Spacing.large)
        }
        // TODO: PP-002 — uncomment when SignInView and SignUpView are coded
        .sheet(isPresented: $showSignIn) {
             SignInView()
        }
        .sheet(isPresented: $showSignUp) {
             SignUpView()
         }
    }

    private var logoSection: some View {
        VStack(spacing: Spacing.small) {
            Circle()
                .fill(Theme.offWhite.opacity(AuthLayout.circleOpacity))
                .frame(width: IconSize.avatar, height: IconSize.avatar)
                .overlay {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: IconSize.logoIcon))
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
                    viewModel.activeOption = .signIn
                    showSignIn = true
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.small)
                .background(viewModel.activeOption == .signIn ? Theme.terracotta : Theme.offWhite)
                .foregroundStyle(viewModel.activeOption == .signIn ? Theme.offWhite : Theme.darkBrown)
                .fontWeight(viewModel.activeOption == .signIn ? .semibold : .regular)
                .clipShape(Capsule())

                Button(String(localized: "auth.sign.up")) {
                    viewModel.activeOption = .signUp
                    showSignUp = true
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.small)
                .background(viewModel.activeOption == .signUp ? Theme.terracotta : Theme.offWhite)
                .foregroundStyle(viewModel.activeOption == .signUp ? Theme.offWhite : Theme.darkBrown)
                .fontWeight(viewModel.activeOption == .signUp ? .semibold : .regular)
                .clipShape(Capsule())
            }
            .padding(.top, Spacing.large)
        }
        .padding(Spacing.large)
        .background(Theme.offWhite.opacity(AuthLayout.cardOpacity))
        .clipShape(RoundedRectangle(cornerRadius: Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.large)
                .stroke(Theme.creamWhite, lineWidth: AuthLayout.borderWidth)
        )
        .shadow(color: .black.opacity(AuthLayout.shadowOpacity), radius: AuthLayout.shadowRadius, x: Spacing.none, y: AuthLayout.shadowY)
    }
}


#Preview {
    AuthView()
        .environment(AuthViewModel(repository: MockAuthRepository()))
}

private struct MockAuthRepository: AuthRepository {
    func signUp(email: String, password: String) async throws -> User {
        User(id: "preview", name: "", photoURL: nil, bio: "", city: "",
             dogs: [], preferences: UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10),
             distance: nil)
    }
    func signUpWithGoogle() async throws -> User {
            User(id: "preview", name: "", photoURL: nil, bio: "", city: "",
                 dogs: [], preferences: UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10),
                 distance: nil)
    }
    func signOut() throws {}
    
    func signIn(email: String, password: String) async throws -> User {
        User(id: "preview", name: "", photoURL: nil, bio: "", city: "",
             dogs: [], preferences: UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10),
             distance: nil)
    }
    func signInWithGoogle() async throws -> User {
        User(id: "preview", name: "", photoURL: nil, bio: "", city: "",
             dogs: [], preferences: UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10),
             distance: nil)
    }
}
