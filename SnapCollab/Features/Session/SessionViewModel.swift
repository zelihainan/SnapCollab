
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
        print("SessionVM: syncInitialState - auth.isSignedIn: \(auth.isSignedIn)")
        state.isSignedIn = auth.isSignedIn
        state.currentUser = auth.currentUser
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await auth.signIn(email: email, password: password)
            state.isSignedIn = true
            state.currentUser = auth.currentUser
        } catch {
            handleAuthError(error)
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
                
        do {
            try await auth.signUp(email: email, password: password, displayName: displayName)
            state.isSignedIn = true
            state.currentUser = auth.currentUser
        } catch {
            handleAuthError(error)
        }
    }
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await auth.signInWithGoogle()
            state.isSignedIn = true
            state.currentUser = auth.currentUser
        } catch {
            handleAuthError(error)
        }
    }
    
    func signInAnon() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await auth.signInAnon()
            state.isSignedIn = true
            state.currentUser = auth.currentUser
        } catch {
            handleAuthError(error)
        }
    }
    
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
        print("SessionVM: signOut called")
        do {
            try auth.signOut()
            print("SessionVM: auth.signOut() successful")
            
            state.isSignedIn = false
            state.currentUser = nil
            print("SessionVM: AppState updated - isSignedIn: \(state.isSignedIn)")
            
        } catch {
            print("SessionVM: signOut error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleAuthError(_ error: Error) {
        let nsError = error as NSError
        
        switch nsError.code {
        case 17007:
            errorMessage = "Bu e-posta adresi zaten kullanımda"
        case 17008:
            errorMessage = "Geçersiz e-posta adresi"
        case 17026:
            errorMessage = "Şifre en az 6 karakter olmalı"
        case 17009:
            errorMessage = "Yanlış şifre"
        case 17011:
            errorMessage = "Kullanıcı bulunamadı"
        case 17020:
            errorMessage = "İnternet bağlantınızı kontrol ediniz"
        default:
            errorMessage = nsError.localizedDescription
        }
    }
}
