//
//  LoginView.swift
//  SnapCollab
//
//  Enhanced beautiful login screen
//

import SwiftUI

struct LoginView: View {
    @StateObject var vm: SessionViewModel
    @State private var showSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isEmailFocused = false
    @State private var isPasswordFocused = false
    @State private var animateGradient = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated Background Gradient
                AnimatedGradientBackground(animate: $animateGradient)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top Section with Logo
                        VStack(spacing: 24) {
                            Spacer(minLength: 60)
                            
                            // Logo and Title
                            VStack(spacing: 16) {
                                // Logo with gradient and shadow
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                        .blur(radius: 1)
                                    
                                    Image(systemName: "camera.aperture")
                                        .font(.system(size: 64, weight: .light))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.white, .white.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                                .scaleEffect(animateGradient ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
                                
                                VStack(spacing: 8) {
                                    Text("SnapCollab")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.white, .white.opacity(0.9)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                                }
                            }
                            
                            Spacer(minLength: 10)
                        }
                        .frame(height: geometry.size.height * 0.35)
                        
                        // Bottom Section with Form
                        VStack(spacing: 0) {
                            // Form Container
                            VStack(spacing: 24) {
                                // Form Header
                                VStack(spacing: 8) {
                                    Text(showSignUp ? "Hesap Oluştur" : "Giriş Yap")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text(showSignUp ? "SnapCollab'a hoş geldiniz" : "Tekrar hoş geldiniz")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 20)
                                
                                // Form Fields
                                VStack(spacing: 16) {
                                    // Email Field
                                    ModernTextField(
                                        text: $email,
                                        placeholder: "E-posta veya Telefon",
                                        icon: "envelope",
                                        keyboardType: .default,
                                        isFocused: $isEmailFocused
                                    )
                                    
                                    // Password Field
                                    ModernSecureField(
                                        text: $password,
                                        placeholder: "Şifre",
                                        icon: "lock",
                                        isFocused: $isPasswordFocused
                                    )

                                    // Şifremi Unuttum (sağ alta, küçük)
                                    HStack {
                                        Spacer()
                                        Button("Şifremi Unuttum") {
                                            vm.showForgotPassword = true
                                        }
                                        .font(.caption2)                // küçük yazı
                                        .foregroundColor(.blue)
                                    }
                                    .padding(.trailing, 4)

                                    
                                    // Display Name Field (Sign Up only)
                                    if showSignUp {
                                        ModernTextField(
                                            text: $displayName,
                                            placeholder: "Ad Soyad (isteğe bağlı)",
                                            icon: "person",
                                            keyboardType: .default,
                                            isFocused: .constant(false)
                                        )
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                                    }
                                }
                                
                                // Error Message
                                if let error = vm.errorMessage {
                                    ErrorMessageView(message: error)
                                }
                                
                                // Main Action Button
                                PrimaryActionButton(
                                    title: showSignUp ? "Hesap Oluştur" : "Giriş Yap",
                                    isLoading: vm.isLoading,
                                    isDisabled: email.isEmpty || password.isEmpty
                                ) {
                                    Task {
                                        if showSignUp {
                                            await vm.signUp(email: email, password: password, displayName: displayName)
                                        } else {
                                            await vm.signIn(email: email, password: password)
                                        }
                                    }
                                }
                                
                                // Toggle Sign Up/In
                                Button(action: {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        showSignUp.toggle()
                                        vm.errorMessage = nil
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Text(showSignUp ? "Zaten hesabım var" : "Hesabım yok")
                                            .font(.body)
                                        Image(systemName: "arrow.right")
                                            .font(.caption)
                                            .rotationEffect(.degrees(showSignUp ? 180 : 0))
                                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSignUp)
                                    }
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                                }
                                
                                Divider()
                                    .padding(.vertical, 10)

                                VStack(spacing: 12) {
                                    Text("Diğer yollarla devam et")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    // Google giriş
                                    Button {
                                        Task { await vm.signInWithGoogle() }
                                    } label: {
                                        HStack {
                                            Image("google")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20, height: 20)
                                            Text("Google ile Giriş Yap")
                                                .font(.footnote)
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                    }
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)

                                    // Misafir giriş
                                    Button {
                                        Task { await vm.signInAnon() }
                                    } label: {
                                        HStack {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.orange)
                                            Text("Misafir Olarak Devam Et")
                                                .font(.footnote)
                                                .foregroundColor(.orange)
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                                    )
                                }
                                .padding(.top, 8)


                                
                                Spacer(minLength: 15)
                            }
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
                            )
                            .padding(.horizontal, 16)
                        }
                        .frame(minHeight: geometry.size.height * 0.4)
                        .padding(.top, -16)
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .onAppear {
            animateGradient = true
        }
        .sheet(isPresented: $vm.showForgotPassword) {
            ForgotPasswordView(vm: vm)
        }
    }
}

