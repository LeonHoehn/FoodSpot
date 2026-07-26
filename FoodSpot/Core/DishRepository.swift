import Foundation
import Supabase

enum DishRepositoryError: Error, LocalizedError {
    case creationFailed

    var errorDescription: String? {
        switch self {
        case .creationFailed:
            return "Gericht konnte nicht angelegt werden."
        }
    }
}

struct DishRepository {
    private struct NewDish: Encodable {
        let name: String
        let restaurant_id: UUID
    }

    private let client = SupabaseManager.shared.client

    /// Gerichte entstehen ausschließlich durch Nutzerbewertungen: existiert
    /// noch kein Dish-Tag mit diesem Namen für das Restaurant, wird er neu
    /// angelegt (Freitext-Fallback für alles, was nicht im DishCatalog steht).
    func findOrCreate(name: String, restaurantId: UUID) async throws -> Dish {
        if let existing = try await find(name: name, restaurantId: restaurantId) {
            return existing
        }

        do {
            let inserted: [Dish] = try await client
                .from("dishes")
                .insert(NewDish(name: name, restaurant_id: restaurantId))
                .select()
                .execute()
                .value
            if let dish = inserted.first {
                return dish
            }
        } catch {
            // Race: ein anderer Client hat das gleiche Gericht zwischenzeitlich angelegt.
        }

        guard let dish = try await find(name: name, restaurantId: restaurantId) else {
            throw DishRepositoryError.creationFailed
        }
        return dish
    }

    private func find(name: String, restaurantId: UUID) async throws -> Dish? {
        let rows: [Dish] = try await client
            .from("dishes")
            .select()
            .eq("restaurant_id", value: restaurantId)
            .eq("name", value: name)
            .limit(1)
            .execute()
            .value
        return rows.first
    }
}
