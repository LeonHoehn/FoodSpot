import Foundation
import Supabase

struct DishSearchRepository {
    private struct NearbyParams: Encodable {
        let search_query: String
        let user_lat: Double
        let user_lng: Double
        let radius_km: Double
    }

    private struct GlobalParams: Encodable {
        let search_query: String
    }

    private let client = SupabaseManager.shared.client

    func search(query: String, lat: Double, lng: Double, radiusKm: Double) async throws -> [DishSearchResult] {
        try await client
            .rpc("search_dishes", params: NearbyParams(
                search_query: query,
                user_lat: lat,
                user_lng: lng,
                radius_km: radiusKm
            ))
            .execute()
            .value
    }

    func searchGlobal(query: String) async throws -> [DishSearchResult] {
        try await client
            .rpc("search_dishes_global", params: GlobalParams(search_query: query))
            .execute()
            .value
    }
}
