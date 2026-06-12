import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit


final class AuthService: AuthRepository {
    func signUp(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return User(
                id: result.user.uid,
                name: result.user.displayName ?? "",
                photoURL: result.user.photoURL?.absoluteString,
                bio: "",
                city: "",
                dogs: [],
                preferences: UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10)
            )
        } catch let error as NSError {
            switch error.code {
            case AuthErrorCode.emailAlreadyInUse.rawValue,
                 AuthErrorCode.invalidEmail.rawValue,
                 AuthErrorCode.wrongPassword.rawValue:
                throw AuthError.invalidCredential
            default:
                throw AuthError.unknown
            }
        }
    }

    @MainActor
        func signUpWithGoogle() async throws -> User {
            guard
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            else {
                throw AuthError.unknown
            }

            do {
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
                guard let idToken = result.user.idToken?.tokenString else {
                    throw AuthError.invalidCredential
                }
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )
                let authResult = try await Auth.auth().signIn(with: credential)
                return User(
                    id: authResult.user.uid,
                    name: authResult.user.displayName ?? "",
                    photoURL: authResult.user.photoURL?.absoluteString,
                    bio: "",
                    city: "",
                    dogs: [],
                    preferences: UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10)
                )
            } catch {
                throw AuthError.unknown
            }
        }

    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AuthError.unknown
        }
    }

    func signIn(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return User(
                id: result.user.uid,
                name: result.user.displayName ?? "",
                photoURL: result.user.photoURL?.absoluteString,
                bio: "",
                city: "",
                dogs: [],
                preferences: UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10)
            )
        } catch let error as NSError {
            switch error.code {
            case AuthErrorCode.invalidEmail.rawValue,
                 AuthErrorCode.wrongPassword.rawValue,
                 AuthErrorCode.userNotFound.rawValue:
                throw AuthError.invalidCredential
            default:
                throw AuthError.unknown
            }
        }
    }

    @MainActor
    func signInWithGoogle() async throws -> User {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            throw AuthError.unknown
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.invalidCredential
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            return User(
                id: authResult.user.uid,
                name: authResult.user.displayName ?? "",
                photoURL: authResult.user.photoURL?.absoluteString,
                bio: "",
                city: "",
                dogs: [],
                preferences: UserPreferences(walkTypes: [], dogSize: .medium, searchRadius: 10)
            )
        } catch {
            throw AuthError.unknown
        }
    }
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { throw AuthError.unknown }
        do {
            try await user.delete()
        } catch {
            throw AuthError.unknown
        }
    }
}
