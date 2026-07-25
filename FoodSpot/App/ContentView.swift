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

    var body: some View {
        NavigationStack {
            MapView()
                .navigationTitle("FoodSpot")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Abmelden", role: .destructive) {
                            Task { await authViewModel.signOut() }
                        }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
