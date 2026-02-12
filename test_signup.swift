import Foundation

// Test signup directly with Supabase API
let url = URL(string: "https://wabgklhhrviqcfdiwofu.supabase.co/auth/v1/signup")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.addValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhYmdrbGhocnZpcWNmZGl3b2Z1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MTc4MDksImV4cCI6MjA4NjQ5MzgwOX0.4SGTbcbFImfTPCqPBPG32EO3N7tDitV9HyBI_S3RkBo", forHTTPHeaderField: "apikey")
request.addValue("application/json", forHTTPHeaderField: "Content-Type")

let testEmail = "test\(Int(Date().timeIntervalSince1970))@gmail.com"
let body: [String: Any] = [
    "email": testEmail,
    "password": "testpass123",
    "data": ["full_name": "Test User"]
]
request.httpBody = try? JSONSerialization.data(withJSONObject: body)

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let httpResponse = response as? HTTPURLResponse {
        print("Status Code: \(httpResponse.statusCode)")
        if let data = data, let body = String(data: data, encoding: .utf8) {
            print("Response: \(body)")
        }
    }
    if let error = error {
        print("Error: \(error)")
    }
    exit(0)
}

task.resume()
RunLoop.main.run()
