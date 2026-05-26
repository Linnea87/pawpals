import Foundation
import FirebaseFirestore

protocol UserRepository {
    
    func updateProfile(_ user: User) async throws
    func saveDog(_ dog: Dog, userId: String) async throws
    func fetchNearbyUsers(location: GeoPoint, radius: Double) async throws -> [User]
    func updateLocation(_ location: GeoPoint, userId: String) async throws

    
}
