import Foundation

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showForgotPassword = false
    @Published var resetEmail = ""
    @Published var resetSuccess = false

    private let auth: AuthRepository
    private let state: AppState

    init(auth: AuthRepository, state: AppState) {
        self.auth = auth
        self.state = state
    }
    
    func syncInitialState() {
        state.isSignedIn = auth.isSignedIn
    }

    // Email/Password Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await auth.signIn(email: email, password: password)
            state.isSignedIn = true
        } catch {
            handleAuthError(error)
        }
    }
    
    // Email/Password Sign Up
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await auth.signUp(email: email, password: password, displayName: displayName)
            state.isSignedIn = true
        } catch {
            handleAuthError(error)
        }
    }
    
    // Google Sign In
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await auth.signInWithGoogle()
            state.isSignedIn = true
        } catch {
            handleAuthError(error)
        }
    }
    
    // Anonymous Sign In (mevcut)
    func signInAnon() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await auth.signInAnon()
            state.isSignedIn = true
        } catch {
            handleAuthError(error)
        }
    }
    
    // Password Reset
    func resetPassword() async {
        guard !resetEmail.isEmpty else {
            errorMessage = "E-posta adresini giriniz"
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await auth.resetPassword(email: resetEmail)
            resetSuccess = true
        } catch {
            handleAuthError(error)
        }
    }

    func signOut() {
        do {
            try auth.signOut()
            state.isSignedIn = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleAuthError(_ error: Error) {
        let nsError = error as NSError
        
        switch nsError.code {
        case 17007: // Email already in use
            errorMessage = "Bu e-posta adresi zaten kullanımda"
        case 17008: // Invalid email
            errorMessage = "Geçersiz e-posta adresi"
        case 17026: // Weak password
            errorMessage = "Şifre en az 6 karakter olmalı"
        case 17009: // Wrong password
            errorMessage = "Yanlış şifre"
        case 17011: // User not found
            errorMessage = "Kullanıcı bulunamadı"
        case 17020: // Network error
            errorMessage = "İnternet bağlantınızı kontrol ediniz"
        default:
            errorMessage = nsError.localizedDescription
        }
    }
}
