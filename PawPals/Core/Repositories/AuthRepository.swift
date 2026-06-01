import Foundation

protocol AuthRepository {
    func signUp(email: String, password: String) async throws -> User
    func signUpWithGoogle() async throws -> User
    func signOut() throws
    func signIn(email: String, password: String) async throws -> User
    func signInWithGoogle() async throws -> User
    func deleteAccount() async throws
    
    
}
