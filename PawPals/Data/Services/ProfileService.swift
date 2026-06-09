import CoreLocation
import FirebaseFirestore
import FirebaseStorage
import Foundation

enum ProfileServiceError: Error {
    case notFound
}


final class ProfileService: ProfileRepository {
    private let db = Firestore.firestore()
  
    func updateProfile(_ user: User) async throws {
        var data: [String: Any] = [
            "name": user.name,
            "bio": user.bio,
            "city": user.city,
        ]
        if let photoURL = user.photoURL {
            data["photoURL"] = photoURL
        }
        try await db.collection("users").document(user.id).setData(
            data,
            merge: true
        )
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
    
    
    func fetchUser(userId: String) async throws -> User {
        let doc = try await db.collection("users").document(userId)
            .getDocument()
        guard let data = doc.data() else { throw ProfileServiceError.notFound }

        let dogsSnapshot = try await db.collection("users")
            .document(userId)
            .collection("dogs")
            .getDocuments()
        let dogs = dogsSnapshot.documents.compactMap {
            try? $0.data(as: Dog.self)
        }

        return User(
            id: userId,
            name: data["name"] as? String ?? "",
            photoURL: data["photoURL"] as? String,
            bio: data["bio"] as? String ?? "",
            city: data["city"] as? String ?? "",
            dogs: dogs,
            preferences: UserPreferences(
                walkTypes: [],
                dogSize: .medium,
                searchRadius: 10.0
            ),
            distance: nil,
            latitude: data["latitude"] as? Double,
            longitude: data["longitude"] as? Double
        )
    }

    
    func savePreferences(_ prefs: UserPreferences, userId: String) async throws
    {
        let data: [String: Any] = [
            "preferences": [
                "walkTypes": prefs.walkTypes.map { $0.rawValue },
                "dogSize": prefs.dogSize.rawValue,
                "searchRadius": prefs.searchRadius,
            ]
        ]
        try await db.collection("users").document(userId).setData(
            data,
            merge: true
        )
    }

    func loadPreferences(userId: String) async throws -> UserPreferences {
        let doc = try await db.collection("users").document(userId)
            .getDocument()
        guard let data = doc.data(),
            let prefsData = data["preferences"] as? [String: Any]
        else {
            return UserPreferences(
                walkTypes: [],
                dogSize: .medium,
                searchRadius: 10.0
            )
        }
        let walkTypes = (prefsData["walkTypes"] as? [String] ?? []).compactMap(
            WalkType.init(rawValue:)
        )
        let dogSize =
            DogSize(rawValue: prefsData["dogSize"] as? String ?? "") ?? .medium
        let searchRadius = prefsData["searchRadius"] as? Double ?? 10.0
        return UserPreferences(
            walkTypes: walkTypes,
            dogSize: dogSize,
            searchRadius: searchRadius
        )
    }

    func savePushNotificationToken(_ token: String, userID: String) async throws
    {
        try await db.collection("users")
            .document(userID)
            .setData(["pushNotificationToken": token], merge: true)
    }

    func deleteUserData(userId: String) async throws {
        let batch = db.batch()
        let dogsSnapshot = try await db.collection("users").document(userId)
            .collection("dogs").getDocuments()
        for doc in dogsSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        batch.deleteDocument(db.collection("users").document(userId))
        try await batch.commit()

        let conversationsSnapshot = try await db.collection("conversations")
            .whereField("participantIDs", arrayContains: userId)
            .getDocuments()
        for conversationDoc in conversationsSnapshot.documents {
            let messagesSnapshot = try await conversationDoc.reference
                .collection("messages").getDocuments()
            let messageBatch = db.batch()
            for messageDoc in messagesSnapshot.documents {
                messageBatch.deleteDocument(messageDoc.reference)
            }
            messageBatch.deleteDocument(conversationDoc.reference)
            try await messageBatch.commit()
        }
    }

    
    func uploadProfilePhoto(_ data: Data, userId: String) async throws -> String
    {
        let ref = Storage.storage().reference().child(
            "profile_photos/\(userId).jpg"
        )
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}
