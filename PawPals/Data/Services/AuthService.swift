import FirebaseAuth

final class AuthService: AuthRepository {

    func signUp(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return User(
                id: result.user.uid,
                name: result.user.displayName ?? "",
                photoURL: result.user.photoURL?.absoluteString,
                bio: "",
                city: "",
                dogs: [],
                preferences: UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10)
            )
        } catch let error as NSError {
            switch error.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue,
                 AuthErrorCode.invalidEmail.rawValue,
                 AuthErrorCode.wrongPassword.rawValue:
                throw AuthError.invalidCredential
            default:
                throw AuthError.unknown
            }
        }
    }

    func signUpWithGoogle() async throws {
        throw AuthError.notImplemented
    }
}
