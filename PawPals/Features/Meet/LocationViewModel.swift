import CoreLocation

@Observable
final class LocationViewModel {
    var locationStatus: CLAuthorizationStatus = .notDetermined
    var currentUserLocation: CLLocationCoordinate2D?
    var isLocating = false

    private let locationService: LocationService

    init(locationService: LocationService = LocationService()) {
        self.locationService = locationService
    }

    func startLocating() async throws {
        isLocating = true
        defer { isLocating = false }

        do {

            /// Request a single real GPS location using the modern iOS 17 AsyncSequence API
            let location = try await locationService.requestLocationOnce()

            currentUserLocation = location.coordinate
            locationStatus = .authorizedWhenInUse

        } catch LocationError.permissionDenied {
            /// User denied location access — update status so the View can show the correct UI
            locationStatus = .denied
        }
        throw LocationError.permissionDenied
    }

}
