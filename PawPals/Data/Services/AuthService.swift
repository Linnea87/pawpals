import Foundation
import FirebaseAuth

final class AuthService: AuthRepository {

    func signUp(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func signUpWithGoogle() async throws {
        // TODO [PP-002]: Implement when Google Sign-In is configured
        throw AuthError.notImplemented
    }
}
