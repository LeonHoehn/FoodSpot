import Foundation
import Supabase

enum RatingRepositoryError: Error, LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Du musst angemeldet sein, um zu bewerten."
        }
    }
}

struct RatingRepository {
    private struct Payload: Encodable {
        let user_id: UUID
        let dish_id: UUID
        let restaurant_id: UUID
        // Gericht-Block
        let taste: Double
        let texture: Double
        let appearance: Double
        let smell: Double
        // Restaurant-Block
        let service: Double
        let ambience: Double
        let value: Double
        let wait_time: Double
    }

    private let client = SupabaseManager.shared.client

    /// Ein Nutzer hat pro Gericht genau eine Bewertung (unique(user_id, dish_id));
    /// erneutes Bewerten überschreibt die bestehende Zeile statt eine neue anzulegen.
    func upsert(
        dishId: UUID,
        restaurantId: UUID,
        taste: Double,
        texture: Double,
        appearance: Double,
        smell: Double,
        service: Double,
        ambience: Double,
        value: Double,
        waitTime: Double
    ) async throws {
        let session = try await client.auth.session

        let payload = Payload(
            user_id: session.user.id,
            dish_id: dishId,
            restaurant_id: restaurantId,
            taste: taste,
            texture: texture,
            appearance: appearance,
            smell: smell,
            service: service,
            ambience: ambience,
            value: value,
            wait_time: waitTime
        )

        try await client
            .from("ratings")
            .upsert(payload, onConflict: "user_id,dish_id")
            .execute()
    }
}
