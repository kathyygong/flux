import Foundation

// MARK: - API Client
class APIClient {
    static let shared = APIClient()
    
    // Change this to your server URL
    #if targetEnvironment(simulator)
    private let baseURL = "http://localhost:8000/api/v1"
    private let serverRoot = "http://localhost:8000"
    #else
    private let baseURL = "http://localhost:8000/api/v1" // Update for production
    private let serverRoot = "http://localhost:8000"
    #endif
    
    // Google OAuth URL — opens in browser, backend redirects back with flux:// callback
    var googleAuthURL: URL {
        URL(string: "\(serverRoot)/api/v1/auth/google/login?callback_scheme=flux")!
    }
    
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    
    // MARK: - Auth
    func login(email: String, password: String) async throws -> AuthResponse {
        let body = AuthRequest(email: email, password: password)
        return try await post("/auth/login", body: body)
    }
    
    func signup(email: String, password: String) async throws -> AuthResponse {
        let body = AuthRequest(email: email, password: password)
        return try await post("/auth/signup", body: body)
    }
    
    // MARK: - Dashboard
    func fetchDashboard(userId: Int) async throws -> DashboardResponse {
        return try await get("/dashboard/\(userId)")
    }
    
    // MARK: - Plan
    func fetchUserPlan(userId: Int) async throws -> UserPlanResponse {
        return try await get("/training-plans/user/\(userId)")
    }
    
    func createPlan(_ request: PlanCreateRequest) async throws -> Data {
        return try await postRaw("/training-plans", body: request)
    }
    
    func updatePlan(planId: Int, _ request: PlanCreateRequest) async throws -> Data {
        return try await putRaw("/training-plans/\(planId)", body: request)
    }
    
    // MARK: - Activity
    func completeActivity(activityId: Int) async throws {
        let _: EmptyResponse = try await post("/dashboard/activity/\(activityId)/complete", body: EmptyBody())
    }
    
    // MARK: - Biometrics
    func postBiometrics(_ entry: BiometricEntry) async throws {
        let _: Data = try await postRaw("/biometrics", body: entry)
    }
    
    func fetchBiometrics(userId: Int, limit: Int = 14) async throws -> BiometricsResponse {
        return try await get("/biometrics/\(userId)?limit=\(limit)")
    }
    
    // MARK: - Generic HTTP Methods
    private func get<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("No response from server")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let message = extractErrorMessage(from: data) ?? "Request failed (HTTP \(httpResponse.statusCode))"
            throw APIError.serverError(message)
        }
        
        return try decoder.decode(T.self, from: data)
    }
    
    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        let data = try await requestWithBody(path, method: "POST", body: body)
        return try decoder.decode(T.self, from: data)
    }
    
    private func postRaw<B: Encodable>(_ path: String, body: B) async throws -> Data {
        return try await requestWithBody(path, method: "POST", body: body)
    }
    
    private func putRaw<B: Encodable>(_ path: String, body: B) async throws -> Data {
        return try await requestWithBody(path, method: "PUT", body: body)
    }
    
    private func requestWithBody<B: Encodable>(_ path: String, method: String, body: B) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("No response from server")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let message = extractErrorMessage(from: data) ?? "Request failed (HTTP \(httpResponse.statusCode))"
            throw APIError.serverError(message)
        }
        
        return data
    }
    
    // MARK: - Error Parsing
    private func extractErrorMessage(from data: Data) -> String? {
        // Try FastAPI's {"detail": "..."} format
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let detail = json["detail"] as? String { return detail }
            if let message = json["message"] as? String { return message }
        }
        return nil
    }
}

// MARK: - Supporting Types
struct EmptyBody: Encodable {}
struct EmptyResponse: Decodable {}

struct BiometricsResponse: Codable {
    let status: String
    let data: [BiometricRecord]
}

struct BiometricRecord: Codable, Identifiable {
    let id: Int
    let hrv: Double?
    let restingHeartRate: Double?
    let sleepHours: Double?
    let readinessScore: Double?
    let recordedDate: String
    
    enum CodingKeys: String, CodingKey {
        case id, hrv
        case restingHeartRate = "resting_heart_rate"
        case sleepHours = "sleep_hours"
        case readinessScore = "readiness_score"
        case recordedDate = "recorded_date"
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case serverError(String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .serverError(let msg): return msg
        case .decodingError: return "Failed to decode response"
        }
    }
}
