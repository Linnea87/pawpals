import Foundation

protocol AuthRepository {
    func signUp(email: String, password: String) async throws
    func signUpWithGoogle() async throws
}
