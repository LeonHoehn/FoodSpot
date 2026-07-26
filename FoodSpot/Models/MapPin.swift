import CoreLocation
import Foundation

struct MapPin: Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
}
