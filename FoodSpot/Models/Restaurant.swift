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
