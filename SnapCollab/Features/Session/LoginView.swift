//
//  ModernLoginView.swift
//  SnapCollab
//

import SwiftUI

struct ModernLoginView: View {
    @StateObject var vm: SessionViewModel
    @State private var showSignUp = false
    @State private var emailOrPhone = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var confirmPassword = ""
    @State private var selectedCountryCode = CountryCode.turkey
    @State private var showCountryPicker = false
    @State private var showTermsSheet = false
    @State private var termsAccepted = false
    @State private var animateBackground = false
    @State private var verificationCode = ""
    
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
                        
                        // Compact Main Form Card
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
                                    
                                    // Smart Email/Phone Input
                                    SmartInputField(
                                        text: $emailOrPhone,
                                        selectedCountryCode: $selectedCountryCode,
                                        showCountryPicker: $showCountryPicker,
                                        placeholder: "E-posta veya telefon"
                                    )
                                    
                                    // Password Field (only for email login/signup)
                                    if !isPhoneNumber || showSignUp {
                                        ModernSecureField(
                                            text: $password,
                                            placeholder: showSignUp ? "Şifre" : "Şifre",
                                            showForgotPassword: !showSignUp && !isPhoneNumber,
                                            onForgotPassword: {
                                                vm.resetEmail = emailOrPhone
                                                vm.showForgotPassword = true
                                            }
                                        )
                                    }
                                    
