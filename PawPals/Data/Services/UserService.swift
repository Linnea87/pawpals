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
    func savePreferences(_ prefs: UserPreferences, userId: String) async throws {
        // Firebase implementation comes here
    }

    func loadPreferences(userId: String) async throws -> UserPreferences {
        // Firebase implementation comes here
        fatalError("Not implemented yet")
    }
}
