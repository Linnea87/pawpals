import Foundation

protocol AuthRepository {
    
    /// Creates a new user account with email and password.
    func signUp(email: String, password: String) async throws -> User

    /// Creates a new user account via Google Sign-In.
    func signUpWithGoogle() async throws -> User

    /// Signs in an existing user with email and password.
    func signIn(email: String, password: String) async throws -> User

    /// Signs in an existing user via Google Sign-In.
    func signInWithGoogle() async throws -> User

    /// Signs the current user out.
    func signOut() throws

    /// Permanently deletes the current user's account and all associated data.
    func deleteAccount() async throws
    
}
