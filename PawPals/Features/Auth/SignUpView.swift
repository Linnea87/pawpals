import SwiftUI

struct SignUpView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.none) {
                    fieldsSection
                    buttonsSection
                }
                .padding(.horizontal, Spacing.large)
                .padding(.top, Spacing.xLarge)
            }
        }
        .presentationDetents([.fraction(AuthLayout.sheetFraction)])
        .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated { dismiss() }
        }
        .alert(String(localized: "common.error"), isPresented: .constant(viewModel.errorMessage != nil)) {
            Button(String(localized: "common.ok")) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var fieldsSection: some View {
        VStack(spacing: Spacing.medium) {
            HStack {
                Image(systemName: "person")
                    .foregroundStyle(Theme.sageGreen)
                TextField(String(localized: "auth.signup.name"), text: $name)
                    .textInputAutocapitalization(.words)
            }
            .padding(Spacing.medium)
            .background(Theme.offWhite)
            .clipShape(RoundedRectangle(cornerRadius: Radius.small))

            HStack {
                Image(systemName: "envelope")
                    .foregroundStyle(Theme.sageGreen)
                TextField(String(localized: "auth.email"), text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(Spacing.medium)
            .background(Theme.offWhite)
            .clipShape(RoundedRectangle(cornerRadius: Radius.small))

            HStack {
                Image(systemName: "lock")
                    .foregroundStyle(Theme.sageGreen)
                SecureField(String(localized: "auth.password"), text: $password)
            }
            .padding(Spacing.medium)
            .background(Theme.offWhite)
            .clipShape(RoundedRectangle(cornerRadius: Radius.small))

            Text(String(localized: "auth.signup.terms"))
                .font(.caption)
                .foregroundStyle(Theme.darkBrown)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.large)
    }

    private var buttonsSection: some View {
        // TODO: PP-003 — Extract shared auth buttons (Google + Or divider) to Core/Components/AuthButtonsView
        VStack(spacing: Spacing.medium) {
            Button {
                Task { await viewModel.signUp(name: name, email: email, password: password) }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Theme.offWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.small)
                } else {
                    Text(String(localized: "auth.sign.up"))
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.offWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.small)
                }
            }
            .background(Theme.terracotta)
            .clipShape(Capsule())
            .disabled(viewModel.isLoading)

            HStack {
                Rectangle()
                    .fill(Theme.creamWhite)
                    .frame(height: AuthLayout.borderWidth)
                Text("Or")
                    .font(.footnote)
                    .foregroundStyle(Theme.creamWhite)
                Rectangle()
                    .fill(Theme.creamWhite)
                    .frame(height: AuthLayout.borderWidth)
            }
            .padding(.top, Spacing.medium)

            Button {
                // TODO: PP-004 — Task { await viewModel.signUpWithGoogle() }
            } label: {
                HStack {
                    Image(systemName: "globe")
                    Text(String(localized: "auth.signup.google"))
                }
                .fontWeight(.medium)
                .foregroundStyle(Theme.darkBrown)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.small)
            }
            .background(Theme.creamWhite)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Theme.darkBrown.opacity(AuthLayout.borderOpacity), lineWidth: AuthLayout.borderWidth))
        }
    }
}

#Preview {
    SignUpView()
        .environment(AuthViewModel(repository: MockAuthRepository()))
}

private struct MockAuthRepository: AuthRepository {
    func signUp(email: String, password: String) async throws -> User {
        User(id: "preview", name: "", photoURL: nil, bio: "", city: "",
             dogs: [], preferences: UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10),
             distance: nil)
    }
    func signUpWithGoogle() async throws {}
}
