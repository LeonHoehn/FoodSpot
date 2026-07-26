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
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var mapViewModel = MapViewModel()

    private static let radiusOptions: [Double] = [1, 2, 5, 10, 20]

    var body: some View {
        NavigationStack {
            MapView(viewModel: mapViewModel)
                .navigationTitle("FoodSpot")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        radiusMenu
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Abmelden", role: .destructive) {
                            Task { await authViewModel.signOut() }
                        }
                    }
                }
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
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
