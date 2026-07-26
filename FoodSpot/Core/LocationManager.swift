import CoreLocation
import Foundation

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentLocation: CLLocationCoordinate2D?
    /// CLLocationCoordinate2D ist nicht Equatable, daher zählt dieser Wert
    /// Updates hoch, damit SwiftUI-`onChange` auf neue Standorte reagieren kann.
    @Published private(set) var locationUpdateCount = 0

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    func requestAuthorization() {
        guard authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else { return }
        manager.requestLocation()
    }

    var isAuthorizationDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in
            currentLocation = coordinate
            locationUpdateCount += 1
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Standort bleibt nil; UI fällt auf "Standort wird ermittelt" zurück.
    }
}
