import AuthenticationServices
import Foundation
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseManager.shared.client
    private var authStateTask: Task<Void, Never>?

    var isSignedIn: Bool { session != nil }

    init() {
        authStateTask = Task { [weak self] in
            guard let self else { return }
            for await state in client.auth.authStateChanges {
                self.session = state.session
            }
        }
    }

    deinit {
        authStateTask?.cancel()
    }

    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil

        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }

        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let identityTokenData = credential.identityToken,
                let identityToken = String(data: identityTokenData, encoding: .utf8)
            else {
                errorMessage = "Apple-Anmeldung lieferte keinen gültigen Token."
                return
            }

            isLoading = true
            defer { isLoading = false }

            do {
                try await client.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(provider: .apple, idToken: identityToken)
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
