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
                            mapViewModel.isShowingAddRestaurant = true
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
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
