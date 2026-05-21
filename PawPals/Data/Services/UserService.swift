import Foundation
import FirebaseFirestore

final class UserService: UserRepository {

    func updateProfile(_ user: User) async throws {
        // Firebase implementation comes here
    }
    
    func saveDog(_ dog: Dog, userId: String) async throws {
            // Firebase implementation comes here
    }
    func updateLocation(_ location: GeoPoint, userId: String) async throws {
        // Firebase implementation comes here

    }
}
