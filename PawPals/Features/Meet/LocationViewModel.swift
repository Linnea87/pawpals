import CoreLocation

@Observable
final class LocationViewModel {
    var locationStatus: CLAuthorizationStatus = .notDetermined
    var currentUserLocation: CLLocationCoordinate2D?
    var isLocating = false

    private let locationRepository: LocationRepository

        init(locationRepository: LocationRepository = LocationService()) {
            self.locationRepository = locationRepository
        }

    func startLocating() async throws -> CLLocationCoordinate2D {
        isLocating = true
        defer { isLocating = false }

        do {

            /// Request a single real GPS location using the modern iOS 17 AsyncSequence API
            let location = try await locationRepository.requestLocationOnce()

            currentUserLocation = location.coordinate
            locationStatus = .authorizedWhenInUse
            return location.coordinate
        } catch LocationError.permissionDenied {
            /// User denied location access — update status so the View can show the correct UI
            locationStatus = .denied
        }
        throw LocationError.permissionDenied
    }

}
