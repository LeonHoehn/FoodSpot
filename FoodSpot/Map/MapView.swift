import MapKit
import SwiftUI

struct MapView: View {
    @ObservedObject var viewModel: MapViewModel
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            ForEach(viewModel.displayedPins) { pin in
                Marker(pin.name, coordinate: pin.coordinate)
                    .tint(viewModel.isSearchActive ? .orange : .accentColor)
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
            }
        }
        .onChange(of: viewModel.searchText) {
            viewModel.scheduleSearch(near: locationManager.currentLocation)
        }
        .onChange(of: viewModel.radiusKm) {
            viewModel.scheduleSearch(near: locationManager.currentLocation)
        }
        .onChange(of: locationManager.locationUpdateCount) {
            if viewModel.isSearchActive {
                viewModel.scheduleSearch(near: locationManager.currentLocation)
            }
        }
        .task {
            locationManager.requestAuthorization()
            locationManager.requestLocation()
            await viewModel.loadRestaurants()
        }
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
    MapView(viewModel: MapViewModel())
}
