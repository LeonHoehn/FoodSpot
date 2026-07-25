import Foundation

/// Bewertung eines Nutzers zu einem Gericht bei einem Restaurant.
/// Die beiden Blöcke (Gericht vs. Restaurant) werden in der UI nie
/// vermischt, obwohl sie hier aus Persistenzgründen in einer Zeile liegen.
struct Rating: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let dishId: UUID
    let restaurantId: UUID

    // Gericht-Block
    var taste: Double
    var texture: Double
    var appearance: Double
    var smell: Double

    // Restaurant-Block
    var service: Double
    var ambience: Double
    var value: Double
    var waitTime: Double

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dishId = "dish_id"
        case restaurantId = "restaurant_id"
        case taste, texture, appearance, smell
        case service, ambience, value
        case waitTime = "wait_time"
    }
}

extension Rating {
    var dishAverage: Double {
        (taste + texture + appearance + smell) / 4
    }

    var restaurantAverage: Double {
        (service + ambience + value + waitTime) / 4
    }
}
