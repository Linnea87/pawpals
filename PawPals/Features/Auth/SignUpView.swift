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
        .alert(
            String(localized: "common.error"),
            isPresented: .constant(viewModel.errorMessage != nil)
        ) {
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
        VStack(spacing: Spacing.medium) {
            Button {
                Task {
                    await viewModel.signUp(
                        name: name,
                        email: email,
                        password: password
                    )
                }
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

            SocialAuthButtons(label: "auth.signup.google") {
                await viewModel.signUpWithGoogle()
            }
        }
    }
}

#Preview {
    SignUpView()
        .environment(
            AuthViewModel(
                repository: MockAuthRepository(),
                userRepository: MockUserRepository()
            )
        )
}