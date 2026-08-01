import CoreLocation
import Foundation
import MapKit
import SwiftUI

@MainActor
final class MapViewModel: ObservableObject {
    @Published private(set) var restaurants: [Restaurant] = []
    @Published private(set) var bookmarks: [BookmarkedRestaurant] = []
    @Published private(set) var searchResults: [DishSearchResult] = []
    /// Live-Treffer aus der "+"-Restaurantsuche, nur fürs Anzeigen als
    /// Pins auf der Karte (rein visuell, nicht Teil des Selection-States).
    @Published var restaurantSearchResults: [MKMapItem] = []
    @Published var searchText = ""
    @Published var searchScope: SearchScope = .nearby
    @Published var radiusKm: Double = 5
    @Published var isSearchSheetPresented = false
    @Published var isShowingAddRestaurant = false
    /// Einziger Ort, an dem "welches Restaurant ist gerade ausgewählt"
    /// gepflegt wird - egal ob per Karten-Tap, Suchergebnis-Tap oder
    /// "+"-Suche gesetzt, immer derselbe State -> immer dieselbe
    /// Pin-Hervorhebung und dieselbe Detailseite.
    @Published var selection: MapSelection<MapPin.ID>?
    @Published var selectedRestaurant: RestaurantSummary?
    /// Detent der RestaurantDetailSheet - wird von jedem Auswahl-Pfad (Karten-
    /// Tap, Such-Tap, "+"-Suche) auf `.medium` zurückgesetzt, damit die
    /// Kamera-Zentrierung zuverlässig weiß, ob die Karte gerade halb verdeckt
    /// ist.
    @Published var detailSheetDetent: PresentationDetent = .medium
    /// Restaurant, das gerade per "+"-Suche angelegt/ausgewählt wurde und
    /// deshalb (noch) nicht zwingend in `restaurants` auftaucht - wird
    /// trotzdem als Pin angezeigt, damit die Auswahl-Hervorhebung sichtbar
    /// "aufpoppt", genau wie bei einem normalen Karten-Tap.
    @Published var focusedRestaurant: RestaurantSummary?
    @Published private(set) var isLoading = false
    @Published private(set) var isSearching = false
    @Published private(set) var isResolvingMapFeature = false
    @Published var errorMessage: String?

    private let restaurantRepository = RestaurantRepository()
    private let bookmarksRepository = BookmarksRepository()
    private let dishSearchRepository = DishSearchRepository()
    private var searchTask: Task<Void, Never>?

    var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Öffentliche "hat Bewertungen"-Pins + private, nur für den eigenen
    /// Nutzer sichtbare Merkliste-Pins (dedupliziert, falls beides zutrifft).
    var displayedPins: [MapPin] {
        var pins: [MapPin]

        if isShowingAddRestaurant, !restaurantSearchResults.isEmpty {
            pins = restaurantSearchResults.map { item in
                MapPin(id: UUID(), name: item.name ?? "Unbekanntes Restaurant", coordinate: item.placemark.coordinate, kind: .searchResult)
            }
        } else if isSearchSheetPresented {
            pins = searchResults.map(\.asMapPin)
        } else {
            pins = restaurants.map(\.asMapPin)
            let ratedIds = Set(restaurants.map(\.id))
            for bookmark in bookmarks where !ratedIds.contains(bookmark.restaurantId) {
                pins.append(bookmark.asMapPin)
            }
        }

        if let focused = focusedRestaurant, !pins.contains(where: { $0.id == focused.id }) {
            pins.append(MapPin(id: focused.id, name: focused.name, coordinate: focused.coordinate, kind: .searchResult))
        }

        return pins
    }

    var showsEmptyMapHint: Bool {
        !isSearchSheetPresented && !isLoading && restaurants.isEmpty && bookmarks.isEmpty
    }

    func restaurantSummary(for pinID: MapPin.ID) -> RestaurantSummary? {
        if isSearchSheetPresented {
            return searchResults.first { $0.restaurantId == pinID }?.summary
        }
        if let restaurant = restaurants.first(where: { $0.id == pinID }) {
            return restaurant.summary
        }
        return bookmarks.first { $0.restaurantId == pinID }?.summary
    }

    func loadPins() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let ratedTask = restaurantRepository.fetchRated()
            async let bookmarksTask = bookmarksRepository.fetchAll()
            restaurants = try await ratedTask
            bookmarks = try await bookmarksTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Antippen eines von Apple selbst auf der Karte angezeigten
    /// Restaurant-POIs (nicht unserer eigenen Pins): legt beim ersten Mal
    /// einen lokalen Eintrag an, genau wie die "+"-Suche.
    func resolveRestaurant(from mapItem: MKMapItem) async -> RestaurantSummary? {
        isResolvingMapFeature = true
        errorMessage = nil
        defer { isResolvingMapFeature = false }

        do {
            let restaurant = try await restaurantRepository.findOrCreate(mapItem: mapItem)
            return restaurant.summary
        } catch {
            errorMessage = error.localizedDescription
            return nil
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
