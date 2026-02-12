import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = URL(string: SupabaseConfig.url)!
        let supabaseKey = SupabaseConfig.anonKey
        
        // Configure AuthClient with emitLocalSessionAsInitialSession to opt-in to new behavior
        var options = SupabaseClientOptions()
        options.auth.flowType = .implicit
        options.auth.emitLocalSessionAsInitialSession = true
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: options
        )
    }
}
