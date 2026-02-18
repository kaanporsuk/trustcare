import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let authConfig = SupabaseClientOptions.AuthOptions(
            emitLocalSessionAsInitialSession: true
        )
        
        client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey,
            options: SupabaseClientOptions(auth: authConfig)
        )
    }
}
