import CoreLocation
import MapKit

/// Wrapper um MKLocalSearch, eingeschränkt auf die POI-Kategorie
/// "Restaurant" — die einzige Quelle für Restaurantdaten in FoodSpot.
struct RestaurantSearchService {
    func search(query: String, near coordinate: CLLocationCoordinate2D) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant])
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 20_000,
            longitudinalMeters: 20_000
        )

        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems
    }
}
