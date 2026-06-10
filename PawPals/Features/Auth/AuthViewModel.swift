import Foundation

@Observable
final class AuthViewModel {
    var isLoading = false
    var errorMessage: String? = nil
    var currentUser: User? = nil
    var isAuthenticated: Bool { currentUser != nil }
    var currentUserID: String { currentUser?.id ?? "" }
    var activeOption: AuthOption = .signIn

    private let repository: AuthRepository
    private let userRepository: ProfileRepository

    init(repository: AuthRepository, userRepository: ProfileRepository) {
        self.repository = repository
        self.userRepository = userRepository
    }

    func signUp(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            var user = try await repository.signUp(email: email, password: password)
            user.name = name
            currentUser = user
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
                currentUser = try await repository.signUpWithGoogle()
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
    
    func signOut() {
        do {
            try repository.signOut()
            currentUser = nil
            errorMessage = nil
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
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            currentUser = try await repository.signIn(email: email, password: password)
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

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            currentUser = try await repository.signInWithGoogle()
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
    
    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        guard let userID = currentUser?.id else { return }
        do {
            try await userRepository.deleteUserData(userID: userID)
            try await repository.deleteAccount()
            currentUser = nil
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
}
