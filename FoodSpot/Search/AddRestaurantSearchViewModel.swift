import CoreLocation
import Foundation
import MapKit

@MainActor
final class AddRestaurantSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [MKMapItem] = [] {
        didSet { resultsUpdateCount += 1 }
    }
    @Published private(set) var isSearching = false
    @Published var errorMessage: String?
    /// MKMapItem ist nicht Equatable, daher zählt dieser Wert Updates hoch,
    /// damit SwiftUI-`onChange` auf neue Ergebnisse reagieren kann.
    @Published private(set) var resultsUpdateCount = 0

    private let searchService = RestaurantSearchService()
    private var searchTask: Task<Void, Never>?

    func scheduleSearch(near coordinate: CLLocationCoordinate2D?, isAuthorizationDenied: Bool = false) {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            errorMessage = nil
            return
        }

        if isAuthorizationDenied {
            errorMessage = "Standortzugriff verweigert – aktiviere ihn in den Einstellungen, um Restaurants in deiner Nähe zu finden."
            return
        }

        guard let coordinate else {
            errorMessage = "Standort wird noch ermittelt…"
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            isSearching = true
            errorMessage = nil
            defer { isSearching = false }

            do {
                let items = try await searchService.search(query: trimmed, near: coordinate)
                guard !Task.isCancelled else { return }
                results = items
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
