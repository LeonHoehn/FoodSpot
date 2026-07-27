import CoreLocation
import Foundation

struct Restaurant: Codable, Identifiable, Hashable {
    let id: UUID
    let appleMapsId: String?
    let name: String
    let lat: Double
    let lng: Double
    let address: String?

    enum CodingKeys: String, CodingKey {
        case id
        case appleMapsId = "apple_maps_id"
        case name
        case lat
        case lng
        case address
    }
}

extension Restaurant {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var asMapPin: MapPin {
        MapPin(id: id, name: name, coordinate: coordinate, kind: .rated)
    }

    var summary: RestaurantSummary {
        RestaurantSummary(id: id, name: name, address: address, coordinate: coordinate)
    }
}
