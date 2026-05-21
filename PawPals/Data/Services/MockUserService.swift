import Foundation
import FirebaseFirestore

final class MockUserService: UserRepository {

    func fetchNearbyUsers() async throws -> [User] {
        try await Task.sleep(nanoseconds: 500_000_000)

        return [
            User(
                id: "mock-1",
                name: "Emma",
                photoURL: nil,
                bio: "We love morning walks in the park!",
                dog: Dog(
                    id: "dog-1",
                    name: "Max",
                    breed: "Golden Retriever",
                    age: 3,
                    size: .large
                ),
                city: "Stockholm",
                dogs: [],
                preferences: UserPreferences(
                    walkTypes: [.morning, .city],
                    dogSize: .large,
                    searchRadius: 5.0
                ),
                distance: 1.2
            ),
            User(
                id: "mock-2",
                name: "Maja",
                photoURL: nil,
                bio: "Looking for a walking buddy in the evenings",
                dog: Dog(
                    id: "dog-2",
                    name: "Charlie",
                    breed: "Labrador",
                    age: 2,
                    size: .medium
                ),
                city: "Stockholm",
                dogs: [],
                preferences: UserPreferences(
                    walkTypes: [.evening, .city],
                    dogSize: .medium,
                    searchRadius: 5.0
                ),
                distance: 2.4
            )
        ]
    }

    func updateProfile(_ user: User) async throws {
    }

    func saveDog(_ dog: Dog, userId: String) async throws {
    }

    func updateLocation(_ location: GeoPoint, userId: String) async throws {
        print("MockUserService: updateLocation \(location)")
    }
}
