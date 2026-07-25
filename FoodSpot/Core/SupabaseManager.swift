import Foundation
import Supabase

enum SupabaseConfig {
    static let url: URL = {
        guard
            let raw = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
            let url = URL(string: raw)
        else {
            fatalError("SUPABASE_URL fehlt oder ist ungültig. Config/Secrets.xcconfig prüfen.")
        }
        return url
    }()

    static let anonKey: String = {
        guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String, !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY fehlt. Config/Secrets.xcconfig prüfen.")
        }
        return key
    }()
}

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(supabaseURL: SupabaseConfig.url, supabaseKey: SupabaseConfig.anonKey)
    }
}
