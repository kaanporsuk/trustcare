import Foundation

let url = URL(string: "https://wabgklhhrviqcfdiwofu.supabase.co/rest/v1/providers?select=count")!
var request = URLRequest(url: url)
request.addValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhYmdrbGhocnZpcWNmZGl3b2Z1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MTc4MDksImV4cCI6MjA4NjQ5MzgwOX0.4SGTbcbFImfTPCqPBPG32EO3N7tDitV9HyBI_S3RkBo", forHTTPHeaderField: "apikey")
request.addValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhYmdrbGhocnZpcWNmZGl3b2Z1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MTc4MDksImV4cCI6MjA4NjQ5MzgwOX0.4SGTbcbFImfTPCqPBPG32EO3N7tDitV9HyBI_S3RkBo", forHTTPHeaderField: "Authorization")

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
