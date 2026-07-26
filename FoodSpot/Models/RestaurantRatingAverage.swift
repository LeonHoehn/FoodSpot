import Foundation

/// Aggregierter Restaurant-Block-Durchschnitt (Service/Ambiente/Preis-
/// Leistung/Wartezeit) aus der `restaurant_ratings_avg`-View.
struct RestaurantRatingAverage: Codable, Identifiable {
    let restaurantId: UUID
    let avgService: Double
    let avgAmbience: Double
    let avgValue: Double
    let avgWaitTime: Double
    let avgOverall: Double
    let ratingCount: Int

    var id: UUID { restaurantId }

    enum CodingKeys: String, CodingKey {
        case restaurantId = "restaurant_id"
        case avgService = "avg_service"
        case avgAmbience = "avg_ambience"
        case avgValue = "avg_value"
        case avgWaitTime = "avg_wait_time"
        case avgOverall = "avg_overall"
        case ratingCount = "rating_count"
    }
}
