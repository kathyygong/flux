import SwiftUI

struct TrainingLogView: View {
    @EnvironmentObject var appState: AppState
    @State private var logItems: [TrainingLogItem] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if logItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No training history yet")
                            .font(.headline)
                        Text("Complete your first workout to see it here!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(logItems) { item in
                                logRow(item)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Training Log")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await loadLog() }
        }
        .task { await loadLog() }
    }
    
    private func logRow(_ item: TrainingLogItem) -> some View {
        let itemDate = ISO8601DateFormatter().date(from: item.date) ?? Date()
        let isPast = itemDate < Calendar.current.startOfDay(for: Date())
        let isMissed = isPast && item.status == "scheduled"
        let isAdapted = item.status == "adapted" || item.status == "accepted"
        
        return HStack(spacing: 14) {
            // Status Icon
            Group {
                if item.status == "completed" {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if isAdapted {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(.purple)
                } else if isMissed {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                }
            }
            .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(formatDate(itemDate))
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    if isAdapted {
                        Text("SMART ADAPT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                Text(item.title)
                    .font(.subheadline.bold())
                
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isMissed ? 0.5 : 1.0)
        .overlay(
            isAdapted ?
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 2)
                    .padding(1)
            : nil
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d"
        return df.string(from: date)
    }
    
    private func loadLog() async {
        guard let userId = appState.userId else { return }
        do {
            let response = try await APIClient.shared.fetchDashboard(userId: userId)
            await MainActor.run {
                logItems = response.data.trainingLog ?? []
                isLoading = false
            }
        } catch {
            isLoading = false
        }
    }
}
