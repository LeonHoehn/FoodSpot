import CoreLocation
import Foundation

/// Ergebniszeile der `search_dishes`-RPC: ein Restaurant mit seinem am besten
/// zur Suche passenden (und bewerteten) Gericht.
struct DishSearchResult: Codable, Identifiable, Hashable {
    let restaurantId: UUID
    let restaurantName: String
    let restaurantAddress: String?
    let restaurantLat: Double
    let restaurantLng: Double
    let dishId: UUID
    let dishName: String
    let avgTaste: Double
    let avgTexture: Double
    let avgAppearance: Double
    let avgSmell: Double
    let avgOverall: Double
    let ratingCount: Int
    let distanceMeters: Double

    var id: UUID { restaurantId }

    enum CodingKeys: String, CodingKey {
        case restaurantId = "restaurant_id"
        case restaurantName = "restaurant_name"
        case restaurantAddress = "restaurant_address"
        case restaurantLat = "restaurant_lat"
        case restaurantLng = "restaurant_lng"
        case dishId = "dish_id"
        case dishName = "dish_name"
        case avgTaste = "avg_taste"
        case avgTexture = "avg_texture"
        case avgAppearance = "avg_appearance"
        case avgSmell = "avg_smell"
        case avgOverall = "avg_overall"
        case ratingCount = "rating_count"
        case distanceMeters = "distance_meters"
    }
}

extension DishSearchResult {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: restaurantLat, longitude: restaurantLng)
    }

    var asMapPin: MapPin {
        MapPin(id: restaurantId, name: restaurantName, coordinate: coordinate)
    }

    var summary: RestaurantSummary {
        RestaurantSummary(id: restaurantId, name: restaurantName, address: restaurantAddress, coordinate: coordinate)
    }
}
