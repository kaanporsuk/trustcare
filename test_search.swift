import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let url = URL(string: "https://wabgklhhrviqcfdiwofu.supabase.co/rest/v1/rpc/search_providers")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhYmdrbGhocnZpcWNmZGl3b2Z1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY3MjMzNzUsImV4cCI6MjA1MjI5OTM3NX0.4SGTbcbFImfTPCqPBPG32EO3N7tDitV9HyBI_S3RkBo", forHTTPHeaderField: "apikey")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

// Test with empty search (just like clicking the search field with no text)
let body: [String: Any] = [
    "search_query": "",
    "specialty_filter": NSNull(),
    "country_filter": NSNull(),
    "price_level_filter": NSNull(),
    "min_rating": 0,
    "verified_only": false,
    "user_lat": NSNull(),
    "user_lng": NSNull(),
    "result_limit": 20,
    "result_offset": 0
]

request.httpBody = try! JSONSerialization.data(withJSONObject: body)

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let error = error {
        print("❌ Error: \(error.localizedDescription)")
        exit(1)
    }
    
    if let httpResponse = response as? HTTPURLR    if let httpResponse = response as? HTTPURLR    if let httpResponse = response as? HTTPURLR    if let httpResponse = response as? HTTPURLR    if let httpResponse = response as? HTTPURLR    if let httpResponse = response as? HTTPURLR    if let httpRespons i    if let httpResponse = response as? HTTPURLR    if let httpResponse me"] ?? "unknown")")
            }
        } else if let errorJson = try? JSONSe        } elseonObject(with: data) as? [String: Any] {
            print("❌ Error response: \(errorJson)")
        } else {
            print("Response: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
        }
    }
    exit(0)
}

task.resume()
RunLoop.main.run()
