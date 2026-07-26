import CoreLocation
import Foundation

/// Eigene Bewertung mit eingebetteten Gericht-/Restaurant-Infos (via
/// PostgREST-Embedding über die FK-Beziehungen), für die nach Gericht-Typ
/// gruppierte Ansicht im Profil.
struct MyRatingRow: Codable, Identifiable {
    let id: UUID
    let dishId: UUID
    let restaurantId: UUID

    // Gericht-Block
    let taste: Double
    let texture: Double
    let appearance: Double
    let smell: Double

    // Restaurant-Block
    let service: Double
    let ambience: Double
    let value: Double
    let waitTime: Double

    let dish: DishEmbed
    let restaurant: RestaurantEmbed

    struct DishEmbed: Codable {
        let name: String
    }

    struct RestaurantEmbed: Codable {
        let name: String
        let address: String?
        let lat: Double
        let lng: Double
    }

    enum CodingKeys: String, CodingKey {
        case id
        case dishId = "dish_id"
        case restaurantId = "restaurant_id"
        case taste, texture, appearance, smell
        case service, ambience, value
        case waitTime = "wait_time"
        case dish = "dishes"
        case restaurant = "restaurants"
    }
}

extension MyRatingRow {
    var dishAverage: Double {
        (taste + texture + appearance + smell) / 4
    }

    var restaurantAverage: Double {
        (service + ambience + value + waitTime) / 4
    }

    var summary: RestaurantSummary {
        RestaurantSummary(
            id: restaurantId,
            name: restaurant.name,
            address: restaurant.address,
            coordinate: CLLocationCoordinate2D(latitude: restaurant.lat, longitude: restaurant.lng)
        )
    }
}
