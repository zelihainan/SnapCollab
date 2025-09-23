//
//  ModernLoginView.swift
//  SnapCollab
//

import SwiftUI

struct ModernLoginView: View {
    @StateObject var vm: SessionViewModel
    @State private var showSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var confirmPassword = ""
    @State private var showTermsSheet = false
    @State private var termsAccepted = false
    @State private var animateBackground = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark Gradient Background
                LinearGradient(
                    colors: [
                        Color(.systemBlue).opacity(0.9),
                        Color(.systemIndigo).opacity(0.8),
                        Color(.systemPurple).opacity(0.7),
                        Color(.systemBackground).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .scaleEffect(animateBackground ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateBackground)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with SnapCollab Title
                        VStack {
                            Spacer()
                                .frame(height: 70)
                            
                            // SnapCollab Title with AlbertSans
                            HStack(spacing: 0) {
                                Text("Snap")
                                    .font(.custom("AlbertSans-Regular", size: 44))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                
                                Text("Collab")
                                    .font(.custom("AlbertSans-Regular", size: 44))
                                    .fontWeight(.light)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Spacer()
                                .frame(height: 50)
                        }
                        
                        // Main Form Card
                        VStack(spacing: 0) {
                            VStack(spacing: 20) {
                                // Welcome Title
                                Text(showSignUp ? "Hesap Oluştur" : "Hoş Geldiniz")
                                    .font(.custom("AlbertSans-Regular", size: 26))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                    .padding(.top, 24)
                                    .animation(.easeInOut(duration: 0.3), value: showSignUp)
                                
                                // Form Fields
                                VStack(spacing: 14) {
                                    // Display Name (only for sign up - first field)
                                    if showSignUp {
                                        ModernTextField(
                                            text: $displayName,
                                            placeholder: "Ad Soyad",
                                            icon: "person.circle.fill",
                                            keyboardType: .default
                                        )
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .top).combined(with: .opacity),
                                            removal: .move(edge: .top).combined(with: .opacity)
                                        ))
                                    }
                                    
                                    // Email Input
                                    ModernTextField(
                                        text: $email,
                                        placeholder: "E-posta",
                                        icon: "envelope.circle.fill",
                                        keyboardType: .emailAddress
                                    )
                                    
                                    // Password Field
                                    ModernSecureField(
                                        text: $password,
                                        placeholder: "Şifre",
                                        showForgotPassword: !showSignUp,
                                        onForgotPassword: {
                                            vm.resetEmail = email
                                            vm.showForgotPassword = true
                                        }
                                    )
                                    
                                    // Confirm Password (only for sign up)
                                    if showSignUp {
                                        ModernSecureField(
                                            text: $confirmPassword,
                                            placeholder: "Şifre Tekrar",
                                            showForgotPassword: false,
                                            onForgotPassword: {}
                                        )
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .bottom).combined(with: .opacity),
                                            removal: .move(edge: .top).combined(with: .opacity)
                                        ))
                                    }
                                }
                                
                                // Terms & Conditions (only for sign up)
                                if showSignUp {
                                    TermsAcceptanceView(
                                        termsAccepted: $termsAccepted,
                                        showTermsSheet: $showTermsSheet
                                    )
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                                }
                                
                                // Error Message
                                if let error = vm.errorMessage {
                                    ErrorMessageView(message: error)
                                }
                                
                                // Main Action Button
                                ModernButton(
                                    title: showSignUp ? "Hesap Oluştur" : "Giriş Yap",
                                    isLoading: vm.isLoading,
                                    isDisabled: !isFormValid,
                                    style: .primary
                                ) {
                                    Task {
                                        await handleAuthentication()
                                    }
                                }
                                
                                // Toggle Sign Up/Sign In
                                Button(action: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        showSignUp.toggle()
                                        clearForm()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Text(showSignUp ? "Zaten hesabım var" : "Hesap oluştur")
                                            .font(.custom("AlbertSans-Regular", size: 15))
                                            .fontWeight(.medium)
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundStyle(.blue)
                                }
                                
                                // Google Sign In
                                ModernButton(
                                    title: "Google ile Devam Et",
                                    isLoading: false,
                                    isDisabled: vm.isLoading,
                                    style: .google,
                                    icon: "google"
                                ) {
                                    Task { await vm.signInWithGoogle() }
                                }
                                
                                Spacer(minLength: 30)
                            }
                            .padding(.horizontal, 28)
                            .padding(.bottom, 40)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(.regularMaterial)
                                .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: -8)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .padding(.horizontal, 14)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .onAppear {
            animateBackground = true
        }
        .sheet(isPresented: $vm.showForgotPassword) {
            ForgotPasswordView(vm: vm)
        }
    }
    
    // MARK: - Helper Properties
    private var isFormValid: Bool {
        let baseValid = !email.isEmpty && vm.isValidEmail(email)
        
        if showSignUp {
            let nameValid = !displayName.isEmpty
            let passwordValid = !password.isEmpty && password.count >= 6
            let passwordMatch = password == confirmPassword
            let termsValid = termsAccepted
            
            return nameValid && baseValid && passwordValid && passwordMatch && termsValid
        } else {
            return baseValid && !password.isEmpty
        }
    }
    
    // MARK: - Helper Methods
    private func handleAuthentication() async {
        if showSignUp {
            await vm.signUp(email: email, password: password, displayName: displayName)
        } else {
            await vm.signIn(email: email, password: password)
        }
    }
    
    private func clearForm() {
        vm.errorMessage = nil
        termsAccepted = false
        password = ""
        confirmPassword = ""
        if showSignUp {
            displayName = ""
        }
    }
}

