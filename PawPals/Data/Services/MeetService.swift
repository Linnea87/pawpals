import CoreLocation
import FirebaseFirestore
import Foundation

final class MeetService: MeetRepository {
    private let db = Firestore.firestore()
    private let profileRepository: ProfileRepository
    
    init(profileRepository: ProfileRepository = ProfileService()) {
             self.profileRepository = profileRepository
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

             var users: [User] = []
             for doc in snapshot.documents {
                 if let user = try? await profileRepository.fetchUser(userId: doc.documentID) {
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
}
