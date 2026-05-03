import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var dashboardData: DashboardData?
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Greeting
                    greetingSection
                    
                    // Today's Session
                    todaysSessionCard
                    
                    // Key Metrics
                    metricsGrid
                    
                    // Mileage Placeholder
                    mileageCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadData()
            }
        }
        .task {
            await loadData()
        }
    }
    
    // MARK: - Greeting
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("Let's make today count.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = appState.userName?.components(separatedBy: " ").first ?? "Runner"
        if hour < 12 { return "Good morning, \(name)" }
        else if hour < 18 { return "Good afternoon, \(name)" }
        else { return "Good evening, \(name)" }
    }
    
    // MARK: - Today's Session
    private var todaysSessionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Session")
                    .font(.headline)
                Spacer()
                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            
            if let plan = dashboardData?.todaysPlan {
                Text(plan.type.uppercased())
                    .font(.caption.bold())
                    .foregroundColor(.blue)
                    .tracking(1)
                
                Text(plan.title)
                    .font(.title3.bold())
                
                Text(plan.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if plan.status == "completed" {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                        .padding(.top, 4)
                } else {
                    Button {
                        Task { await completeWorkout(id: plan.id) }
                    } label: {
                        Text("Mark Complete")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 4)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "leaf")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("Rest Day")
                        .font(.title3.bold())
                    Text("Focus on mobility and hydration.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Readiness",
                value: "\(dashboardData?.readiness.score ?? 0)",
                subtitle: dashboardData?.readiness.label ?? "—",
                color: .green
            )
            
            MetricCard(
                title: "Completion",
                value: "\(dashboardData?.completionPct ?? 0)%",
                subtitle: "Consistency",
                color: .blue
            )
            
            MetricCard(
                title: "Streak",
                value: "\(dashboardData?.streak ?? 0)",
                subtitle: "Active days",
                color: .orange
            )
        }
    }
    
    // MARK: - Mileage
    private var mileageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Progress")
                .font(.headline)
            
            if let mileage = dashboardData?.weeklyMileage, !mileage.data.isEmpty {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(zip(mileage.labels.indices, mileage.data)), id: \.0) { index, value in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.gradient)
                                .frame(height: max(8, CGFloat(value) * 12))
                            
                            Text(mileage.labels[index].replacingOccurrences(of: "Week ", with: "W"))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            } else {
                Text("Complete workouts to see your progress here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Data Loading
    private func loadData() async {
        guard let userId = appState.userId else { return }
        do {
            let response = try await APIClient.shared.fetchDashboard(userId: userId)
            await MainActor.run {
                dashboardData = response.data
                isLoading = false
            }
        } catch {
            print("Dashboard error: \(error)")
            isLoading = false
        }
    }
    
    private func completeWorkout(id: Int) async {
        do {
            try await APIClient.shared.completeActivity(activityId: id)
            await loadData()
        } catch {
            print("Complete error: \(error)")
        }
    }
}

// MARK: - Metric Card Component
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
