import FirebaseFirestore
import Foundation

enum FirestoreError: LocalizedError {
    case notFound
    case encodingFailed
    case decodingFailed
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notFound: return String(localized: "firestore.error.notFound")
        case .encodingFailed: return String(localized: "firestore.error.encodingFailed")
        case .decodingFailed: return String(localized: "firestore.error.decodingFailed")
        case .unknown(let error): return error.localizedDescription
        }
    }
}

final class FirestoreErrorHandler {
    static let shared = FirestoreErrorHandler()
    private let db = Firestore.firestore()

    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as FirestoreError {
            throw error
        } catch {
            throw FirestoreError.unknown(error)
        }
    }
}
