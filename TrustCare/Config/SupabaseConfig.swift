import Foundation

enum SupabaseConfig {
    // ============================================================
    // HOW TO SWITCH MODES:
    // 1. Comment out the mode you DON'T want
    // 2. Uncomment the mode you DO want
    // 3. Rebuild (Cmd+B)
    // ============================================================
    
    // --- MODE 1: Local Docker + Xcode Simulator ---
    // static let url = "http://127.0.0.1:54321"
    // static let anonKey = "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"
    
    // --- MODE 2: Local Docker + Physical iPhone via USB (same WiFi) ---
    // static let url = "http://192.168.1.11:54321"
    // static let anonKey = "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"
    
    // --- MODE 3: Cloud Supabase (TestFlight / Production) ---
    static let url = "https://wabgklhhrviqcfdiwofu.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhYmdrbGhocnZpcWNmZGl3b2Z1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MTc4MDksImV4cCI6MjA4NjQ5MzgwOX0.4SGTbcbFImfTPCqPBPG32EO3N7tDitV9HyBI_S3RkBo"
}
