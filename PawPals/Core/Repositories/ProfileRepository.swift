import Foundation
import FirebaseFirestore

protocol ProfileRepository {
    
     /// Updates the user's profile fields in Firestore.
     func updateProfile(_ user: User) async throws

     /// Saves a dog to the user's dogs subcollection in Firestore.
     func saveDog(_ dog: Dog, userID: String) async throws

     /// Removes a dog from the user's dogs subcollection in Firestore.
     func removeDog(dogId: String, userId: String) async throws

     /// Saves the user's walk preferences to Firestore.
     func savePreferences(_ prefs: UserPreferences, userID: String) async throws

     /// Loads the user's walk preferences from Firestore.
     func loadPreferences(userID: String) async throws -> UserPreferences

     /// Saves the device's push notification token to Firestore.
     func savePushNotificationToken(_ token: String, userID: String) async throws

     /// Deletes all Firestore data associated with a user account.
     func deleteUserData(userId: String) async throws

     /// Uploads a profile photo to Firebase Storage and returns the download URL.
     func uploadProfilePhoto(_ data: Data, userID: String) async throws -> String

     /// Fetches a single user's data from Firestore by ID.
     func fetchUser(userID: String) async throws -> User
}
