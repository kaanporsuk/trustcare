import Foundation

// Test signup with detailed error response
let url = URL(string: "https://wabgklhhrviqcfdiwofu.supabase.co/auth/v1/signup")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.addValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhYmdrbGhocnZpcWNmZGl3b2Z1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MTc4MDksImV4cCI6MjA4NjQ5MzgwOX0.4SGTbcbFImfTPCqPBPG32EO3N7tDitV9HyBI_S3RkBo", forHTTPHeaderField: "apikey")
request.addValue("application/json", forHTTPHeaderField: "Content-Type")

// Test with a real-looking email
let testEmail = "kaan.test@gmail.com"
let body: [String: Any] = [
    "email": testEmail,
    "password": "TestPassword123!",
    "data": ["full_name": "Kaan Test"]
]
request.httpBody = try? JSONSerialization.data(withJSONObject: body)

print("Testing signup for: \(testEmail)")
print("URL: \(url.absoluteString)")

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let httpResponse = response as? HTTPURLResponse {
        print("\n=== Response ===")
        print("Status Code: \(httpResponse.statusCode)")
        print("Headers: \(httpResponse.allHeaderFields)")
    }
    
    if let data = data {
        print("\n=== Body ===")
        if let jsonString = String(data: data, encoding: .utf8) {
            print(jsonString)
        }
        
        // Try to parse as JSON for better formatting
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("\n=== Parsed JSON ===")
            print(json)
        }
    }
    
    if let error = error {
        print("\n=== Network Error ===")
        print("Error: \(error)")
        print("Local Description: \(error.localizedDescription)")
    }
    
    exit(0)
}

task.resume()
RunLoop.main.run()
