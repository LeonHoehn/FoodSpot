import CoreLocation
import MapKit
import SwiftUI

struct AddRestaurantSearchView: View {
    @ObservedObject var locationManager: LocationManager
    let onSelect: (MKMapItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddRestaurantSearchViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }

                ForEach(Array(viewModel.results.enumerated()), id: \.offset) { _, item in
                    Button {
                        onSelect(item)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "Unbekanntes Restaurant")
                                .foregroundStyle(.primary)
                            if let address = item.placemark.title {
                                Text(address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .overlay {
                if viewModel.isSearching {
                    ProgressView()
                } else if viewModel.query.isEmpty {
                    ContentUnavailableView {
                        Label("Restaurant suchen", systemImage: "magnifyingglass")
                    } description: {
                        Text("Suche nach dem Namen eines Restaurants in deiner Nähe.")
                    }
                } else if viewModel.results.isEmpty && viewModel.errorMessage == nil {
                    ContentUnavailableView.search(text: viewModel.query)
                }
            }
            .searchable(text: $viewModel.query, prompt: "Restaurant suchen")
            .onChange(of: viewModel.query) {
                performSearch()
            }
            .onChange(of: locationManager.locationUpdateCount) {
                performSearch()
            }
            .navigationTitle("Restaurant finden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }

    private func performSearch() {
        viewModel.scheduleSearch(
            near: locationManager.currentLocation,
            isAuthorizationDenied: locationManager.isAuthorizationDenied
        )
    }
}
