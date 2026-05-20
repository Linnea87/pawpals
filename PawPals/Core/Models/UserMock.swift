import Foundation

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
                size: .large,
                photoURL: nil
            )
        ],
        preferences: UserPreferences(
            walkTypes: [.evening, .forest],
            dogSize: .large,
            searchRadius: 10.0
        ),
        distance: 1.2
    )
}
