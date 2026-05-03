import SwiftUI

@main
struct FluxApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.isAuthenticated {
                ContentView()
                    .environmentObject(appState)
            } else {
                LoginView()
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - Global App State
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userId: Int?
    @Published var userEmail: String?
    @Published var userName: String?
    
    init() {
        // Check for saved session
        if let savedId = UserDefaults.standard.object(forKey: "userId") as? Int {
            self.userId = savedId
            self.userEmail = UserDefaults.standard.string(forKey: "userEmail")
            self.userName = UserDefaults.standard.string(forKey: "userName")
            self.isAuthenticated = true
        }
    }
    
    func login(id: Int, email: String, name: String?) {
        self.userId = id
        self.userEmail = email
        self.userName = name
        self.isAuthenticated = true
        UserDefaults.standard.set(id, forKey: "userId")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(name, forKey: "userName")
    }
    
    func logout() {
        self.userId = nil
        self.userEmail = nil
        self.userName = nil
        self.isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userName")
    }
}
