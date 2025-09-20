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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient Background
                LinearGradient(
                    colors: [
                        Color(.systemBlue).opacity(0.8),
                        Color(.systemPurple).opacity(0.6),
                        Color(.systemBackground)
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
                                .frame(height: 80)
                            
                            // SnapCollab Title
                            HStack(spacing: 0) {
                                Text("Snap")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                
                                Text("Collab")
                                    .font(.system(size: 42, weight: .light, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Spacer()
                                .frame(height: 60)
                        }
                        
                        // Main Form Card
                        VStack(spacing: 0) {
                            VStack(spacing: 24) {
                                // Welcome Title
                                Text(showSignUp ? "Hesap Oluştur" : "Hoş Geldiniz")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .padding(.top, 32)
                                    .animation(.easeInOut(duration: 0.3), value: showSignUp)
                                
                                // Form Fields
                                VStack(spacing: 16) {
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
                                    
                                    // Password Field
                                    ModernSecureField(
                                        text: $password,
                                        placeholder: "Şifre",
                                        showForgotPassword: !showSignUp,
                                        onForgotPassword: {
                                            vm.resetEmail = emailOrPhone
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
                                            .font(.system(size: 16, weight: .medium))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundStyle(.blue)
                                }
                                
                                // Divider
                                HStack {
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundStyle(.separator)
                                    
                                    Text("veya")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 16)
                                        .background(Color(.systemBackground))
                                    
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundStyle(.separator)
                                }
                                .padding(.vertical, 8)
                                
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
                                
                                Spacer(minLength: 40)
                            }
                            .padding(.horizontal, 32)
                            .padding(.bottom, 50)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(.regularMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .padding(.horizontal, 16)
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
        .sheet(isPresented: $showTermsSheet) {
            TermsAndPrivacySheet(termsAccepted: $termsAccepted)
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryCodePicker(selectedCountryCode: $selectedCountryCode)
        }
    }
    
    // MARK: - Helper Methods
    private var isFormValid: Bool {
        if showSignUp {
            return !displayName.isEmpty &&
                   !emailOrPhone.isEmpty &&
                   !password.isEmpty &&
                   password == confirmPassword &&
                   password.count >= 6 &&
                   termsAccepted
        }
        return !emailOrPhone.isEmpty && !password.isEmpty
    }
    
    private func handleAuthentication() async {
        if showSignUp {
            if isValidPhoneNumber(emailOrPhone) {
                let fullPhone = selectedCountryCode.code + cleanPhoneNumber(emailOrPhone)
                await vm.signUpWithPhone(phone: fullPhone, password: password, displayName: displayName)
            } else {
                await vm.signUp(email: emailOrPhone, password: password, displayName: displayName)
            }
        } else {
            if isValidPhoneNumber(emailOrPhone) {
                let fullPhone = selectedCountryCode.code + cleanPhoneNumber(emailOrPhone)
                await vm.signInWithPhone(phone: fullPhone, password: password)
            } else {
                await vm.signIn(email: emailOrPhone, password: password)
            }
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
    
    private func isValidPhoneNumber(_ input: String) -> Bool {
        let cleanInput = cleanPhoneNumber(input)
        return cleanInput.allSatisfy { $0.isNumber } && cleanInput.count >= 10
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
        HStack(spacing: 12) {
            // Dynamic Icon
            Image(systemName: iconName)
                .foregroundStyle(isFocused ? .blue : .secondary)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 24)
                .animation(.easeInOut(duration: 0.2), value: inputType)
            
            // Country Code (only visible for phone input)
            if inputType == .phone {
                Button(action: {
                    showCountryPicker = true
                }) {
                    HStack(spacing: 4) {
                        Text(selectedCountryCode.flag)
                            .font(.title3)
                        Text(selectedCountryCode.code)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Text Field
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .keyboardType(inputType == .phone ? .phonePad : .emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onChange(of: text) { newValue in
                    detectInputType(newValue)
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
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
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundStyle(isFocused ? .blue : .secondary)
                .font(.system(size: 20, weight: .medium))
                .frame(width: 24)
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
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
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
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Image(systemName: "lock.circle.fill")
                    .foregroundStyle(isFocused ? .blue : .secondary)
                    .font(.system(size: 20, weight: .medium))
                    .frame(width: 24)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                if isSecured {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSecured.toggle()
                    }
                }) {
                    Image(systemName: isSecured ? "eye.slash.circle" : "eye.circle")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
                .padding(.trailing, 4)
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
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon {
                        if icon == "google" {
                            Circle()
                                .fill(.white)
                                .frame(width: 20, height: 20)
                                .overlay {
                                    Text("G")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.blue)
                                }
                        } else {
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .medium))
                        }
                    }
                    
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
            return isDisabled ? 2 : 8
        case .google:
            return 6
        }
    }
    
    private var shadowY: CGFloat {
        switch style {
        case .primary:
            return isDisabled ? 1 : 4
        case .google:
            return 3
        }
    }
}

// MARK: - Terms Acceptance Component
struct TermsAcceptanceView: View {
    @Binding var termsAccepted: Bool
    @Binding var showTermsSheet: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    termsAccepted.toggle()
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(termsAccepted ? .blue : .gray, lineWidth: 2)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(termsAccepted ? .blue : .clear)
                        )
                    
                    if termsAccepted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Aşağıdaki şartları kabul ediyorum:")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    Button("Kullanım Koşulları") {
                        showTermsSheet = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.blue)
                    
                    Text("ve")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    
                    Button("Gizlilik Politikası") {
                        showTermsSheet = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Error Message Component
struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 16))
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
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
                        HStack(spacing: 16) {
                            Text(country.flag)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(country.name)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                
                                Text(country.code)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if country.id == selectedCountryCode.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Ülke Seçin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
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
