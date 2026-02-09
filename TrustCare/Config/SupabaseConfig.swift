import Foundation

enum SupabaseConfig {
    static var url: String {
        guard let value = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              !value.isEmpty else {
            fatalError("SUPABASE_URL not set in xcconfig")
        }
        return value
    }

    static var anonKey: String {
        guard let value = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
              !value.isEmpty else {
            fatalError("SUPABASE_ANON_KEY not set in xcconfig")
        }
        return value
    }
}
