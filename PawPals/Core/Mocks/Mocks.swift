import Foundation

/// Available in all builds — referenced as a nil-fallback in production views.
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

// =========== Preview-only mocks ==================================
 

#if DEBUG
import UIKit
import FirebaseFirestore

// =========== Mock Users ==================================
 

extension User {
    /// Five nearby Stockholm users used by FilterSheetView and MeetView previews.
    static let mockUsers: [User] = [
        .mock,
        User(
            id: "preview-2",
            name: "Erik",
            photoURL: nil,
            bio: "",
            city: "Stockholm",
            dogs: [],
            preferences: UserPreferences(walkTypes: [.evening], dogSize: .medium, searchRadius: 10.0),
            distance: 5.0,
            latitude: 59.3300,
            longitude: 18.1400
        ),
        User(
            id: "preview-3",
            name: "Lisa",
            photoURL: nil,
            bio: "",
            city: "Stockholm",
            dogs: [],
            preferences: UserPreferences(walkTypes: [.forest], dogSize: .small, searchRadius: 10.0),
            distance: 10.0,
            latitude: 59.2500,
            longitude: 17.9800
        ),
        User(
            id: "preview-4",
            name: "Johan",
            photoURL: nil,
            bio: "",
            city: "Solna",
            dogs: [],
            preferences: UserPreferences(walkTypes: [.morning], dogSize: .large, searchRadius: 20.0),
            distance: 18.0,
            latitude: 59.4200,
            longitude: 17.9000
        ),
        User(
            id: "preview-5",
            name: "Anna",
            photoURL: nil,
            bio: "",
            city: "Huddinge",
            dogs: [],
            preferences: UserPreferences(walkTypes: [.evening], dogSize: .medium, searchRadius: 30.0),
            distance: 30.0,
            latitude: 59.1200,
            longitude: 17.9800
        )
    ]
}

// =========== MockAuthRepository =============================

struct MockAuthRepository: AuthRepository {
    private var previewUser: User {
        User(
            id: "preview",
            name: "",
            photoURL: nil,
            bio: "",
            city: "",
            dogs: [],
            preferences: UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10),
            distance: nil
        )
    }

    func signUp(email: String, password: String) async throws -> User { previewUser }
    func signUpWithGoogle() async throws -> User { previewUser }
    func signIn(email: String, password: String) async throws -> User { previewUser }
    func signInWithGoogle() async throws -> User { previewUser }
    func signOut() throws {}
    func deleteAccount() async throws {}
}

// =========== MockUserRepository =============================

struct MockUserRepository: UserRepository {
    func updateProfile(_ user: User) async throws {}
    func saveDog(_ dog: Dog, userId: String) async throws {}
    func removeDog(dogId: String, userId: String) async throws {}
    func fetchNearbyUsers(location: GeoPoint, radius: Double, excludingUserID: String) async throws -> [User] { [] }
    func updateLocation(_ location: GeoPoint, userId: String) async throws {}
    func savePreferences(_ prefs: UserPreferences, userId: String) async throws {}
    func loadPreferences(userId: String) async throws -> UserPreferences {
        UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10.0)
    }
    func savePushNotificationToken(_ token: String, userID: String) async throws {}
    func deleteUserData(userId: String) async throws {}
    func saveProfile(_ targetId: String, by userId: String) async throws {}
    func unsaveProfile(_ targetId: String, by userId: String) async throws {}
    func fetchSavedProfiles(for userId: String) async throws -> [User] { [] }
    func uploadProfilePhoto(_ data: Data, userId: String) async throws -> String { "" }
    func fetchUser(userId: String) async throws -> User { .mock }
}


// =========== MockChatRepository =============================

struct MockChatRepository: ChatRepository {
    func observeConversations(
        for userID: String,
        onUpdate: @escaping ([Conversation]) -> Void
    ) -> (() -> Void) { return {} }

    func createOrFetchConversation(between userId1: String, and userId2: String) async throws -> Conversation {
        Conversation(
            id: "mock-conv",
            participantIDs: [userId1, userId2],
            lastMessage: "",
            lastMessageTimestamp: Date()
        )
    }
    
    func fetchConversationIfExists(between userID1: String, and userID2: String) async throws -> Conversation? {
        return nil
    }
}

// =========== MockConversationRepository =============================

struct MockConversationRepository: ConversationRepository {
    func observeMessages(
        conversationID: String,
        onUpdate: @escaping ([Message]) -> Void
    ) -> (() -> Void) {
        onUpdate([
            Message(
                id: "1",
                senderID: "user2",
                receiverID: "user1",
                text: "Hey! Bella would love to meet May 🐾",
                timestamp: Date().addingTimeInterval(-300)
            ),
            Message(
                id: "2",
                senderID: "user1",
                receiverID: "user2",
                text: "Oh that sounds perfect! When are you free?",
                timestamp: Date().addingTimeInterval(-240),
                isRead: true,
                isDelivered: true
            ),
            Message(
                id: "3",
                senderID: "user2",
                receiverID: "user1",
                text: "How about Saturday morning at Humlegården?",
                timestamp: Date().addingTimeInterval(-180)
            ),
            Message(
                id: "4",
                senderID: "user1",
                receiverID: "user2",
                text: "Yes! 10am works great for us 🐕",
                timestamp: Date().addingTimeInterval(-120),
                isRead: true,
                isDelivered: true
            ),
            Message(
                id: "5",
                senderID: "user2",
                receiverID: "user1",
                text: "Can't wait! See you there 🌿",
                timestamp: Date().addingTimeInterval(-60)
            )
        ])
        return {}
    }

    func sendMessage(_ message: Message, to conversationID: String) async throws {}
    func markAsRead(conversationID: String, userID: String) async throws {}
    func markAsDelivered(conversationID: String, userID: String) async throws {}
    func uploadImage(_ image: UIImage, conversationId: String) async throws -> URL {
        URL(string: "https://mock-image-url.com/image.jpg")!
    }
}
#endif
