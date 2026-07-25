import Foundation
import Supabase

struct RestaurantRepository {
    private let client = SupabaseManager.shared.client

    func fetchAll() async throws -> [Restaurant] {
        try await client
            .from("restaurants")
            .select("id, apple_maps_id, name, lat, lng, address")
            .execute()
            .value
    }
}
