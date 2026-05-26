import Foundation

enum AuthOption {
    case signIn, signUp
}

enum AuthError: Error {
    case notImplemented
    case invalidCredential
    case unknown
}
