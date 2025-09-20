//
//  SessionViewModel.swift - Updated with Phone Support
//  SnapCollab
//

import Foundation
import FirebaseAuth

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showForgotPassword = false
    @Published var resetEmail = ""
    @Published var resetSuccess = false
    @Published var verificationID: String?
    @Published var verificationCode = ""
    @Published var showVerificationCode = false
    @Published var phoneNumber = ""

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

    // MARK: - Email Authentication
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
    
    // MARK: - Phone Authentication
    func signInWithPhone(phone: String, password: String) async {
        // For now, we'll use a custom authentication system
        // In a real app, you'd implement Firebase Phone Auth
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Convert phone to email format for Firebase compatibility
            let phoneEmail = phoneToEmail(phone)
            try await auth.signIn(email: phoneEmail, password: password)
            state.isSignedIn = true
            state.currentUser = auth.currentUser
        } catch {
            handleAuthError(error)
        }
    }
    
    func signUpWithPhone(phone: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Convert phone to email format for Firebase compatibility
            let phoneEmail = phoneToEmail(phone)
            try await auth.signUp(email: phoneEmail, password: password, displayName: displayName)
            state.isSignedIn = true
            state.currentUser = auth.currentUser
        } catch {
            handleAuthError(error)
        }
    }
    
    // MARK: - Firebase Phone Auth (Optional - for SMS verification)
    func sendVerificationCode(to phoneNumber: String) async {
        isLoading = true
        errorMessage = nil
        self.phoneNumber = phoneNumber
        
        do {
            let verificationID = try await PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            await MainActor.run {
                self.verificationID = verificationID
                self.showVerificationCode = true
            }
        } catch {
            await MainActor.run {
                self.handleAuthError(error)
            }
        }
        
        isLoading = false
    }
    
    func verifyCode(_ code: String) async {
        guard let verificationID = verificationID else {
            errorMessage = "Doğrulama kodu bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationID,
                verificationCode: code
            )
            
            let result = try await Auth.auth().signIn(with: credential)
            
            // Create user profile if needed
            let user = result.user
            let snapUser = User(
                uid: user.uid,
                email: user.phoneNumber ?? "",
                displayName: user.displayName,
                photoURL: user.photoURL?.absoluteString
            )
            
            // Save to Firestore
            let userService = FirestoreUserService()
            try await userService.createUser(snapUser)
            
            await MainActor.run {
                self.state.isSignedIn = true
                self.state.currentUser = self.auth.currentUser
                self.showVerificationCode = false
                self.verificationCode = ""
                self.verificationID = nil
            }
            
        } catch {
            await MainActor.run {
                self.handleAuthError(error)
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Google Authentication
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
    
    // MARK: - Password Reset
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

    // MARK: - Sign Out
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
    
    // MARK: - Helper Methods
    private func phoneToEmail(_ phoneNumber: String) -> String {
        // Convert phone number to email format for Firebase compatibility
        // Remove + and other characters, then add domain
        let cleanPhone = phoneNumber.replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        return "\(cleanPhone)@phone.snapcollab.local"
    }
    
    private func handleAuthError(_ error: Error) {
        let nsError = error as NSError
        
        switch nsError.code {
        case 17007:
            errorMessage = "Bu telefon numarası veya e-posta adresi zaten kullanımda"
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
        case 17044:
            errorMessage = "Geçersiz doğrulama kodu"
        case 17048:
            errorMessage = "Geçersiz telefon numarası"
        case 17052:
            errorMessage = "Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin"
        default:
            // Check if it's a phone-related error
            if nsError.localizedDescription.contains("phone") {
                errorMessage = "Telefon numarası doğrulamasında hata oluştu"
            } else {
                errorMessage = nsError.localizedDescription
            }
        }
    }
    
    // MARK: - Validation Helpers
    func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let cleanPhone = phoneNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "+", with: "")
        
        return cleanPhone.allSatisfy { $0.isNumber } && cleanPhone.count >= 10
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Reset Methods
    func resetVerificationState() {
        verificationID = nil
        verificationCode = ""
        showVerificationCode = false
        phoneNumber = ""
    }
}
