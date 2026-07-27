import CoreLocation
import MapKit

extension MKPointOfInterestCategory {
    /// Kategorien, unter denen Apple Maps Orte listet, die Essen/Trinken
    /// servieren könnten. Apple kategorisiert z. B. Kneipen/Bars oft als
    /// "Nightlife" statt "Restaurant" - laut CLAUDE.md soll es aber egal
    /// sein, ob ein Gericht "bei einem Italiener oder zufällig bei einer
    /// Dönerbude" serviert wird, daher bewusst breiter als nur .restaurant.
    static let foodAndDrink: [MKPointOfInterestCategory] = [
        .restaurant, .bakery, .cafe, .brewery, .foodMarket, .nightlife, .winery, .distillery,
    ]
}

/// Wrapper um MKLocalSearch, eingeschränkt auf Essen/Trinken-POI-Kategorien
/// — die einzige Quelle für Restaurantdaten in FoodSpot.
struct RestaurantSearchService {
    func search(query: String, near coordinate: CLLocationCoordinate2D) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: MKPointOfInterestCategory.foodAndDrink)
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
