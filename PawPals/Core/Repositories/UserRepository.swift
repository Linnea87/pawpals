import Foundation

protocol UserRepository {
    
    func updateProfile(_ user: User) async throws
}
