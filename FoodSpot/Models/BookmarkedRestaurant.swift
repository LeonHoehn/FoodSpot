import CoreLocation
import Foundation

struct BookmarkedRestaurant: Codable, Identifiable {
    let id: UUID
    let restaurantId: UUID
    let createdAt: Date
    let restaurant: RestaurantEmbed

    struct RestaurantEmbed: Codable {
        let name: String
        let address: String?
        let lat: Double
        let lng: Double
    }

    enum CodingKeys: String, CodingKey {
        case id
        case restaurantId = "restaurant_id"
        case createdAt = "created_at"
        case restaurant = "restaurants"
    }
}

extension BookmarkedRestaurant {
    var summary: RestaurantSummary {
        RestaurantSummary(
            id: restaurantId,
            name: restaurant.name,
            address: restaurant.address,
            coordinate: CLLocationCoordinate2D(latitude: restaurant.lat, longitude: restaurant.lng)
        )
    }
}
