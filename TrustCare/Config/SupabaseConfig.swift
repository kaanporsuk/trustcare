import Foundation

enum SupabaseConfig {
    static let devUrl: String = "http://127.0.0.1:54321"
    static let devAnonKey: String = "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"
    static let prodUrl: String = "https://your-project.supabase.co"
    static let prodAnonKey: String = "sb_publishable_your_production_key"

    static var url: String {
        isProduction ? prodUrl : devUrl
    }

    static var anonKey: String {
        isProduction ? prodAnonKey : devAnonKey
    }

    private static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
}
