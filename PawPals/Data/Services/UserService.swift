import Foundation
import FirebaseFirestore

final class UserService: UserRepository {
    private let db = Firestore.firestore()

    func updateProfile(_ user: User) async throws {
        var data: [String: Any] = [
            "name": user.name,
            "bio": user.bio,
            "city": user.city
        ]
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
    
    func removeDog(dogId: String, userId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("dogs")
            .document(dogId)
            .delete()
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
        let data: [String: Any] = [
            "preferences": [
                "walkTypes": prefs.walkTypes.map { $0.rawValue },
                "dogSize": prefs.dogSize.rawValue,
                "searchRadius": prefs.searchRadius
            ]
        ]
        try await db.collection("users").document(userId).setData(data, merge: true)
    }

    func loadPreferences(userId: String) async throws -> UserPreferences {
        let doc = try await db.collection("users").document(userId).getDocument()
        guard let data = doc.data(),
              let prefsData = data["preferences"] as? [String: Any] else {
            return UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10.0)
        }
        let walkTypes = (prefsData["walkTypes"] as? [String] ?? []).compactMap(WalkType.init(rawValue:))
        let dogSize = DogSize(rawValue: prefsData["dogSize"] as? String ?? "") ?? .medium
        let searchRadius = prefsData["searchRadius"] as? Double ?? 10.0
        return UserPreferences(walkTypes: walkTypes, dogSize: dogSize, searchRadius: searchRadius)
    }

    func savePushNotificationToken(_ token: String, userID: String) async throws {
        try await db.collection("users")
            .document(userID)
            .setData(["pushNotificationToken": token], merge: true)
    }
    
    func deleteUserData(userId: String) async throws {
        let batch = db.batch()
        let dogsSnapshot = try await db.collection("users").document(userId).collection("dogs").getDocuments()
        for doc in dogsSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        batch.deleteDocument(db.collection("users").document(userId))
        try await batch.commit()

        let conversationsSnapshot = try await db.collection("conversations")
            .whereField("participantIDs", arrayContains: userId)
            .getDocuments()
        for conversationDoc in conversationsSnapshot.documents {
            let messagesSnapshot = try await conversationDoc.reference.collection("messages").getDocuments()
            let messageBatch = db.batch()
            for messageDoc in messagesSnapshot.documents {
                messageBatch.deleteDocument(messageDoc.reference)
            }
            messageBatch.deleteDocument(conversationDoc.reference)
            try await messageBatch.commit()
        }
    }
}
