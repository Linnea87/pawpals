import Foundation
import UIKit

@Observable
final class ProfileViewModel {
    
    private let profileRepository: ProfileRepository
    
    var user: User
    var isLoading = false
    var errorMessage: String?
    
    init(profileRepository: ProfileRepository, user: User) {
         self.profileRepository = profileRepository
         self.user = user
     }
    
    func saveOwnerInfo(name: String, photoURL: String?) async {
        isLoading = true
        errorMessage = nil
        user.name = name
        user.photoURL = photoURL
        do {
            try await profileRepository.updateProfile(user)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func saveProfileInfo(name: String, bio: String, walkTypes: [WalkType]) async {
        isLoading = true
        errorMessage = nil
        user.name = name
        user.bio = bio
        user.preferences.walkTypes = walkTypes
        do {
            try await profileRepository.updateProfile(user)
            try await profileRepository.savePreferences(user.preferences, userID: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func saveDog(_ dog: Dog) async {
        isLoading = true
        errorMessage = nil
        do {
            try await profileRepository.saveDog(dog, userID: user.id)
            if let index = user.dogs.firstIndex(where: { $0.id == dog.id }) {
                user.dogs[index] = dog
            } else {
                user.dogs.append(dog)
            }
            user.preferences.dogSize = dog.size
            try await profileRepository.savePreferences(user.preferences, userID: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func removeDog(_ dogID: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await profileRepository.removeDog(dogID: dogID, userID: user.id)
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
            try await profileRepository.updateProfile(user)
            try await profileRepository.saveDog(dog, userID: user.id)
            try await profileRepository.savePreferences(user.preferences, userID: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func loadPreferences() async {
        isLoading = true
        errorMessage = nil
        do {
            user.preferences = try await profileRepository.loadPreferences(userID: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func savePreferences() async {
        isLoading = true
        errorMessage = nil
        do {
            try await profileRepository.savePreferences(user.preferences, userID: user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func uploadProfilePhoto(_ data: Data) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let jpegData = await MainActor.run {
                UIImage(data: data)?.jpegData(compressionQuality: 0.8)
            }
            guard let jpegData else { return }
            let url = try await profileRepository.uploadProfilePhoto(jpegData, userID: user.id)
            user.photoURL = url
            try await profileRepository.updateProfile(user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadUser(userID: String) async {
        isLoading = true
        errorMessage = nil
        do {
            user = try await profileRepository.fetchUser(userID: userID)
            user.preferences = try await profileRepository.loadPreferences(userID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

}
