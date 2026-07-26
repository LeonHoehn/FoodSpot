import MapKit
import SwiftUI

struct MapView: View {
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var locationManager: LocationManager
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedRestaurant: RestaurantSummary?
    @State private var searchSheetDetent: PresentationDetent = .medium

    var body: some View {
        Map(position: $cameraPosition, selection: $viewModel.selectedPinID) {
            UserAnnotation()

            ForEach(viewModel.displayedPins) { pin in
                Marker(pin.name, coordinate: pin.coordinate)
                    .tint(viewModel.isSearchSheetPresented ? .orange : .accentColor)
                    .tag(pin.id)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .overlay(alignment: .top) {
            if let errorMessage = viewModel.errorMessage {
                hintBanner(errorMessage)
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.restaurants.isEmpty {
                ProgressView()
            } else if viewModel.showsEmptyMapHint {
                emptyMapHint
            }
        }
        .overlay(alignment: .bottom) {
            if !viewModel.isSearchSheetPresented {
                searchTrigger
                    .padding(.bottom, 8)
            }
        }
        .onChange(of: viewModel.selectedPinID) { _, newValue in
            guard let id = newValue else { return }
            selectedRestaurant = viewModel.restaurantSummary(for: id)
        }
        .sheet(item: $selectedRestaurant, onDismiss: { viewModel.selectedPinID = nil }) { restaurant in
            RestaurantDetailSheet(restaurant: restaurant)
        }
        .sheet(isPresented: $viewModel.isSearchSheetPresented) {
            SearchResultsSheet(viewModel: viewModel, locationManager: locationManager)
                .presentationDetents([.medium, .large], selection: $searchSheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationBackground(
                    searchSheetDetent == .medium
                        ? AnyShapeStyle(Material.ultraThinMaterial.opacity(0.7))
                        : AnyShapeStyle(Color(.systemGroupedBackground))
                )
        }
        .task {
            locationManager.requestAuthorization()
            locationManager.requestLocation()
            await viewModel.loadRestaurants()
        }
    }

    private var searchTrigger: some View {
        Button {
            viewModel.isSearchSheetPresented = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                Text(viewModel.searchText.isEmpty ? "Gericht suchen, z. B. Ramen" : viewModel.searchText)
                    .foregroundStyle(viewModel.searchText.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(12)
            .glassCapsuleBackground()
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
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

private extension View {
    /// Liquid-Glass-Optik (iOS 26+) wie bei den nativen Map-Controls,
    /// mit Material-Fallback für ältere Systeme.
    @ViewBuilder
    func glassCapsuleBackground() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: .capsule)
        } else {
            self.background(.thickMaterial, in: .capsule)
        }
    }
}

#Preview {
    MapView(viewModel: MapViewModel(), locationManager: LocationManager())
}
