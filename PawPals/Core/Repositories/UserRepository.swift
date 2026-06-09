import Foundation
import FirebaseFirestore

protocol UserRepository {
    
     /// Updates the user's profile fields in Firestore.
     func updateProfile(_ user: User) async throws

     /// Saves a dog to the user's dogs subcollection in Firestore.
     func saveDog(_ dog: Dog, userID: String) async throws

     /// Removes a dog from the user's dogs subcollection in Firestore.
     func removeDog(dogID: String, userID: String) async throws

     /// Fetches users within a given radius from a location, excluding the current user.
     func fetchNearbyUsers(location: GeoPoint, radius: Double, excludingUserID: String) async throws -> [User]

     /// Updates the user's stored GPS location in Firestore.
     func updateLocation(_ location: GeoPoint, userID: String) async throws

     /// Saves the user's walk preferences to Firestore.
     func savePreferences(_ prefs: UserPreferences, userID: String) async throws

     /// Loads the user's walk preferences from Firestore.
     func loadPreferences(userID: String) async throws -> UserPreferences

     /// Saves the device's push notification token to Firestore.
     func savePushNotificationToken(_ token: String, userID: String) async throws

     /// Deletes all Firestore data associated with a user account.
     func deleteUserData(userID: String) async throws

     /// Saves another user's profile to the current user's saved list.
     func saveProfile(_ targetID: String, by userID: String) async throws

     /// Removes a user from the current user's saved list.
     func unsaveProfile(_ targetID: String, by userID: String) async throws

     /// Fetches all profiles saved by a user.
     func fetchSavedProfiles(for userID: String) async throws -> [User]

     /// Uploads a profile photo to Firebase Storage and returns the download URL.
     func uploadProfilePhoto(_ data: Data, userID: String) async throws -> String

     /// Fetches a single user's data from Firestore by ID.
     func fetchUser(userID: String) async throws -> User
}
