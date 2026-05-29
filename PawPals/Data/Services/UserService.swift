import Foundation
import FirebaseFirestore

final class UserService: UserRepository {
    private let db = Firestore.firestore()

    func updateProfile(_ user: User) async throws {
        var data: [String: Any] = ["name": user.name]
        if let photoURL = user.photoURL {
            data["photoURL"] = photoURL
        }
        try await db.collection("users").document(user.id).setData(data, merge: true)
    }
    
    func saveDog(_ dog: Dog, userId: String) async throws {
        try db.collection("users")
            .document(userId)
            .collection("dogs")
            .document(dog.id)
            .setData(from: dog)
    }
    
    func fetchNearbyUsers(location: GeoPoint, radius: Double) async throws -> [User] {
        let snapshot = try await db.collection("users").getDocuments()
        return try snapshot.documents.compactMap { doc in
            try doc.data(as: User.self)
        }
    }
    
    func updateLocation(_ location: GeoPoint, userId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .setData(["location": location], merge: true)
    }
    
    func savePreferences(_ prefs: UserPreferences, userId: String) async throws {
        // Firebase implementation comes here
    }

    func loadPreferences(userId: String) async throws -> UserPreferences {
        // Firebase implementation comes here
        fatalError("Not implemented yet")
    }
    
    func savePushNotificationToken(_ token: String, userID: String) async throws {
            try await db.collection("users")
                .document(userID)
                .setData(["pushNotificationToken": token], merge: true)
        }
}
