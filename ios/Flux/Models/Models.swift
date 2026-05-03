import Foundation

// MARK: - Dashboard API Response
struct DashboardResponse: Codable {
    let status: String
    let data: DashboardData
}

struct DashboardData: Codable {
    let user: UserInfo
    let readiness: ReadinessInfo
    let completionPct: Int
    let streak: Int
    let todaysPlan: TodaysPlan?
    let planMeta: PlanMeta?
    let weeklyMileage: WeeklyMileage?
    let trainingLog: [TrainingLogItem]?
    let resiliency: ResiliencyData?
    let aiProposal: AIProposal?
    let planActivities: [PlanActivity]?
    
    enum CodingKeys: String, CodingKey {
        case user, readiness, streak, resiliency
        case completionPct = "completion_pct"
        case todaysPlan = "todays_plan"
        case planMeta = "plan_meta"
        case weeklyMileage = "weekly_mileage"
        case trainingLog = "training_log"
        case aiProposal = "ai_proposal"
        case planActivities = "plan_activities"
    }
}

struct UserInfo: Codable {
    let fullName: String?
    let email: String
    let profilePicture: String?
    
    enum CodingKeys: String, CodingKey {
        case email
        case fullName = "full_name"
        case profilePicture = "profile_picture"
    }
}

struct ReadinessInfo: Codable {
    let score: Int
    let label: String
    let colorClass: String
    
    enum CodingKeys: String, CodingKey {
        case score, label
        case colorClass = "colorClass"
    }
}

struct TodaysPlan: Codable {
    let id: Int
    let type: String
    let title: String
    let description: String
    let duration: String
    let status: String
}

struct PlanMeta: Codable {
    let goal: String
    let targetDate: String?
    let totalWeeks: Int?
    let completedWeeks: Int?
    
    enum CodingKeys: String, CodingKey {
        case goal
        case targetDate = "target_date"
        case totalWeeks = "total_weeks"
        case completedWeeks = "completed_weeks"
    }
}

struct WeeklyMileage: Codable {
    let labels: [String]
    let data: [Int]
}

struct TrainingLogItem: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let date: String
    let status: String
}

struct ResiliencyData: Codable {
    let heatmap: [HeatmapCell]
    let savedPct: Int
    let skippedPct: Int
    let originalCount: Int
    let adaptedCount: Int
    let skippedCount: Int
    
    enum CodingKeys: String, CodingKey {
        case heatmap
        case savedPct = "saved_pct"
        case skippedPct = "skipped_pct"
        case originalCount = "original_count"
        case adaptedCount = "adapted_count"
        case skippedCount = "skipped_count"
    }
}

struct HeatmapCell: Codable {
    let date: String
    let state: String
}

struct AIProposal: Codable {
    let exists: Bool
    let id: Int?
    let reason: String?
    let suggestion: String?
}

struct PlanActivity: Codable, Identifiable {
    let id: Int
    let type: String
    let title: String
    let description: String
    let duration: String
    let date: String
    let status: String
}

// MARK: - Plan Builder
struct PlanCreateRequest: Codable {
    let userId: Int
    let name: String
    let goalRace: String
    let raceDistance: String
    let startDate: String
    let endDate: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case userId = "user_id"
        case goalRace = "goal_race"
        case raceDistance = "race_distance"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct UserPlanResponse: Codable {
    let status: String
    let data: UserPlanData?
}

struct UserPlanData: Codable {
    let id: Int
    let name: String
    let goalRace: String
    let raceDistance: String
    let weeks: Int
    let startDate: String?
    let endDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, weeks
        case goalRace = "goal_race"
        case raceDistance = "race_distance"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

// MARK: - Auth
struct AuthRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let status: String
    let data: AuthData
}

struct AuthData: Codable {
    let id: Int
    let email: String
    let fullName: String?
    let isNew: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name"
        case isNew = "is_new"
    }
}

// MARK: - Biometrics
struct BiometricEntry: Codable {
    let userId: Int
    let hrv: Double?
    let restingHeartRate: Double?
    let sleepHours: Double?
    let readinessScore: Double?
    let recordedDate: String
    
    enum CodingKeys: String, CodingKey {
        case hrv
        case userId = "user_id"
        case restingHeartRate = "resting_heart_rate"
        case sleepHours = "sleep_hours"
        case readinessScore = "readiness_score"
        case recordedDate = "recorded_date"
    }
}
