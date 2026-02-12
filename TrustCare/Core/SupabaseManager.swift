import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let url = URL(string: SupabaseConfig.url) ?? URL(string: "http://127.0.0.1:54321")!
        client = SupabaseClient(supabaseURL: url, supabaseKey: SupabaseConfig.anonKey)
    }
}
