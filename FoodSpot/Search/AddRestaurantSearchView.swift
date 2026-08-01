import CoreLocation
import MapKit
import SwiftUI

struct AddRestaurantSearchView: View {
    @ObservedObject var locationManager: LocationManager
    let onSelect: (MKMapItem) -> Void
    var onResultsChanged: ([MKMapItem]) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddRestaurantSearchViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }

                ForEach(Array(viewModel.results.enumerated()), id: \.offset) { _, item in
                    Button {
                        onSelect(item)
                        dismiss()
                    } label: {
                        resultCard(item)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .listStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: viewModel.results.count)
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
            .onChange(of: viewModel.resultsUpdateCount) {
                onResultsChanged(viewModel.results)
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

    private func resultCard(_ item: MKMapItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.orange.gradient)
                Image(systemName: "fork.knife")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name ?? "Unbekanntes Restaurant")
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let address = item.placemark.title {
                    Text(address)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.background.secondary, in: .rect(cornerRadius: 14))
    }

    private func performSearch() {
        viewModel.scheduleSearch(
            near: locationManager.currentLocation,
            isAuthorizationDenied: locationManager.isAuthorizationDenied
        )
    }
}
