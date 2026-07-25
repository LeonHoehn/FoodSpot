import Foundation

struct Dish: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let restaurantId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case restaurantId = "restaurant_id"
    }
}
