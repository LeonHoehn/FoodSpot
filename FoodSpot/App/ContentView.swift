import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        if authViewModel.isSignedIn {
            SignedInPlaceholderView()
        } else {
            SignInView()
        }
    }
}

/// Platzhalter bis Phase 3 (Kartenansicht) umgesetzt ist.
private struct SignedInPlaceholderView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                Text("Angemeldet")
                    .font(.title2.bold())
                Text("Die Kartenansicht folgt in Phase 3.")
                    .foregroundStyle(.secondary)

                Button("Abmelden", role: .destructive) {
                    Task { await authViewModel.signOut() }
                }
                .padding(.top, 24)
            }
            .navigationTitle("FoodSpot")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
