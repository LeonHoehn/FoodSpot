import CoreLocation
import Foundation

@MainActor
final class MapViewModel: ObservableObject {
    @Published private(set) var restaurants: [Restaurant] = []
    @Published private(set) var searchResults: [DishSearchResult] = []
    @Published var searchText = ""
    @Published var searchScope: SearchScope = .nearby
    @Published var radiusKm: Double = 5
    @Published var isSearchSheetPresented = false
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
        isSearchSheetPresented ? searchResults.map(\.asMapPin) : restaurants.map(\.asMapPin)
    }

    var showsEmptyMapHint: Bool {
        !isSearchSheetPresented && !isLoading && restaurants.isEmpty
    }

    func restaurantSummary(for pinID: MapPin.ID) -> RestaurantSummary? {
        if isSearchSheetPresented {
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

    /// Ohne Sucheingabe wird trotzdem gesucht (leerer Query) - die RPCs
    /// liefern dann die bestbewerteten Gerichte ohne Namensfilter, damit
    /// man beim Öffnen des Sheets direkt etwas zum Stöbern sieht.
    func performSearch(near coordinate: CLLocationCoordinate2D?, isAuthorizationDenied: Bool = false) {
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch searchScope {
        case .global:
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }

                isSearching = true
                errorMessage = nil
                defer { isSearching = false }

                do {
                    let results = try await dishSearchRepository.searchGlobal(query: query)
                    guard !Task.isCancelled else { return }
                    searchResults = results
                } catch {
                    if !Task.isCancelled {
                        errorMessage = error.localizedDescription
                    }
                }
            }

        case .nearby:
            if isAuthorizationDenied {
                errorMessage = "Standortzugriff verweigert – aktiviere ihn in den Einstellungen, um nach Gerichten in deiner Nähe zu suchen."
                return
            }

            guard let coordinate else {
                errorMessage = "Standort wird noch ermittelt…"
                return
            }

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
}
