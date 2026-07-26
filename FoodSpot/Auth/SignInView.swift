import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text("FoodSpot")
                    .font(.largeTitle.bold())

                Text("Finde die besten Gerichte in deiner Nähe.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task { await authViewModel.handleSignInWithAppleCompletion(result) }
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 50)
            .padding(.horizontal, 32)
            .disabled(authViewModel.isLoading)
            .overlay {
                if authViewModel.isLoading {
                    ProgressView()
                }
            }

            #if DEBUG
            Button {
                Task { await authViewModel.signInAsDebugUser() }
            } label: {
                Text("Debug-Login (nur lokal)")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.gray)
            .frame(height: 50)
            .padding(.horizontal, 32)
            .disabled(authViewModel.isLoading)
            #endif

            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding()
    }

    @Environment(\.colorScheme) private var colorScheme
}

#Preview {
    SignInView()
        .environmentObject(AuthViewModel())
}
