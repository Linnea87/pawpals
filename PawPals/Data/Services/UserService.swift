import CoreLocation
import FirebaseFirestore
import FirebaseStorage
import Foundation

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
    
    
    func fetchNearbyUsers(location: GeoPoint, radius: Double, excludingUserID: String) async throws
        -> [User]
    {
        let snapshot = try await db.collection("users").getDocuments()

        let currentLocation = CLLocation(
            latitude: location.latitude,
            longitude: location.longitude
        )

    
        return snapshot.documents.compactMap { doc in
            /// Read raw Firestore fields instead of using data(as: User.self).
            /// User has a dogs subcollection — Codable's data(as:) fails silently
            let data = doc.data()
            let userID = doc.documentID

            /// Never show the current user in the Meet list
            guard userID != excludingUserID else { return nil }

            /// Skip users who have never stored a location — they can't be ranked by distance
            guard let lat = data["latitude"] as? Double,
                  let long = data["longitude"] as? Double else { return nil }

            /// Calculate distance in km, rounded to 1 decimal place
            let userLocation = CLLocation(latitude: lat, longitude: long)
            let distanceKm = currentLocation.distance(from: userLocation) / 1000
            let rounded = (distanceKm * 10).rounded() / 10

            /// Drop users outside the selected search radius
            guard rounded <= radius else { return nil }

            /// Decode the nested preferences map — fall back to safe defaults if any field is missing
            let prefsData = data["preferences"] as? [String: Any]
            let walkTypes = (prefsData?["walkTypes"] as? [String] ?? []).compactMap(WalkType.init(rawValue:))
            let dogSize = DogSize(rawValue: prefsData?["dogSize"] as? String ?? "") ?? .medium
            let searchRadius = prefsData?["searchRadius"] as? Double ?? 10.0

            /// Build and return the User with distance already filled in.
            /// dogs is left empty here — subcollection data is fetched separately in fetchUser.
            return User(
                id: userID,
                name: data["name"] as? String ?? "",
                photoURL: data["photoURL"] as? String,
                bio: data["bio"] as? String ?? "",
                city: data["city"] as? String ?? "",
                dogs: [],
                preferences: UserPreferences(walkTypes: walkTypes, dogSize: dogSize, searchRadius: searchRadius),
                distance: rounded,
                latitude: lat,
                longitude: long
            )
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
        /// Store lat/long as top-level Double fields so they match the User model's - latitude and longitude properties when decoded by Firestore
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
            let doc = try await db.collection("users").document(id).getDocument()
            if let user = try? await fetchUser(userId: id) {
                users.append(user)
            }
        }
        return users
    }
    
    func fetchSavedProfileIds(for userId: String) async throws -> Set<String> {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("savedProfiles")
            .getDocuments()
        return Set(snapshot.documents.map { $0.documentID })
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
