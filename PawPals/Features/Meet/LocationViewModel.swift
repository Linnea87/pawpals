import CoreLocation
import MapKit

@Observable
final class LocationViewModel {
    var locationStatus: CLAuthorizationStatus = .notDetermined
    var currentUserLocation: CLLocationCoordinate2D?
    var isLocating = false
    var resolvedCity: String?

    private let locationRepository: LocationRepository
    private let profileRepository: ProfileRepository

    init(
        locationRepository: LocationRepository = LocationService(),
        profileRepository: ProfileRepository = ProfileService()
    ) {
        self.locationRepository = locationRepository
        self.profileRepository = profileRepository
    }

    func startLocating(userID: String? = nil) async throws
        -> CLLocationCoordinate2D
    {
        isLocating = true
        defer { isLocating = false }

        do {

            /// Request a single real GPS location using the modern iOS 17 AsyncSequence API
            let location = try await locationRepository.requestLocationOnce()

            currentUserLocation = location.coordinate
            locationStatus = .authorizedWhenInUse

            if let userID {
                Task {
                    await resolveAndSaveCity(from: location, userID: userID)
                }
            }
            return location.coordinate
        } catch LocationError.permissionDenied {
            /// User denied location access — update status so the View can show the correct UI
            locationStatus = .denied
        }
        throw LocationError.permissionDenied
    }
    
    private func resolveAndSaveCity(from location: CLLocation, userID: String) async {
        do {
            let city: String?

            if #available(iOS 26, *) {
                guard let request = MKReverseGeocodingRequest(location: location) else { return }
                let mapItems = try await request.mapItems
                city = mapItems.first?.addressRepresentations?.cityName
            } else {
                let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
                city = placemarks.first?.locality
            }

            guard let city else { return }
            try await profileRepository.updateCity(city, userID: userID)
            resolvedCity = city
        } catch {

        }
    }

}
