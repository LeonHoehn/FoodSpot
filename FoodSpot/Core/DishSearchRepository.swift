import Foundation
import Supabase

struct DishSearchRepository {
    private struct Params: Encodable {
        let search_query: String
        let user_lat: Double
        let user_lng: Double
        let radius_km: Double
    }

    private let client = SupabaseManager.shared.client

    func search(query: String, lat: Double, lng: Double, radiusKm: Double) async throws -> [DishSearchResult] {
        try await client
            .rpc("search_dishes", params: Params(
                search_query: query,
                user_lat: lat,
                user_lng: lng,
                radius_km: radiusKm
            ))
            .execute()
            .value
    }
}