                                    // Confirm Password (only for email sign up)
                                    if showSignUp && !isPhoneNumber {
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
                                    
                                    // Verification Code (only for phone and when verification is shown)
                                    if isPhoneNumber && vm.showVerificationCode {
                                        ModernTextField(
                                            text: $verificationCode,
                                            placeholder: "Doğrulama Kodu",
                                            icon: "number.circle.fill",
                                            keyboardType: .numberPad
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
                                    title: getButtonTitle(),
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
                                
                                // Google Sign In (more compact)
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
        .sheet(isPresented: $showCountryPicker) {
            CountryCodePicker(selectedCountryCode: $selectedCountryCode)
        }
    }
    
    // MARK: - Helper Properties
    private var isPhoneNumber: Bool {
        isValidPhoneNumber(emailOrPhone)
    }
    
    private var isFormValid: Bool {
        let baseValid = !emailOrPhone.isEmpty
        
        if showSignUp {
            let nameValid = !displayName.isEmpty
            let termsValid = termsAccepted
            
            if isPhoneNumber {
                return nameValid && baseValid && termsValid
            } else {
                return nameValid && baseValid && !password.isEmpty &&
                       password == confirmPassword && password.count >= 6 && termsValid
            }
        } else {
            if isPhoneNumber {
                if vm.showVerificationCode {
                    return baseValid && !verificationCode.isEmpty
                } else {
                    return baseValid
                }
            } else {
                return baseValid && !password.isEmpty
            }
        }
    }
    
    private func getButtonTitle() -> String {
        if showSignUp {
            return "Hesap Oluştur"
        } else {
            if isPhoneNumber {
                if vm.showVerificationCode {
                    return "Doğrula"
                } else {
                    return "SMS Gönder"
                }
            } else {
                return "Giriş Yap"
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleAuthentication() async {
        if isPhoneNumber {
            if showSignUp {
                // Phone signup - send SMS
                let fullPhone = selectedCountryCode.code + cleanPhoneNumber(emailOrPhone)
                await vm.sendVerificationCode(to: fullPhone)
            } else {
                if vm.showVerificationCode {
                    // Verify code
                    await vm.verifyCode(verificationCode)
                } else {
                    // Send verification code - Firebase test number handling
                    let fullPhone = selectedCountryCode.code + cleanPhoneNumber(emailOrPhone)
                    
                    // Check if it's the test number
                    if fullPhone == "+905551234567" {
                        // For test number, use test verification method
                        vm.verificationCode = "111111"
                        vm.showVerificationCode = true
                    } else {
                        await vm.sendVerificationCode(to: fullPhone)
                    }
                }
            }
        } else {
            // Email authentication
            if showSignUp {
                await vm.signUp(email: emailOrPhone, password: password, displayName: displayName)
            } else {
                await vm.signIn(email: emailOrPhone, password: password)
            }
        }
    }
    
    private func clearForm() {
        vm.errorMessage = nil
        vm.resetVerificationState()
        termsAccepted = false
        password = ""
        confirmPassword = ""
        verificationCode = ""
        if showSignUp {
            displayName = ""
        }
    }
    
    private func isValidPhoneNumber(_ input: String) -> Bool {
        let cleanInput = cleanPhoneNumber(input)
        // Simplified: if it starts with digit and has at least 7 digits, consider it phone
        return cleanInput.first?.isNumber == true && cleanInput.count >= 7
    }
    
    private func cleanPhoneNumber(_ input: String) -> String {
        return input.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "+", with: "")
    }
}

// MARK: - Smart Input Field Component
struct SmartInputField: View {
    @Binding var text: String
    @Binding var selectedCountryCode: CountryCode
    @Binding var showCountryPicker: Bool
    let placeholder: String
    
    @FocusState private var isFocused: Bool
    @State private var inputType: InputType = .unknown
    
    enum InputType {
        case unknown, email, phone
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Dynamic Icon
            Image(systemName: iconName)
                .foregroundStyle(isFocused ? .blue : .secondary)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 22)
                .animation(.easeInOut(duration: 0.2), value: inputType)
            
            // Country Code (only visible for phone input)
            if inputType == .phone {
                Button(action: {
                    showCountryPicker = true
                }) {
                    HStack(spacing: 3) {
                        Text(selectedCountryCode.flag)
                            .font(.callout)
                        Text(selectedCountryCode.code)
                            .font(.custom("AlbertSans-Regular", size: 14))
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Text Field
            TextField(placeholder, text: $text)
                .font(.custom("AlbertSans-Regular", size: 16))
                .focused($isFocused)
                .keyboardType(inputType == .phone ? .phonePad : .emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onChange(of: text) { newValue in
                    detectInputType(newValue)
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
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: inputType)
    }
    
    private var iconName: String {
        switch inputType {
        case .email:
            return "envelope.circle.fill"
        case .phone:
            return "phone.circle.fill"
        case .unknown:
            return "at.circle"
        }
    }
    
    private func detectInputType(_ input: String) {
        let cleanInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanInput.isEmpty {
            inputType = .unknown
        } else if cleanInput.contains("@") {
            inputType = .email
        } else if cleanInput.first?.isNumber == true || cleanInput.hasPrefix("+") {
            inputType = .phone
        } else {
            let numbersOnly = cleanInput.filter { $0.isNumber }
            if numbersOnly.count >= 3 && numbersOnly.count == cleanInput.count {
                inputType = .phone
            } else {
                inputType = .email
            }
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

// MARK: - Country Code Model and Picker
struct CountryCode: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let flag: String
    
    static let turkey = CountryCode(name: "Türkiye", code: "+90", flag: "🇹🇷")
    static let usa = CountryCode(name: "United States", code: "+1", flag: "🇺🇸")
    static let germany = CountryCode(name: "Germany", code: "+49", flag: "🇩🇪")
    static let france = CountryCode(name: "France", code: "+33", flag: "🇫🇷")
    static let uk = CountryCode(name: "United Kingdom", code: "+44", flag: "🇬🇧")
    
    static let all: [CountryCode] = [
        .turkey, .usa, .germany, .france, .uk,
        CountryCode(name: "Canada", code: "+1", flag: "🇨🇦"),
        CountryCode(name: "Italy", code: "+39", flag: "🇮🇹"),
        CountryCode(name: "Spain", code: "+34", flag: "🇪🇸"),
        CountryCode(name: "Netherlands", code: "+31", flag: "🇳🇱"),
        CountryCode(name: "Japan", code: "+81", flag: "🇯🇵")
    ]
}

struct CountryCodePicker: View {
    @Binding var selectedCountryCode: CountryCode
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    var filteredCountries: [CountryCode] {
        if searchText.isEmpty {
            return CountryCode.all
        } else {
            return CountryCode.all.filter { country in
                country.name.localizedCaseInsensitiveContains(searchText) ||
                country.code.contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredCountries) { country in
                    Button(action: {
                        selectedCountryCode = country
                        dismiss()
                    }) {
                        HStack(spacing: 14) {
                            Text(country.flag)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(country.name)
                                    .font(.custom("AlbertSans-Regular", size: 16))
                                    .foregroundStyle(.primary)
                                
                                Text(country.code)
                                    .font(.custom("AlbertSans-Regular", size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if country.id == selectedCountryCode.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Ülke Seçin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .font(.custom("AlbertSans-Regular", size: 16))
                }
            }
            .searchable(text: $searchText, prompt: "Ülke ara...")
        }
    }
}

// MARK: - Terms and Privacy Sheet
struct TermsAndPrivacySheet: View {
    @Binding var termsAccepted: Bool
    @Environment(\.dismiss) var dismiss
    @State private var showTerms = false
    @State private var showPrivacy = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Kullanım Koşulları")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("SnapCollab'ı kullanmak için aşağıdaki şartları kabul etmeniz gerekir")
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
                                .frame(width: 24)
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
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showPrivacy = true }) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundStyle(.green)
                                .frame(width: 24)
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
                    .buttonStyle(PlainButtonStyle())
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
        .fullScreenCover(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
    }
}
