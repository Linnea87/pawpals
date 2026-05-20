import Foundation

protocol UserRepository {
    
    func updateProfile(_ user: User) async throws
    func saveDog(_ dog: Dog, userId: String) async throws
    
}
