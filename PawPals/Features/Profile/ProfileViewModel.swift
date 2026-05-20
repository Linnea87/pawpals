import Foundation

@Observable
final class ProfileViewModel {

    private let userRepository: UserRepository
    var user: User
    var isLoading = false
    var errorMessage: String?

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
            user.dog = dog
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
