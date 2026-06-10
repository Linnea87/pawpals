import CoreLocation

protocol LocationRepository {
    func requestLocationOnce() async throws -> CLLocation
}
