import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isSignup = false
    @State private var isLoading = false
    @State private var isGoogleLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Fluid gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.95, blue: 1.0),
                    Color(red: 0.96, green: 0.93, blue: 1.0),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo
                VStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 56, weight: .thin))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    
                    Text("Flux")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .tracking(-2)
                    
                    Text("Adaptive Training, Reimagined")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .textContentType(isSignup ? .newPassword : .password)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Email/Password Button
                    Button {
                        Task { await authenticate() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSignup ? "Create Account" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    
                    // Divider
                    HStack {
                        Rectangle().fill(Color(.separator)).frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Rectangle().fill(Color(.separator)).frame(height: 1)
                    }
                    .padding(.vertical, 4)
                    
                    // Google Sign In
                    Button {
                        Task { await googleSignIn() }
                    } label: {
                        HStack(spacing: 10) {
                            if isGoogleLoading {
                                ProgressView()
                                    .tint(.primary)
                            } else {
                                Image(systemName: "globe")
                                    .font(.body.bold())
                            }
                            Text("Continue with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                    }
                    .disabled(isGoogleLoading)
                    
                    // Toggle signup/login
                    Button {
                        isSignup.toggle()
                        errorMessage = nil
                    } label: {
                        Text(isSignup ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                Spacer()
            }
        }
    }
    
    // MARK: - Email/Password Auth
    private func authenticate() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: AuthResponse
            if isSignup {
                response = try await APIClient.shared.signup(email: email, password: password)
            } else {
                response = try await APIClient.shared.login(email: email, password: password)
            }
            
            await MainActor.run {
                appState.login(id: response.data.id, email: response.data.email, name: response.data.fullName)
                isLoading = false
            }
        } catch let error as APIError {
            await MainActor.run {
                errorMessage = error.errorDescription
                isLoading = false
            }
        } catch {
            await MainActor.run {
                if isSignup {
                    errorMessage = "Could not create account. Email may already be registered."
                } else {
                    errorMessage = "Invalid email or password."
                }
                isLoading = false
            }
        }
    }
    
    // MARK: - Google Sign In (via ASWebAuthenticationSession)
    private func googleSignIn() async {
        isGoogleLoading = true
        errorMessage = nil
        
        // The backend OAuth endpoint redirects back with user data in the URL
        let authURL = APIClient.shared.googleAuthURL
        
        await MainActor.run {
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "flux"
            ) { callbackURL, error in
                isGoogleLoading = false
                
                if let error = error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        return // User cancelled, not an error
                    }
                    errorMessage = "Google sign-in failed."
                    return
                }
                
                guard let url = callbackURL,
                      let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    errorMessage = "Invalid callback."
                    return
                }
                
                // Parse user data from callback URL params
                let params = Dictionary(uniqueKeysWithValues:
                    components.queryItems?.map { ($0.name, $0.value ?? "") } ?? []
                )
                
                if let idStr = params["user_id"], let id = Int(idStr) {
                    let email = params["email"] ?? ""
                    let name = params["full_name"]
                    appState.login(id: id, email: email, name: name)
                } else {
                    errorMessage = "Could not complete Google sign-in."
                }
            }
            
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = GoogleAuthPresentationContext.shared
            session.start()
        }
    }
}

// MARK: - Presentation Context for ASWebAuthenticationSession
class GoogleAuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = GoogleAuthPresentationContext()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
