//
//  CleanLoginView.swift
//  SnapCollab
//
//  Sade ve şık login ekranı
//

import SwiftUI

struct CleanLoginView: View {
    @StateObject var vm: SessionViewModel
    @State private var showSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var showTermsSheet = false
    @State private var termsAccepted = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Simple gradient background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Logo ve başlık alanı
                        VStack(spacing: 24) {
                            Spacer(minLength: max(60, geometry.size.height * 0.1))
                            
                            // Sade logo
                            VStack(spacing: 16) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .overlay {
                                        Image(systemName: "photo.stack")
                                            .font(.system(size: 36, weight: .medium))
                                            .foregroundStyle(.white)
                                    }
                                    .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                                
                                VStack(spacing: 8) {
                                    Text("SnapCollab")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    
                                    Text("Anıları birlikte paylaşalım")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .frame(minHeight: geometry.size.height * 0.45)
                        
                        // Form alanı
                        VStack(spacing: 32) {
                            // Form başlığı
                            VStack(spacing: 8) {
                                Text(showSignUp ? "Hesap Oluştur" : "Hoş Geldiniz")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                Text(showSignUp ? "Yeni hesabınızı oluşturun" : "Hesabınıza giriş yapın")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .animation(.easeInOut(duration: 0.3), value: showSignUp)
                            
                            // Form alanları
                            VStack(spacing: 20) {
                                // Email
                                CleanTextField(
                                    text: $email,
                                    placeholder: "E-posta",
                                    icon: "envelope",
                                    keyboardType: .emailAddress
                                )
                                
                                // Şifre
                                CleanSecureField(
                                    text: $password,
                                    placeholder: "Şifre",
                                    icon: "lock"
                                )
                                
                                // Kayıt olurken isim alanı
                                if showSignUp {
                                    CleanTextField(
                                        text: $displayName,
                                        placeholder: "Ad Soyad (isteğe bağlı)",
                                        icon: "person",
                                        keyboardType: .default
                                    )
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                                    
                                    // Terms checkbox
                                    HStack(spacing: 12) {
                                        Button(action: { termsAccepted.toggle() }) {
                                            Image(systemName: termsAccepted ? "checkmark.square.fill" : "square")
                                                .font(.title2)
                                                .foregroundStyle(termsAccepted ? .blue : .gray)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 4) {
                                                Text("Kabul ediyorum:")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            HStack(spacing: 8) {
                                                Button("Kullanım Koşulları") {
                                                    showTermsSheet = true
                                                }
                                                .font(.caption)
                                                .foregroundStyle(.blue)
                                                
                                                Text("ve")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                
                                                Button("Gizlilik Politikası") {
                                                    showTermsSheet = true
                                                }
                                                .font(.caption)
                                                .foregroundStyle(.blue)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                            
                            // Hata mesajı
                            if let error = vm.errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.caption)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.orange.opacity(0.1))
                                )
                            }
                            
                            // Ana buton
                            CleanButton(
                                title: showSignUp ? "Hesap Oluştur" : "Giriş Yap",
                                isLoading: vm.isLoading,
                                isDisabled: !isFormValid
                            ) {
                                Task {
                                    if showSignUp {
                                        await vm.signUp(email: email, password: password, displayName: displayName)
                                    } else {
                                        await vm.signIn(email: email, password: password)
                                    }
                                }
                            }
                            
                            // Şifremi unuttum (sadece giriş ekranında)
                            if !showSignUp {
                                Button("Şifremi Unuttum") {
                                    vm.resetEmail = email
                                    vm.showForgotPassword = true
                                }
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                            }
                            
                            // Hesap değiştirme
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSignUp.toggle()
                                    vm.errorMessage = nil
                                    // Terms'i sıfırla
                                    termsAccepted = false
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(showSignUp ? "Zaten hesabım var" : "Hesap oluştur")
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                }
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                            }
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundStyle(.secondary.opacity(0.3))
                                Text("veya")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundStyle(.secondary.opacity(0.3))
                            }
                            .padding(.top, 8)
                            
                            // Sosyal giriş butonları
                            VStack(spacing: 12) {
                                CleanSocialButton(
                                    title: "Google ile Devam Et",
                                    icon: "globe",
                                    isLoading: vm.isLoading
                                ) {
                                    Task { await vm.signInWithGoogle() }
                                }
                                
                                CleanSocialButton(
                                    title: "Misafir Olarak Devam Et",
                                    icon: "person.crop.circle",
                                    isLoading: vm.isLoading,
                                    color: .orange
                                ) {
                                    Task { await vm.signInAnon() }
                                }
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .sheet(isPresented: $vm.showForgotPassword) {
            ForgotPasswordView(vm: vm)
        }
        .sheet(isPresented: $showTermsSheet) {
            TermsAcceptanceSheet(termsAccepted: $termsAccepted)
        }
    }
    
    // Form validasyon
    private var isFormValid: Bool {
        let baseValid = !email.isEmpty && !password.isEmpty
        if showSignUp {
            return baseValid && termsAccepted
        }
        return baseValid
    }
}

// MARK: - Clean Text Field
struct CleanTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let keyboardType: UIKeyboardType
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundStyle(isFocused ? .blue : .secondary)
                .font(.system(size: 18))
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .autocorrectionDisabled(keyboardType == .emailAddress)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? .blue : .clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Clean Secure Field
struct CleanSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @FocusState private var isFocused: Bool
    @State private var isSecured = true
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundStyle(isFocused ? .blue : .secondary)
                .font(.system(size: 18))
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            if isSecured {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
            }
            
            Button(action: { isSecured.toggle() }) {
                Image(systemName: isSecured ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 16))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? .blue : .clear, lineWidth: 2)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Clean Button
struct CleanButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDisabled ? .gray : .blue)
            )
        }
        .disabled(isDisabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - Clean Social Button
struct CleanSocialButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let color: Color
    let action: () -> Void
    
    init(title: String, icon: String, isLoading: Bool, color: Color = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                
                Text(title)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                    )
            )
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
    }
}

// MARK: - Terms Acceptance Sheet
struct TermsAcceptanceSheet: View {
    @Binding var termsAccepted: Bool
    @Environment(\.dismiss) var dismiss
    @State private var showTerms = false
    @State private var showPrivacy = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Kullanım Koşulları")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("SnapCollab'ı kullanmak için aşağıdaki koşulları kabul etmeniz gerekir")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    Button(action: { showTerms = true }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.blue)
                            Text("Kullanım Koşullarını Oku")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    Button(action: { showPrivacy = true }) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundStyle(.green)
                            Text("Gizlilik Politikasını Oku")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                .padding(.horizontal)
                
                VStack(spacing: 16) {
                    Button("Kabul Ediyorum") {
                        termsAccepted = true
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("İptal") {
                        termsAccepted = false
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .fullScreenCover(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .fullScreenCover(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }
}
