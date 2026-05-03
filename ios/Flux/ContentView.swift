import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var healthKit = HealthKitManager()
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
            
            PlanView()
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }
            
            RecoveryView(healthKit: healthKit)
                .tabItem {
                    Label("Recovery", systemImage: "heart")
                }
            
            TrainingLogView()
                .tabItem {
                    Label("Log", systemImage: "book")
                }
            
            SettingsView(healthKit: healthKit)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(Color("AccentBlue"))
        .onAppear {
            healthKit.requestAuthorization()
        }
    }
}
