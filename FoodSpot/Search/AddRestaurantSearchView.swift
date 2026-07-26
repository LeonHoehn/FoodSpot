import CoreLocation
import MapKit
import SwiftUI

struct AddRestaurantSearchView: View {
    let userLocation: CLLocationCoordinate2D?
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
                } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                    ContentUnavailableView.search(text: viewModel.query)
                }
            }
            .searchable(text: $viewModel.query, prompt: "Restaurant suchen")
            .onChange(of: viewModel.query) {
                viewModel.scheduleSearch(near: userLocation)
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
}
