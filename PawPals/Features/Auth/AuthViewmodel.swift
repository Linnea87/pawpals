import Foundation

@Observable
final class AuthViewModel {
    var isLoading = false
    var errorMessage: String? = nil
    var currentUser: User? = nil

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
