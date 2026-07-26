import MapKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        if authViewModel.isSignedIn {
            HomeView()
        } else {
            SignInView()
        }
    }
}

private struct HomeView: View {
    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var locationManager = LocationManager()

    @State private var isShowingAddRestaurant = false
    @State private var restaurantPendingRating: RestaurantSummary?
    @State private var addRestaurantErrorMessage: String?

    private static let radiusOptions: [Double] = [1, 2, 5, 10, 20]

    var body: some View {
        TabView {
            NavigationStack {
                MapView(viewModel: mapViewModel, locationManager: locationManager)
                    .navigationTitle("FoodSpot")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            radiusMenu
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isShowingAddRestaurant = true
                            } label: {
                                Image(systemName: "plus")
                            }
                            .accessibilityLabel("Restaurant hinzufügen")
                        }
                    }
            }
            .tabItem {
                Label("Karte", systemImage: "map")
            }

            NavigationStack {
                ProfileView(locationManager: locationManager)
            }
            .tabItem {
                Label("Profil", systemImage: "person.crop.circle")
            }
        }
        .sheet(isPresented: $isShowingAddRestaurant) {
            AddRestaurantSearchView(locationManager: locationManager) { mapItem in
                Task { await handleRestaurantSelected(mapItem) }
            }
        }
        .sheet(item: $restaurantPendingRating) { restaurant in
            RatingFormView(restaurant: restaurant)
        }
        .alert(
            "Restaurant konnte nicht angelegt werden",
            isPresented: Binding(
                get: { addRestaurantErrorMessage != nil },
                set: { if !$0 { addRestaurantErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(addRestaurantErrorMessage ?? "")
        }
    }

    private var radiusMenu: some View {
        Menu {
            ForEach(Self.radiusOptions, id: \.self) { km in
                Button {
                    mapViewModel.radiusKm = km
                } label: {
                    if mapViewModel.radiusKm == km {
                        Label("\(Int(km)) km", systemImage: "checkmark")
                    } else {
                        Text("\(Int(km)) km")
                    }
                }
            }
        } label: {
            Label("\(Int(mapViewModel.radiusKm)) km", systemImage: "location.circle")
        }
    }

    @MainActor
    private func handleRestaurantSelected(_ mapItem: MKMapItem) async {
        do {
            let restaurant = try await RestaurantRepository().findOrCreate(mapItem: mapItem)
            await mapViewModel.loadRestaurants()
            restaurantPendingRating = restaurant.summary
        } catch {
            addRestaurantErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
