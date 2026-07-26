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
    @State private var isShowingProfile = false

    var body: some View {
        NavigationStack {
            MapView(viewModel: mapViewModel, locationManager: locationManager)
                .navigationTitle("FoodSpot")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isShowingProfile = true
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                        .accessibilityLabel("Profil")
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
                .navigationDestination(isPresented: $isShowingProfile) {
                    ProfileView(locationManager: locationManager)
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
