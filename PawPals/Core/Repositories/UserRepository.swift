import Foundation
import FirebaseFirestore

protocol UserRepository {
    
    func updateProfile(_ user: User) async throws
    func saveDog(_ dog: Dog, userId: String) async throws
    func removeDog(dogId: String, userId: String) async throws
    func fetchNearbyUsers(location: GeoPoint, radius: Double) async throws -> [User]
    func updateLocation(_ location: GeoPoint, userId: String) async throws
    func savePreferences(_ prefs: UserPreferences, userId: String) async throws
    func loadPreferences(userId: String) async throws -> UserPreferences
    func savePushNotificationToken(_ token: String, userID: String) async throws

    
}
