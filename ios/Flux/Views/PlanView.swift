import SwiftUI

struct PlanView: View {
    @EnvironmentObject var appState: AppState
    @State private var dashboardData: DashboardData?
    @State private var showPlanBuilder = false
    @State private var isModifying = false
    @State private var existingPlan: UserPlanData?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Plan Overview
                    planOverviewCard
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button { showCreatePlan() } label: {
                            Label("Create Plan", systemImage: "plus.circle")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        Button { showModifyPlan() } label: {
                            Label("Modify Plan", systemImage: "pencil.circle")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.ultraThinMaterial)
                                .foregroundColor(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    
                    // Daily Schedule
                    dailyScheduleCard
                    
                    // Weekly Breakdown
                    weeklyBreakdownCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await loadData() }
            .sheet(isPresented: $showPlanBuilder) {
                PlanBuilderSheet(
                    isModifying: isModifying,
                    existingPlan: existingPlan,
                    onComplete: {
                        showPlanBuilder = false
                        Task { await loadData() }
                    }
                )
                .environmentObject(appState)
            }
        }
        .task { await loadData() }
    }
    
    // MARK: - Plan Overview
    private var planOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(dashboardData?.planMeta?.goal ?? "No Active Plan")
                    .font(.title2.bold())
                Spacer()
                if let meta = dashboardData?.planMeta {
                    let daysLeft = daysUntilTarget(meta.targetDate)
                    Text("\(daysLeft) days left")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
            
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("Weeks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(dashboardData?.planMeta?.completedWeeks ?? 0)/\(dashboardData?.planMeta?.totalWeeks ?? 0)")
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(spacing: 4) {
                    Text("Resiliency")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(resiliencyScore)
                        .font(.title3.bold())
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(progressPercent)% Completed")
                        .font(.caption.bold())
                    Spacer()
                    Text("Week \(dashboardData?.planMeta?.completedWeeks ?? 0) of \(dashboardData?.planMeta?.totalWeeks ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.gradient)
                            .frame(width: geo.size.width * CGFloat(progressPercent) / 100)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Daily Schedule
    private var dailyScheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Sessions")
                .font(.headline)
            
            if let activities = dashboardData?.planActivities, !activities.isEmpty {
                ForEach(activities.prefix(5)) { activity in
                    HStack(spacing: 14) {
                        Circle()
                            .fill(activity.status == "completed" ? Color.green : Color.blue.opacity(0.2))
                            .frame(width: 10, height: 10)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.title)
                                .font(.subheadline.bold())
                            Text(formatDate(activity.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(activity.duration + " min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    
                    if activity.id != activities.prefix(5).last?.id {
                        Divider()
                    }
                }
            } else {
                Text("No upcoming sessions. Create a plan to get started!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Weekly Breakdown
    private var weeklyBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Breakdown")
                .font(.headline)
            
            if let activities = dashboardData?.planActivities, !activities.isEmpty {
                // Group by week
                let weeks = Dictionary(grouping: activities) { activity -> Int in
                    let date = ISO8601DateFormatter().date(from: activity.date) ?? Date()
                    return Calendar.current.component(.weekOfYear, from: date)
                }
                
                ForEach(Array(weeks.keys.sorted().prefix(4)), id: \.self) { weekNum in
                    let weekActivities = weeks[weekNum] ?? []
                    let runCount = weekActivities.filter { $0.type.lowercased().contains("run") || $0.type.lowercased().contains("easy") || $0.type.lowercased().contains("tempo") || $0.type.lowercased().contains("interval") }.count
                    
                    HStack {
                        Image(systemName: "flame")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Week \(weekNum)")
                                .font(.subheadline.bold())
                            Text("\(runCount) sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            } else {
                Text("No plan data available.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Helpers
    private var resiliencyScore: String {
        guard let r = dashboardData?.resiliency else { return "100%" }
        let total = r.originalCount + r.adaptedCount + r.skippedCount
        guard total > 0 else { return "100%" }
        let pct = Int(Double(r.originalCount + r.adaptedCount) / Double(total) * 100)
        return "\(pct)%"
    }
    
    private var progressPercent: Int {
        guard let meta = dashboardData?.planMeta,
              let total = meta.totalWeeks, total > 0,
              let completed = meta.completedWeeks else { return 0 }
        return min(100, Int(Double(completed) / Double(total) * 100))
    }
    
    private func daysUntilTarget(_ dateStr: String?) -> Int {
        guard let dateStr = dateStr,
              let date = ISO8601DateFormatter().date(from: dateStr) else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0)
    }
    
    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return isoString }
        let display = DateFormatter()
        display.dateFormat = "EEE, MMM d"
        return display.string(from: date)
    }
    
    private func showCreatePlan() {
        isModifying = false
        existingPlan = nil
        showPlanBuilder = true
    }
    
    private func showModifyPlan() {
        isModifying = true
        Task {
            guard let userId = appState.userId else { return }
            do {
                let response = try await APIClient.shared.fetchUserPlan(userId: userId)
                await MainActor.run {
                    existingPlan = response.data
                    showPlanBuilder = true
                }
            } catch {
                showPlanBuilder = true
            }
        }
    }
    
    private func loadData() async {
        guard let userId = appState.userId else { return }
        do {
            let response = try await APIClient.shared.fetchDashboard(userId: userId)
            await MainActor.run { dashboardData = response.data }
        } catch {
            print("Plan data error: \(error)")
        }
    }
}

// MARK: - Plan Builder Sheet
struct PlanBuilderSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    let isModifying: Bool
    let existingPlan: UserPlanData?
    let onComplete: () -> Void
    
    @State private var raceName = ""
    @State private var raceDistance = "Marathon"
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(30 * 86400)
    @State private var isSubmitting = false
    
    let distances = ["5K", "10K", "Half Marathon", "Marathon"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Race Details") {
                    TextField("Race Name", text: $raceName)
                    Picker("Distance", selection: $raceDistance) {
                        ForEach(distances, id: \.self) { Text($0) }
                    }
                }
                
                Section("Schedule") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section {
                    Button {
                        Task { await submitPlan() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView().tint(.white)
                            }
                            Text(isModifying ? "Regenerate Plan" : "Generate Plan")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.blue)
                    .foregroundColor(.white)
                    .disabled(raceName.isEmpty || isSubmitting)
                }
            }
            .navigationTitle(isModifying ? "Modify Plan" : "Create Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let plan = existingPlan {
                    raceName = plan.name
                    raceDistance = plan.raceDistance
                    if let s = plan.startDate { startDate = ISO8601DateFormatter().date(from: s + "T00:00:00Z") ?? Date() }
                    if let e = plan.endDate { endDate = ISO8601DateFormatter().date(from: e + "T00:00:00Z") ?? Date().addingTimeInterval(30 * 86400) }
                }
            }
        }
    }
    
    private func submitPlan() async {
        guard let userId = appState.userId else { return }
        isSubmitting = true
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        
        let request = PlanCreateRequest(
            userId: userId,
            name: raceName,
            goalRace: raceName,
            raceDistance: raceDistance,
            startDate: df.string(from: startDate),
            endDate: df.string(from: endDate)
        )
        
        do {
            if isModifying, let planId = existingPlan?.id {
                _ = try await APIClient.shared.updatePlan(planId: planId, request)
            } else {
                _ = try await APIClient.shared.createPlan(request)
            }
            await MainActor.run {
                isSubmitting = false
                onComplete()
            }
        } catch {
            await MainActor.run { isSubmitting = false }
            print("Plan submit error: \(error)")
        }
    }
}
