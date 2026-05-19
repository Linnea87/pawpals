import Foundation

@Observable
final class ProfileViewModel {

    private let userRepository: UserRepository
    var user: User

    init(userRepository: UserRepository, user: User) {
        self.userRepository = userRepository
        self.user = user
    }

    func saveOwnerInfo(name: String, photoURL: String?) async {
        user.displayName = name
        user.photoURL = photoURL
        do {
            try await userRepository.updateProfile(user)
        } catch {
            print("Failed to save owner info: \(error)")
        }
    }
}
