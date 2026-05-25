import Foundation

enum AuthError: LocalizedError {
    case notImplemented
    case invalidCredential
    case unknown

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return String(localized: "error.auth.not_implemented")
        case .invalidCredential:
            return String(localized: "error.auth.invalid_credential")
        case .unknown:
            return String(localized: "error.auth.unknown")
        }
    }
}
