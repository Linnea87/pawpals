import CoreLocation
import Observation

@Observable
final class LocationService: LocationRepository {

    var currentLocation: CLLocation?
        var authorizationStatus: CLAuthorizationStatus = .notDetermined

        private let locationManager = CLLocationManager()

        func requestLocationOnce() async throws -> CLLocation {
            for try await update in CLLocationUpdate.liveUpdates() {
                authorizationStatus = locationManager.authorizationStatus

                if authorizationStatus == .denied || authorizationStatus == .restricted {
                    throw LocationError.permissionDenied
                }

                if let location = update.location {
                    currentLocation = location
                    return location
                }
            }
            throw LocationError.unavailable
        }
    }

enum LocationError: LocalizedError {
    case permissionDenied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location access is denied. Please enable it in Settings."
        case .unavailable:
            return "Could not determine your location. Try again."
        }
    }
}

