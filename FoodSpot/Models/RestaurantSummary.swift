import CoreLocation
import Foundation

/// Leichtgewichtige Restaurant-Repräsentation für UI-Flows (Detail-Sheet,
/// Bewertungsformular), unabhängig davon ob sie aus der vollen Restaurant-
/// liste oder aus einem Such-Treffer stammt.
struct RestaurantSummary: Identifiable {
    let id: UUID
    let name: String
    let address: String?
    let coordinate: CLLocationCoordinate2D
}
