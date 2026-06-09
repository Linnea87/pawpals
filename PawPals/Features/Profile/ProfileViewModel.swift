import Foundation
import UIKit

@MainActor
@Observable
final class ProfileViewModel {
    
    private let userRepository: UserRepository
    var user: User
    var isLoading = false
    var errorMessage: String?
    var savedUsers: [User] = []
    
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
    
    func saveProfileInfo(name: String, bio: String, city: String, walkTypes: [WalkType]) async {
        isLoading = true
        errorMessage = nil
        user.name = name
        user.bio = bio
        user.city = city
        user.preferences.walkTypes = walkTypes
        do {
            try await userRepository.updateProfile(user)
            try await userRepository.savePreferences(user.preferences, userID: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func saveDog(_ dog: Dog) async {
        isLoading = true
        errorMessage = nil
        do {
            try await userRepository.saveDog(dog, userID: user.id)
            user.dogs.append(dog)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func removeDog(_ dogID: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await userRepository.removeDog(dogID: dogID, userID: user.id)
            user.dogs.removeAll { $0.id == dogID }
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
        user.preferences.walkTypes = walkTypes
        do {
            try await userRepository.updateProfile(user)
            try await userRepository.saveDog(dog, userID: user.id)
            try await userRepository.savePreferences(user.preferences, userID: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func loadPreferences() async {
        isLoading = true
        errorMessage = nil
        do {
            user.preferences = try await userRepository.loadPreferences(userID: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func savePreferences() async {
        isLoading = true
        errorMessage = nil
        do {
            try await userRepository.savePreferences(user.preferences, userID: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func loadSavedProfiles() async {
        do {
            savedUsers = try await userRepository.fetchSavedProfiles(for: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func uploadProfilePhoto(_ data: Data) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            guard let uiImage = UIImage(data: data),
                  let jpegData = uiImage.jpegData(compressionQuality: 0.8) else { return }
            let url = try await userRepository.uploadProfilePhoto(jpegData, userID: user.id)
            user.photoURL = url
            try await userRepository.updateProfile(user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadUser(userID: String) async {
        isLoading = true
        errorMessage = nil
        do {
            user = try await userRepository.fetchUser(userID: userID)
            user.preferences = try await userRepository.loadPreferences(userID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

}
