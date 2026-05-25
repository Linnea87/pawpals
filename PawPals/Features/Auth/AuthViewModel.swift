import Foundation

@Observable
final class AuthViewModel {
    var isLoading = false
    var errorMessage: String? = nil
    var currentUser: User? = nil
    var isAuthenticated: Bool { currentUser != nil }
    var activeOption: AuthOption = .signIn

    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func signUp(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await repository.signUp(email: email, password: password)
        } catch let error as AuthError {
            switch error {
            case .notImplemented: errorMessage = String(localized: "auth.error.not.implemented")
            case .invalidCredential: errorMessage = String(localized: "auth.error.invalid.credential")
            case .unknown: errorMessage = String(localized: "auth.error.unknown")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUpWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await repository.signUpWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
