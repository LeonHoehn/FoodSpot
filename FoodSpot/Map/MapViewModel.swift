import CoreLocation
import Foundation

@MainActor
final class MapViewModel: ObservableObject {
    @Published private(set) var restaurants: [Restaurant] = []
    @Published private(set) var searchResults: [DishSearchResult] = []
    @Published var searchText = ""
    @Published var radiusKm: Double = 5
    @Published private(set) var isLoading = false
    @Published private(set) var isSearching = false
    @Published var errorMessage: String?
    @Published var selectedPinID: MapPin.ID?

    private let restaurantRepository = RestaurantRepository()
    private let dishSearchRepository = DishSearchRepository()
    private var searchTask: Task<Void, Never>?

    var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayedPins: [MapPin] {
        isSearchActive ? searchResults.map(\.asMapPin) : restaurants.map(\.asMapPin)
    }

    var showsNoResultsHint: Bool {
        isSearchActive && !isSearching && searchResults.isEmpty
    }

    func restaurantSummary(for pinID: MapPin.ID) -> RestaurantSummary? {
        if isSearchActive {
            return searchResults.first { $0.restaurantId == pinID }?.summary
        } else {
            return restaurants.first { $0.id == pinID }?.summary
        }
    }

    func loadRestaurants() async {
        isLoading = true
        defer { isLoading = false }

        do {
            restaurants = try await restaurantRepository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scheduleSearch(near coordinate: CLLocationCoordinate2D?) {
        searchTask?.cancel()

        guard isSearchActive else {
            searchResults = []
            errorMessage = nil
            return
        }

        guard let coordinate else {
            errorMessage = "Standort wird noch ermittelt…"
            return
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let radius = radiusKm

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }

            isSearching = true
            errorMessage = nil
            defer { isSearching = false }

            do {
                let results = try await dishSearchRepository.search(
                    query: query,
                    lat: coordinate.latitude,
                    lng: coordinate.longitude,
                    radiusKm: radius
                )
                guard !Task.isCancelled else { return }
                searchResults = results
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
