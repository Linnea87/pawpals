import CoreLocation
import Observation

@Observable
final class LocationService {

    var currentLocation: CLLocation?
        var authorizationStatus: CLAuthorizationStatus = .notDetermined

        private let locationManager = CLLocationManager()           // ← only used to read authorizationStatus

        func requestLocationOnce() async throws -> CLLocation {
            for try await update in CLLocationUpdate.liveUpdates() { // ← iOS 17 — triggers permission prompt automatically
                authorizationStatus = locationManager.authorizationStatus  // ← read status after each update

                if authorizationStatus == .denied || authorizationStatus == .restricted {
                    throw LocationError.permissionDenied
                }

                if let location = update.location {
                    currentLocation = location
                    return location                                  // ← first fix — exit the stream
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

//@Observable
//final class LocationService: NSObject {
//
//    var authorizationStatus: CLAuthorizationStatus = .notDetermined
//
//    var currentLocation: CLLocation?
//
//    private let locationManager = CLLocationManager()
//
//    override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
//        authorizationStatus = locationManager.authorizationStatus
//    }
//
//    func requestPermission() {
//        locationManager.requestWhenInUseAuthorization()
//    }
//
//    func requestLocation() {
//        locationManager.requestLocation()
//    }
//}
//
//
//extension LocationService: CLLocationManagerDelegate {
//
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        authorizationStatus = manager.authorizationStatus
//    }
//
//    func locationManager(_ manager: CLLocationManager,
//                         didUpdateLocations locations: [CLLocation]) {
//        currentLocation = locations.last
//    }
//
//    func locationManager(_ manager: CLLocationManager,
//                         didFailWithError error: Error) {
//        print("LocationService error: \(error.localizedDescription)")
//    }
//}
