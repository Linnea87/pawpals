import Foundation

@Observable
final class ProfileViewModel {

    private let userRepository: UserRepository
    var user: User
    var isLoading = false
    var errorMessage: String?
    var preferences: UserPreferences = UserPreferences(
        walkTypes: [],
        dogSize: .medium,
        searchRadius: 5.0
    )

    init(userRepository: UserRepository, user: User) {
        self.userRepository = userRepository
        self.user = user
    }

    func saveOwnerInfo(name: String, photoURL: String?) async {
        isLoading = true
        errorMessage = nil
        user.name = name
        user.photoURL = photoURL
        do {
            try await userRepository.updateProfile(user)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveDog(_ dog: Dog) async {
        isLoading = true
        errorMessage = nil
        do {
            try await userRepository.saveDog(dog, userId: user.id)
            user.dogs.append(dog)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveProfile(name: String, bio: String, city: String, dogName: String, dogBreed: String, dogSize: DogSize, walkTypes: [WalkType]) async {
        isLoading = true
        errorMessage = nil
        user.name = name
        user.bio = bio
        user.city = city
        let existing = user.dogs.first
        let dog = Dog(
            id: existing?.id ?? UUID().uuidString,
            name: dogName,
            breed: dogBreed,
            age: existing?.age ?? 0,
            size: dogSize
        )
        if let index = user.dogs.firstIndex(where: { $0.id == dog.id }) {
            user.dogs[index] = dog
        } else {
            user.dogs.append(dog)
        }
        preferences.walkTypes = walkTypes
        do {
            try await userRepository.updateProfile(user)
            try await userRepository.saveDog(dog, userId: user.id)
            try await userRepository.savePreferences(preferences, userId: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadPreferences() async {
        isLoading = true
        errorMessage = nil
        do {
            preferences = try await userRepository.loadPreferences(userId: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func savePreferences() async {
        isLoading = true
        errorMessage = nil
        do {
            try await userRepository.savePreferences(preferences, userId: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
