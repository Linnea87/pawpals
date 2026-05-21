import Foundation
import FirebaseFirestore

protocol UserRepository {
    
    func updateProfile(_ user: User) async throws
    func saveDog(_ dog: Dog, userId: String) async throws
    func updateLocation(_ location: GeoPoint, userId: String) async throws

    
}
