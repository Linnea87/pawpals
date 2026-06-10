import Foundation
import FirebaseFirestore

protocol MeetRepository {
    
    /// Fetches users within a given radius from a location, excluding the current user.
    func fetchNearbyUsers(location: GeoPoint, radius: Double, excludingUserID: String) async throws -> [User]
    
    /// Updates the user's stored GPS location in Firestore.
    func updateLocation(_ location: GeoPoint, userID: String) async throws
    
    /// Saves another user's profile to the current user's saved list.
    func saveProfile(_ targetID: String, by userID: String) async throws
    
    /// Removes a user from the current user's saved list.
    func unsaveProfile(_ targetID: String, by userID: String) async throws
    
    /// Fetches all profiles saved by a user.
    func fetchSavedProfiles(for userID: String) async throws -> [User]

    /// Fetches the IDs of all profiles saved by a user.
    func fetchSavedProfileIDs(for userID: String) async throws -> Set<String>
}


