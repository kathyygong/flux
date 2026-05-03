import SwiftUI
import Charts

struct RecoveryView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var healthKit: HealthKitManager
    @State private var biometrics: [BiometricRecord] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Recovery Summary
                    recoverySummaryCard
                    
                    // HealthKit Live Data
                    healthKitCard
                    
                    // Charts Grid
                    chartsGrid
                    
                    // Sync Button
                    syncButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Recovery")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                healthKit.fetchAllMetrics()
                await loadBiometrics()
            }
        }
        .task {
            await loadBiometrics()
        }
    }
    
    // MARK: - Recovery Summary
    private var recoverySummaryCard: some View {
        VStack(spacing: 16) {
            Text("Recovery Status")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                RecoveryMetricBadge(
                    label: "Score",
                    value: String(format: "%.0f", healthKit.computeReadiness()),
                    color: readinessColor
                )
                
                RecoveryMetricBadge(
                    label: "HRV",
                    value: healthKit.latestHRV.map { String(format: "%.0f", $0) + "ms" } ?? "—",
                    color: .purple
                )
                
                RecoveryMetricBadge(
                    label: "Sleep",
                    value: healthKit.latestSleepHours.map { String(format: "%.1f", $0) + "h" } ?? "—",
                    color: .indigo
                )
                
                RecoveryMetricBadge(
                    label: "RHR",
                    value: healthKit.latestRestingHR.map { String(format: "%.0f", $0) + " bpm" } ?? "—",
                    color: .red
                )
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var readinessColor: Color {
        let score = healthKit.computeReadiness()
        if score >= 80 { return .green }
        else if score >= 60 { return .yellow }
        else { return .red }
    }
    
    // MARK: - HealthKit Live
    private var healthKitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Apple Health")
                    .font(.headline)
                Spacer()
                if healthKit.isAuthorized {
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                } else {
                    Button("Connect") {
                        healthKit.requestAuthorization()
                    }
                    .font(.caption.bold())
                    .foregroundColor(.blue)
                }
            }
            
            if !healthKit.isAuthorized {
                Text("Connect Apple Health to see your real-time recovery metrics and get personalized training adjustments.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Charts
    private var chartsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            miniChart(title: "HRV", data: healthKit.hrvHistory, color: .purple, unit: "ms")
            miniChart(title: "Resting HR", data: healthKit.rhrHistory, color: .red, unit: "bpm")
            miniChart(title: "Sleep", data: healthKit.sleepHistory, color: .indigo, unit: "hrs")
            
            // Readiness from API biometrics
            if !biometrics.isEmpty {
                let readinessData = biometrics.compactMap { record -> (date: Date, value: Double)? in
                    guard let score = record.readinessScore else { return nil }
                    let date = ISO8601DateFormatter().date(from: record.recordedDate) ?? Date()
                    return (date: date, value: score)
                }
                miniChart(title: "Readiness", data: readinessData, color: .green, unit: "")
            }
        }
    }
    
    private func miniChart(title: String, data: [(date: Date, value: Double)], color: Color, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondary)
            
            if data.isEmpty {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(data.indices, id: \.self) { i in
                    LineMark(
                        x: .value("Date", data[i].date),
                        y: .value(title, data[i].value)
                    )
                    .foregroundStyle(color.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", data[i].date),
                        y: .value(title, data[i].value)
                    )
                    .foregroundStyle(color.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 80)
            }
            
            if let latest = data.last {
                Text(String(format: "%.1f", latest.value) + " " + unit)
                    .font(.caption2)
                    .foregroundColor(color)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Sync
    private var syncButton: some View {
        Button {
            Task {
                guard let userId = appState.userId else { return }
                await healthKit.syncToBackend(userId: userId)
            }
        } label: {
            Label("Sync Health Data to Flux", systemImage: "arrow.triangle.2.circlepath")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    private func loadBiometrics() async {
        guard let userId = appState.userId else { return }
        do {
            let response = try await APIClient.shared.fetchBiometrics(userId: userId)
            await MainActor.run { biometrics = response.data }
        } catch {
            print("Biometrics error: \(error)")
        }
    }
}

// MARK: - Recovery Metric Badge
struct RecoveryMetricBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
