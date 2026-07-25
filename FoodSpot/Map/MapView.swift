import MapKit
import SwiftUI

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            ForEach(viewModel.restaurants) { restaurant in
                Marker(restaurant.name, coordinate: restaurant.coordinate)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .overlay(alignment: .top) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: .rect(cornerRadius: 10))
                    .padding(.top, 8)
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.restaurants.isEmpty {
                ProgressView()
            }
        }
        .task {
            locationManager.requestAuthorization()
            await viewModel.loadRestaurants()
        }
    }
}

#Preview {
    MapView()
}
