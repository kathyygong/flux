import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var healthKit: HealthKitManager
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Text(initials)
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.userName ?? "Runner")
                                .font(.headline)
                            Text(appState.userEmail ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Health Integration
                Section("Health Integration") {
                    HStack {
                        Label("Apple Health", systemImage: "heart.fill")
                            .foregroundColor(.red)
                        Spacer()
                        if healthKit.isAuthorized {
                            Text("Connected")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Button("Connect") {
                                healthKit.requestAuthorization()
                            }
                            .font(.caption.bold())
                        }
                    }
                    
                    if healthKit.isAuthorized {
                        Button {
                            Task {
                                guard let userId = appState.userId else { return }
                                await healthKit.syncToBackend(userId: userId)
                            }
                        } label: {
                            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                }
                
                // App Info
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://flux.run")!) {
                        Label("Website", systemImage: "globe")
                    }
                }
                
                // Logout
                Section {
                    Button(role: .destructive) {
                        appState.logout()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var initials: String {
        guard let name = appState.userName else { return "?" }
        return name.components(separatedBy: " ")
            .compactMap { $0.first }
            .map(String.init)
            .prefix(2)
            .joined()
            .uppercased()
    }
}
