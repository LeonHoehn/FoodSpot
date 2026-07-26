import Foundation
import Supabase

struct RatingsSummaryRepository {
    private let client = SupabaseManager.shared.client

    func fetchRestaurantAverage(restaurantId: UUID) async throws -> RestaurantRatingAverage? {
        let rows: [RestaurantRatingAverage] = try await client
            .from("restaurant_ratings_avg")
            .select()
            .eq("restaurant_id", value: restaurantId)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    func fetchDishAverages(restaurantId: UUID) async throws -> [DishRatingAverage] {
        try await client
            .from("restaurant_dish_ratings")
            .select()
            .eq("restaurant_id", value: restaurantId)
            .order("avg_overall", ascending: false)
            .execute()
            .value
    }
}