// MARK: - Animated Background (tek eksen drift, koyu pastel)
struct AnimatedGradientBackground: View {
    @Binding var animate: Bool
    @State private var drift = false

    // Biraz koyu pastel palet
    private let colors: [Color] = [
        Color(red: 0.88, green: 0.64, blue: 0.80), // deeper rose
        Color(red: 0.62, green: 0.78, blue: 1.00), // deeper baby blue
        Color(red: 0.98, green: 0.78, blue: 0.56), // deeper peach
        Color(red: 0.70, green: 0.68, blue: 1.00)  // deeper lavender
    ]

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .saturation(1.2)     // hafif canlılık
                .contrast(1.10)       // biraz daha kontrast
                .scaleEffect(1.25)    // banding riskini azaltır
                .offset(
                    x: drift ? -geo.size.width * 0.08 : geo.size.width * 0.08,
                    y: 0
                )                     // sadece yatay drift
                .ignoresSafeArea()
                .animation(
                    .easeInOut(duration: 15).repeatForever(autoreverses: true),
                    value: drift
                )
                .onAppear {
                    // Kullanıcı animate geçirmese bile drift’i başlat
                    drift = true
                }
                .onChange(of: animate) { on in
                    // İstersen animate=false ile durdurabilirsin
                    drift = on
                }
        }
    }
}




// MARK: - Modern Text Field
struct ModernTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let keyboardType: UIKeyboardType
    @Binding var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isFocused ? .blue : .gray)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .font(.body)
                .onTapGesture { isFocused = true }
                .onSubmit { isFocused = false }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(
                    color: isFocused ? .blue.opacity(0.3) : .black.opacity(0.05),
                    radius: isFocused ? 8 : 4,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isFocused ? .blue : .clear,
                    lineWidth: 2
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Modern Secure Field
struct ModernSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @Binding var isFocused: Bool
    @State private var isSecured = true
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isFocused ? .blue : .gray)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            if isSecured {
                SecureField(placeholder, text: $text)
                    .font(.body)
                    .onTapGesture { isFocused = true }
                    .onSubmit { isFocused = false }
            } else {
                TextField(placeholder, text: $text)
                    .font(.body)
                    .onTapGesture { isFocused = true }
                    .onSubmit { isFocused = false }
            }
            
            Button(action: { isSecured.toggle() }) {
                Image(systemName: isSecured ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(
                    color: isFocused ? .blue.opacity(0.3) : .black.opacity(0.05),
                    radius: isFocused ? 8 : 4,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isFocused ? .blue : .clear,
                    lineWidth: 2
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Primary Action Button
struct PrimaryActionButton: View {
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
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isDisabled ? [.gray, .gray] : [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: isDisabled ? .clear : .blue.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isLoading ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}


// MARK: - Social Login Button
struct SocialLoginButton: View {
    let icon: String
    let title: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }
}

// MARK: - Error Message View
struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.caption)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.red.opacity(0.1))
        )
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
    }
}

// MARK: - Divider with Text
struct DividerWithText: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.3))
            
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .background(.regularMaterial)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.3))
        }
    }
}

#Preview {
    let mockAuthRepo = AuthRepository(
        service: FirebaseAuthService(),
        userService: FirestoreUserService()
    )
    let mockAppState = AppState()
    
    LoginView(vm: SessionViewModel(auth: mockAuthRepo, state: mockAppState))
}
