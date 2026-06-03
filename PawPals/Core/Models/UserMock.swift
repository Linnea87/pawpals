import Foundation
import FirebaseFirestore

extension User {
    static let mock = User(
        id: "preview-1",
        name: "Sara",
        photoURL: nil,
        bio: "Vi älskar långa promenader i skogen och att träffa nya hundar!",
        city: "Stockholm",
        dogs: [
            Dog(
                id: "dog-1",
                name: "Bella",
                breed: "Golden Retriever",
                age: 3,
                size: .large
            )
        ],
        preferences: UserPreferences(
            walkTypes: [.evening, .forest],
            dogSize: .large,
            searchRadius: 10.0
        ),
        distance: 1.2,
        latitude: 59.3293,
        longitude: 18.0686
    )
}

#if DEBUG
struct MockUserRepository: UserRepository {
    func updateProfile(_ user: User) async throws {}
    func saveDog(_ dog: Dog, userId: String) async throws {}
    func removeDog(dogId: String, userId: String) async throws {}
    func fetchNearbyUsers(location: GeoPoint, radius: Double) async throws -> [User] { [] }
    func updateLocation(_ location: GeoPoint, userId: String) async throws {}
    func savePreferences(_ prefs: UserPreferences, userId: String) async throws {}
    func loadPreferences(userId: String) async throws -> UserPreferences {
        UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10.0)
    }
    func savePushNotificationToken(_ token: String, userID: String) async throws {}
    func deleteUserData(userId: String) async throws {}
    func fetchUser(userId: String) async throws -> User { .mock }
}
#endif
