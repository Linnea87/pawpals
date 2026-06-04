import FirebaseFirestore
import FirebaseStorage
import Foundation
import CoreLocation

enum UserServiceError: Error {
    case notFound
}

final class UserService: UserRepository {
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

    func fetchNearbyUsers(location: GeoPoint, radius: Double) async throws -> [User] {
        let snapshot = try await db.collection("users").getDocuments()
        
        let allUsers = snapshot.documents.compactMap { try? $0.data(as: User.self) }
        
        let currentLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        return allUsers.compactMap { user in
            guard let lat = user.latitude, let long = user.longitude else { return nil }
            let userLocation = CLLocation(latitude: lat, longitude: long)
            let distanceKm = currentLocation.distance(from: userLocation) / 1000
            let rounded = (distanceKm * 10).rounded() / 10
            guard rounded <= radius else { return nil }
            var updatedUser = user
            updatedUser.distance = rounded
            return updatedUser
        }
    }

    func fetchUser(userId: String) async throws -> User {
        let doc = try await db.collection("users").document(userId)
            .getDocument()
        guard let data = doc.data() else { throw UserServiceError.notFound }

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

    func updateLocation(_ location: GeoPoint, userId: String) async throws {

        try await db.collection("users")
            .document(userId)
            .setData(
                [
                    "latitude": location.latitude,
                    "longitude": location.longitude,
                ],
                merge: true
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

    func saveProfile(_ targetId: String, by userId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("savedProfiles")
            .document(targetId)
            .setData(["savedAt": Date()])
    }

    func unsaveProfile(_ targetId: String, by userId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("savedProfiles")
            .document(targetId)
            .delete()
    }

    func fetchSavedProfiles(for userId: String) async throws -> [User] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("savedProfiles")
            .getDocuments()

        let savedIds = snapshot.documents.map { $0.documentID }

        var users: [User] = []
        for id in savedIds {
            let doc = try await db.collection("users").document(id)
                .getDocument()
            if let user = try? doc.data(as: User.self) {
                users.append(user)
            }
        }
        return users
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
