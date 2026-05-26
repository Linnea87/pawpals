import Foundation

protocol AuthRepository {
    func signUp(email: String, password: String) async throws -> User
    func signUpWithGoogle() async throws
    func signIn(email: String, password: String) async throws -> User
    func signInWithGoogle() async throws -> User
    
    
}