// MARK: - Modern Text Field Component
struct ModernTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let keyboardType: UIKeyboardType
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(isFocused ? .blue : .secondary)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 22)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            TextField(placeholder, text: $text)
                .font(.custom("AlbertSans-Regular", size: 16))
                .focused($isFocused)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .autocorrectionDisabled(keyboardType == .emailAddress)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isFocused ? .blue : .clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Modern Secure Field Component
struct ModernSecureField: View {
    @Binding var text: String
    let placeholder: String
    let showForgotPassword: Bool
    let onForgotPassword: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var isSecured = true
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: "lock.circle.fill")
                    .foregroundStyle(isFocused ? .blue : .secondary)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 22)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                if isSecured {
                    SecureField(placeholder, text: $text)
                        .font(.custom("AlbertSans-Regular", size: 16))
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.custom("AlbertSans-Regular", size: 16))
                        .focused($isFocused)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSecured.toggle()
                    }
                }) {
                    Image(systemName: isSecured ? "eye.slash.circle" : "eye.circle")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isFocused ? .blue : .clear, lineWidth: 2)
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            if showForgotPassword {
                HStack {
                    Spacer()
                    Button("Şifremi unuttum") {
                        onForgotPassword()
                    }
                    .font(.custom("AlbertSans-Regular", size: 12))
                    .foregroundStyle(.blue)
                }
                .padding(.trailing, 2)
            }
        }
    }
}

// MARK: - Modern Button Component
struct ModernButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let style: ButtonStyle
    var icon: String? = nil
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, google
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        if icon == "google" {
                            Circle()
                                .fill(.white)
                                .frame(width: 18, height: 18)
                                .overlay {
                                    Text("G")
                                        .font(.custom("AlbertSans-Regular", size: 11))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)
                                }
                        } else {
                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    
                    Text(title)
                        .font(.custom("AlbertSans-Regular", size: 16))
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor)
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            )
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isDisabled ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .animation(.easeInOut(duration: 0.1), value: isDisabled)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isDisabled ? .gray.opacity(0.6) : .blue
        case .google:
            return Color(.systemBackground)
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .google:
            return .primary
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary:
            return .blue.opacity(0.3)
        case .google:
            return .black.opacity(0.1)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .primary:
            return isDisabled ? 2 : 6
        case .google:
            return 4
        }
    }
    
    private var shadowY: CGFloat {
        switch style {
        case .primary:
            return isDisabled ? 1 : 3
        case .google:
            return 2
        }
    }
}

// MARK: - Terms Acceptance Component
struct TermsAcceptanceView: View {
    @Binding var termsAccepted: Bool
    @Binding var showTermsSheet: Bool
    @State private var showTerms = false
    @State private var showPrivacy = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    termsAccepted.toggle()
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(termsAccepted ? .blue : .gray, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(termsAccepted ? .blue : .clear)
                        )
                    
                    if termsAccepted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.top, 1)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Aşağıdaki şartları kabul ediyorum:")
                    .font(.custom("AlbertSans-Regular", size: 13))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 3) {
                    Button("Kullanım Koşulları") {
                        showTerms = true
                    }
                    .font(.custom("AlbertSans-Regular", size: 13))
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                    
                    Text("ve")
                        .font(.custom("AlbertSans-Regular", size: 13))
                        .foregroundStyle(.secondary)
                    
                    Button("Gizlilik Politikası") {
                        showPrivacy = true
                    }
                    .font(.custom("AlbertSans-Regular", size: 13))
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 2)
        .fullScreenCover(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .fullScreenCover(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }
}

// MARK: - Error Message Component
struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 14))
            
            Text(message)
                .font(.custom("AlbertSans-Regular", size: 12))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
