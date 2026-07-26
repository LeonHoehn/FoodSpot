import MapKit
import SwiftUI

struct MapView: View {
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var locationManager: LocationManager
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedRestaurant: RestaurantSummary?

    var body: some View {
        Map(position: $cameraPosition, selection: $viewModel.selectedPinID) {
            UserAnnotation()

            ForEach(viewModel.displayedPins) { pin in
                Marker(pin.name, coordinate: pin.coordinate)
                    .tint(viewModel.isSearchActive ? .orange : .accentColor)
                    .tag(pin.id)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .searchable(text: $viewModel.searchText, prompt: "Gericht suchen, z. B. Ramen")
        .overlay(alignment: .top) {
            if let errorMessage = viewModel.errorMessage {
                hintBanner(errorMessage)
            } else if viewModel.showsNoResultsHint {
                hintBanner("Keine Bewertungen für „\(viewModel.searchText)“ im Umkreis von \(Int(viewModel.radiusKm)) km.")
            }
        }
        .overlay {
            if (viewModel.isLoading && viewModel.restaurants.isEmpty) || viewModel.isSearching {
                ProgressView()
            } else if viewModel.showsEmptyMapHint {
                emptyMapHint
            }
        }
        .onChange(of: viewModel.searchText) {
            performSearch()
        }
        .onChange(of: viewModel.radiusKm) {
            performSearch()
        }
        .onChange(of: locationManager.locationUpdateCount) {
            if viewModel.isSearchActive {
                performSearch()
            }
        }
        .onChange(of: viewModel.selectedPinID) { _, newValue in
            guard let id = newValue else { return }
            selectedRestaurant = viewModel.restaurantSummary(for: id)
        }
        .sheet(item: $selectedRestaurant, onDismiss: { viewModel.selectedPinID = nil }) { restaurant in
            RestaurantDetailSheet(restaurant: restaurant)
        }
        .task {
            locationManager.requestAuthorization()
            locationManager.requestLocation()
            await viewModel.loadRestaurants()
        }
    }

    private func performSearch() {
        viewModel.scheduleSearch(
            near: locationManager.currentLocation,
            isAuthorizationDenied: locationManager.isAuthorizationDenied
        )
    }

    private var emptyMapHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife.circle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Noch keine Restaurants in der Nähe")
                .font(.headline)
            Text("Tippe oben rechts auf „+“, um dein erstes Restaurant hinzuzufügen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(.thinMaterial, in: .rect(cornerRadius: 16))
        .padding(.horizontal, 40)
        .allowsHitTesting(false)
    }

    private func hintBanner(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: .rect(cornerRadius: 10))
            .padding(.top, 8)
            .padding(.horizontal, 16)
    }
}

#Preview {
    MapView(viewModel: MapViewModel(), locationManager: LocationManager())
}
