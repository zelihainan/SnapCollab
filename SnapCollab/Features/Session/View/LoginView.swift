//
//  CleanLoginView.swift
//  SnapCollab
//
//  Completely rewritten with all requested changes
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
                        // Logo alanı - daha yukarıda
                        VStack(spacing: 20) {
                            Spacer(minLength: max(80, geometry.size.height * 0.15))
                            
                            // SnapCollab Logo - dengeli font weight'ler
                            HStack(spacing: 2) {
                                // "Snap" - Orta kalın
                                Text("Snap")
                                    .font(.system(size: 44, weight: .bold, design: .default))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                // "Collab" - Light (dengeli ince)
                                Text("Collab")
                                    .font(.system(size: 44, weight: .light, design: .default))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            .shadow(color: .blue.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        .frame(minHeight: geometry.size.height * 0.32)
                        
                        // Form alanı - daha aşağıda güzel şekilde
                        VStack(spacing: 36) {
                            // Form başlığı - büyük ve güzel
                            VStack(spacing: 12) {
                                Text(showSignUp ? "Hesap Oluştur" : "Hoş Geldiniz")
                                    .font(.system(size: 28, weight: .semibold, design: .default))
                                    .foregroundStyle(.primary)
                                
                                Text(showSignUp ? "Yeni hesabınızı oluşturun" : "Hesabınıza giriş yapın")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .animation(.easeInOut(duration: 0.3), value: showSignUp)
                            .padding(.top, 25)
                            
                            // Form alanları
                            VStack(spacing: 20) {
                                // Email/Telefon - çift ikon
                                VStack(spacing: 16) {
                                    HStack(spacing: 16) {
                                        // Çift ikon - email ve telefon
                                        HStack(spacing: 6) {
                                            Image(systemName: "envelope")
                                                .font(.system(size: 16))
                                            Image(systemName: "phone")
                                                .font(.system(size: 16))
                                        }
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                        
                                        TextField("E-posta veya telefon", text: $email)
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.systemGray6))
                                    )
                                }
                                
                                // Şifre alanı + şifremi unuttum
                                VStack(alignment: .trailing, spacing: 8) {
                                    CleanSecureField(
                                        text: $password,
                                        placeholder: "Şifre",
                                        icon: "lock"
                                    )
                                    
                                    // Şifremi unuttum - sağ altta küçük
                                    if !showSignUp {
                                        HStack {
                                            Spacer()
                                            Button("Şifremi unuttum") {
                                                vm.resetEmail = email
                                                vm.showForgotPassword = true
                                            }
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                        }
                                        .padding(.trailing, 4)
                                    }
                                }
                                
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
                            
                            // Hesap değiştirme
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSignUp.toggle()
                                    vm.errorMessage = nil
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
                            
                            // Güzelleştirilmiş sosyal giriş butonları
                            VStack(spacing: 12) {
                                // Google Button - assets'teki google.png ile
                                Button(action: {
                                    Task { await vm.signInWithGoogle() }
                                }) {
                                    HStack(spacing: 12) {
                                        Image("google")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 20, height: 20)
                                        
                                        Text("Google ile Devam Et")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(.primary)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.gray.opacity(0.15), lineWidth: 1)
                                    )
                                }
                                .disabled(vm.isLoading)
                                .scaleEffect(vm.isLoading ? 0.98 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: vm.isLoading)
                                
                                // Misafir Button - sade gri tonlarda (turuncu değil)
                                Button(action: {
                                    Task { await vm.signInAnon() }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.crop.circle")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(.secondary)
                                        
                                        Text("Misafir Olarak Devam Et")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(.primary)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.secondarySystemBackground))
                                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.gray.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .disabled(vm.isLoading)
                                .scaleEffect(vm.isLoading ? 0.98 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: vm.isLoading)
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
