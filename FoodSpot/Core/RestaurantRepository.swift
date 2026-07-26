import Foundation
import MapKit
import Supabase

enum RestaurantRepositoryError: Error, LocalizedError {
    case creationFailed

    var errorDescription: String? {
        switch self {
        case .creationFailed:
            return "Restaurant konnte nicht angelegt werden."
        }
    }
}

struct RestaurantRepository {
    private struct NewRestaurant: Encodable {
        let apple_maps_id: String
        let name: String
        let lat: Double
        let lng: Double
        let address: String?
    }

    private let client = SupabaseManager.shared.client

    func fetchAll() async throws -> [Restaurant] {
        try await client
            .from("restaurants")
            .select("id, apple_maps_id, name, lat, lng, address")
            .execute()
            .value
    }

    /// Legt beim ersten Treffer eines MapKit-POIs einen lokalen Referenz-
    /// Eintrag an (nur ID + Name + Location) oder liefert den bestehenden.
    func findOrCreate(mapItem: MKMapItem) async throws -> Restaurant {
        let appleMapsId = Self.appleMapsId(for: mapItem)

        if let existing = try await find(appleMapsId: appleMapsId) {
            return existing
        }

        let payload = NewRestaurant(
            apple_maps_id: appleMapsId,
            name: mapItem.name ?? "Unbekanntes Restaurant",
            lat: mapItem.placemark.coordinate.latitude,
            lng: mapItem.placemark.coordinate.longitude,
            address: mapItem.placemark.title
        )

        do {
            let inserted: [Restaurant] = try await client
                .from("restaurants")
                .insert(payload)
                .select("id, apple_maps_id, name, lat, lng, address")
                .execute()
                .value
            if let restaurant = inserted.first {
                return restaurant
            }
        } catch {
            // Race: ein anderer Client hat den gleichen POI zwischenzeitlich angelegt.
        }

        guard let restaurant = try await find(appleMapsId: appleMapsId) else {
            throw RestaurantRepositoryError.creationFailed
        }
        return restaurant
    }

    private func find(appleMapsId: String) async throws -> Restaurant? {
        let rows: [Restaurant] = try await client
            .from("restaurants")
            .select("id, apple_maps_id, name, lat, lng, address")
            .eq("apple_maps_id", value: appleMapsId)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// MKMapItem liefert keine stabile persistente ID, daher wird sie aus
    /// Name + gerundeter Koordinate abgeleitet (ausreichend stabil für
    /// denselben realen POI über mehrere Suchen hinweg).
    private static func appleMapsId(for mapItem: MKMapItem) -> String {
        let coordinate = mapItem.placemark.coordinate
        let lat = (coordinate.latitude * 100_000).rounded() / 100_000
        let lng = (coordinate.longitude * 100_000).rounded() / 100_000
        let name = mapItem.name ?? "unknown"
        return "\(name)|\(lat)|\(lng)"
    }
}
