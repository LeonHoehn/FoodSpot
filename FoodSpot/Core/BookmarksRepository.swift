import Foundation
import Supabase

struct BookmarksRepository {
    private struct NewBookmark: Encodable {
        let user_id: UUID
        let restaurant_id: UUID
    }

    private struct BookmarkIdRow: Codable {
        let id: UUID
    }

    private let client = SupabaseManager.shared.client

    func fetchAll() async throws -> [BookmarkedRestaurant] {
        let userId = try await client.auth.session.user.id
        return try await client
            .from("bookmarks")
            .select("id, restaurant_id, created_at, restaurants(name, address, lat, lng)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func isBookmarked(restaurantId: UUID) async throws -> Bool {
        let userId = try await client.auth.session.user.id
        let rows: [BookmarkIdRow] = try await client
            .from("bookmarks")
            .select("id")
            .eq("user_id", value: userId)
            .eq("restaurant_id", value: restaurantId)
            .limit(1)
            .execute()
            .value
        return !rows.isEmpty
    }

    func add(restaurantId: UUID) async throws {
        let userId = try await client.auth.session.user.id
        try await client
            .from("bookmarks")
            .insert(NewBookmark(user_id: userId, restaurant_id: restaurantId))
            .execute()
    }

    func remove(restaurantId: UUID) async throws {
        let userId = try await client.auth.session.user.id
        try await client
            .from("bookmarks")
            .delete()
            .eq("user_id", value: userId)
            .eq("restaurant_id", value: restaurantId)
            .execute()
    }
}
