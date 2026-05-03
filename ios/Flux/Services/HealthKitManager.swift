import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var latestHRV: Double?
    @Published var latestRestingHR: Double?
    @Published var latestSleepHours: Double?
    @Published var hrvHistory: [(date: Date, value: Double)] = []
    @Published var rhrHistory: [(date: Date, value: Double)] = []
    @Published var sleepHistory: [(date: Date, value: Double)] = []
    
    // MARK: - Authorization
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.restingHeartRate),
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.stepCount),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.activeEnergyBurned),
        ]
        
        let writeTypes: Set<HKSampleType> = [
            HKQuantityType.workoutType(),
        ]
        
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.fetchAllMetrics()
                }
            }
        }
    }
    
    // MARK: - Fetch All
    func fetchAllMetrics() {
        fetchLatestHRV()
        fetchLatestRestingHR()
        fetchLatestSleep()
        fetchHRVHistory(days: 14)
        fetchRHRHistory(days: 14)
        fetchSleepHistory(days: 14)
    }
    
    // MARK: - HRV
    func fetchLatestHRV() {
        let type = HKQuantityType(.heartRateVariabilitySDNN)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            DispatchQueue.main.async {
                self.latestHRV = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            }
        }
        healthStore.execute(query)
    }
    
    func fetchHRVHistory(days: Int) {
        fetchQuantityHistory(type: HKQuantityType(.heartRateVariabilitySDNN),
                           unit: HKUnit.secondUnit(with: .milli),
                           days: days) { history in
            DispatchQueue.main.async {
                self.hrvHistory = history
            }
        }
    }
    
    // MARK: - Resting Heart Rate
    func fetchLatestRestingHR() {
        let type = HKQuantityType(.restingHeartRate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            DispatchQueue.main.async {
                self.latestRestingHR = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
        }
        healthStore.execute(query)
    }
    
    func fetchRHRHistory(days: Int) {
        fetchQuantityHistory(type: HKQuantityType(.restingHeartRate),
                           unit: HKUnit.count().unitDivided(by: .minute()),
                           days: days) { history in
            DispatchQueue.main.async {
                self.rhrHistory = history
            }
        }
    }
    
    // MARK: - Sleep
    func fetchLatestSleep() {
        let type = HKCategoryType(.sleepAnalysis)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let calendar = Calendar.current
        let now = Date()
        let startOfYesterday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: now)!)
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: now, options: .strictEndDate)
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            // Sum up asleep time (filter out "inBed" if available)
            let asleepSamples = samples.filter { $0.value != HKCategoryValueSleepAnalysis.inBed.rawValue }
            let totalSeconds = asleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            let hours = totalSeconds / 3600.0
            
            DispatchQueue.main.async {
                self.latestSleepHours = hours
            }
        }
        healthStore.execute(query)
    }
    
    func fetchSleepHistory(days: Int) {
        let calendar = Calendar.current
        let now = Date()
        var history: [(date: Date, value: Double)] = []
        let group = DispatchGroup()
        
        for i in 0..<days {
            group.enter()
            let dayEnd = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -i, to: now)!)
            let dayStart = calendar.date(byAdding: .day, value: -1, to: dayEnd)!
            
            let type = HKCategoryType(.sleepAnalysis)
            let predicate = HKQuery.predicateForSamples(withStart: dayStart, end: dayEnd, options: .strictEndDate)
            
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let totalHours = (samples as? [HKCategorySample])?.reduce(0.0) {
                    $0 + $1.endDate.timeIntervalSince($1.startDate) / 3600.0
                } ?? 0
                
                history.append((date: dayStart, value: totalHours))
                group.leave()
            }
            healthStore.execute(query)
        }
        
        group.notify(queue: .main) {
            self.sleepHistory = history.sorted { $0.date < $1.date }
        }
    }
    
    // MARK: - Sync to Backend
    func syncToBackend(userId: Int) async {
        let today = ISO8601DateFormatter().string(from: Date())
        
        let entry = BiometricEntry(
            userId: userId,
            hrv: latestHRV,
            restingHeartRate: latestRestingHR,
            sleepHours: latestSleepHours,
            readinessScore: computeReadiness(),
            recordedDate: today
        )
        
        do {
            try await APIClient.shared.postBiometrics(entry)
            print("✅ Synced biometrics to backend")
        } catch {
            print("❌ Failed to sync biometrics: \(error)")
        }
    }
    
    // MARK: - Readiness Score (Composite)
    func computeReadiness() -> Double {
        var score: Double = 100
        
        // HRV component (higher = better, baseline ~40-60ms)
        if let hrv = latestHRV {
            if hrv < 20 { score -= 30 }
            else if hrv < 35 { score -= 15 }
            else if hrv > 60 { score += 5 }
        }
        
        // RHR component (lower = better, baseline ~55-65 bpm)
        if let rhr = latestRestingHR {
            if rhr > 75 { score -= 20 }
            else if rhr > 65 { score -= 10 }
            else if rhr < 55 { score += 5 }
        }
        
        // Sleep component (7-9 hours optimal)
        if let sleep = latestSleepHours {
            if sleep < 5 { score -= 25 }
            else if sleep < 6.5 { score -= 15 }
            else if sleep >= 7.5 { score += 5 }
        }
        
        return max(0, min(100, score))
    }
    
    // MARK: - Helper
    private func fetchQuantityHistory(type: HKQuantityType, unit: HKUnit, days: Int, completion: @escaping ([(date: Date, value: Double)]) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: now)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            let history = (samples as? [HKQuantitySample])?.map {
                (date: $0.endDate, value: $0.quantity.doubleValue(for: unit))
            } ?? []
            completion(history)
        }
        healthStore.execute(query)
    }
}
