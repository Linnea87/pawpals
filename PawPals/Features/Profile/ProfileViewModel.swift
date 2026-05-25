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
