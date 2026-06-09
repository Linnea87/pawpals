import Foundation
import FirebaseFirestore

protocol MeetRepository {
    
    /// Fetches users within a given radius from a location, excluding the current user.
    func fetchNearbyUsers(location: GeoPoint, radius: Double, excludingUserID: String) async throws -> [User]
    
    /// Updates the user's stored GPS location in Firestore.
    func updateLocation(_ location: GeoPoint, userId: String) async throws
    
    /// Saves another user's profile to the current user's saved list.
    func saveProfile(_ targetId: String, by userId: String) async throws
    
    /// Removes a user from the current user's saved list.
    func unsaveProfile(_ targetId: String, by userId: String) async throws
    
    /// Fetches all profiles saved by a user.
    func fetchSavedProfiles(for userId: String) async throws -> [User]
}


