import Foundation

/// Ein bewertetes Gericht eines Restaurants mit seinem Gericht-Block-
/// Durchschnitt (Geschmack/Textur/Aussehen/Geruch), aus der
/// `restaurant_dish_ratings`-View.
struct DishRatingAverage: Codable, Identifiable {
    let restaurantId: UUID
    let dishId: UUID
    let dishName: String
    let avgTaste: Double
    let avgTexture: Double
    let avgAppearance: Double
    let avgSmell: Double
    let avgOverall: Double
    let ratingCount: Int

    var id: UUID { dishId }

    enum CodingKeys: String, CodingKey {
        case restaurantId = "restaurant_id"
        case dishId = "dish_id"
        case dishName = "dish_name"
        case avgTaste = "avg_taste"
        case avgTexture = "avg_texture"
        case avgAppearance = "avg_appearance"
        case avgSmell = "avg_smell"
        case avgOverall = "avg_overall"
        case ratingCount = "rating_count"
    }
}
