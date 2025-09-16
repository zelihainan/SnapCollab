//
//  SettingsView.swift - Complete with All Active Functions
//  SnapCollab
//

import SwiftUI
import UIKit
import StoreKit

struct SettingsView: View {
    @StateObject var vm: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("preferredColorScheme") private var preferredColorScheme: ColorSchemePreference = .system
    
    // Sheet state'leri - Mevcut olanlar
    @State private var showFontSizeSettings = false
    @State private var showNotificationSettings = false
    
    // 🆕 Yeni aktif fonksiyonlar için sheet state'leri
    @State private var showStorageDetails = false
    @State private var showDataExport = false
    @State private var showDeleteAccount = false
    @State private var showAboutApp = false
    
    var body: some View {
        NavigationView {
            List {
                // Profil Bilgileri Bölümü
                Section {
                    ProfileEditRow(vm: vm)
                } header: {
                    Text("Profil Bilgileri")
                } footer: {
                    Text("Profil fotoğrafınızı ve görünen adınızı değiştirin")
                }
                
                // Hesap Güvenliği Bölümü
                if !vm.isAnonymous {
                    Section {
                        SettingsRow(
                            icon: "key.fill",
                            title: "Şifre Değiştir",
                            subtitle: "Hesap güvenliğinizi koruyun",
                            iconColor: .orange
                        ) {
                            vm.showPasswordChange = true
                        }
                        
                        SettingsRow(
                            icon: "envelope.fill",
                            title: "E-posta Değiştir",
                            subtitle: vm.user?.email ?? "",
                            iconColor: .blue
                        ) {
                            vm.showEmailChange = true
                        }
                    } header: {
                        Text("Hesap Güvenliği")
                    }
                }
                
                // Görünüm Ayarları Bölümü
                Section {
                    // Dark Mode Toggle
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.purple.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: colorScheme == .dark ? "moon.fill" : "sun.max.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.purple)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tema")
                                .font(.body)
                                .foregroundStyle(.primary)
                            
                            Text(themeDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Menu {
                            Picker("Tema Seçimi", selection: $preferredColorScheme) {
                                Label("Sistem", systemImage: "gear")
                                    .tag(ColorSchemePreference.system)
                                
                                Label("Açık", systemImage: "sun.max")
                                    .tag(ColorSchemePreference.light)
                                
                                Label("Koyu", systemImage: "moon")
                                    .tag(ColorSchemePreference.dark)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(preferredColorScheme.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    SettingsRow(
                        icon: "textformat.size",
                        title: "Yazı Boyutu",
                        subtitle: "Uygulama yazı boyutunu ayarlayın",
                        iconColor: .green
                    ) {
                        showFontSizeSettings = true
                    }
                    
                } header: {
                    Text("Görünüm")
                }
                
                // Bildirim Ayarları Bölümü
                Section {
                    SettingsRow(
                        icon: "bell.fill",
                        title: "Bildirimler",
                        subtitle: "Bildirim tercihlerinizi yönetin",
                        iconColor: .red
                    ) {
                        showNotificationSettings = true
                    }
                    
                } header: {
                    Text("Bildirimler")
                }
                
                // Veri ve Depolama Bölümü - 🆕 Enhanced
                Section {
                    StorageUsageRow(showDetails: $showStorageDetails)
                    
                    ClearCacheRow()
                    
                } header: {
                    Text("Veri ve Depolama")
                }
                
                // Hesap Yönetimi Bölümü - 🆕 Enhanced
                Section {
                    if vm.isAnonymous {
                        SettingsRow(
                            icon: "arrow.up.circle.fill",
                            title: "Hesabı Kayıtlı Hesaba Dönüştür",
                            subtitle: "Verilerinizi güvence altına alın",
                            iconColor: .blue
                        ) {
                            // TODO: Upgrade account implementation
                            print("Upgrade account tapped")
                        }
                    }
                    
                    // ✅ Verilerimi İndir - ACTIVE
                    SettingsRow(
                        icon: "square.and.arrow.down.fill",
                        title: "Verilerimi İndir",
                        subtitle: "Tüm verilerinizi JSON olarak indirin",
                        iconColor: .purple
                    ) {
                        showDataExport = true
                    }
                    
                    // ✅ Hesabı Sil - ACTIVE
                    SettingsRow(
                        icon: "trash.fill",
                        title: "Hesabı Sil",
                        subtitle: "Hesabınızı kalıcı olarak silin",
                        iconColor: .red
                    ) {
                        showDeleteAccount = true
                    }
                    
                } header: {
                    Text("Hesap Yönetimi")
                } footer: {
                    Text("Hesap silme işlemi geri alınamaz")
                }
                
                // App Info Bölümü - 🆕 Enhanced
                Section {
                    // ✅ Uygulama Hakkında - ACTIVE
                    SettingsRow(
                        icon: "info.circle.fill",
                        title: "Uygulama Hakkında",
                        subtitle: "Versiyon, lisanslar ve geliştirici bilgileri",
                        iconColor: .gray
                    ) {
                        showAboutApp = true
                    }
                    
                    // ✅ Uygulamayı Değerlendir - ACTIVE
                    SettingsRow(
                        icon: "star.fill",
                        title: "Uygulamayı Değerlendir",
                        subtitle: "App Store'da değerlendirin",
                        iconColor: .yellow
                    ) {
                        requestAppReview()
                    }
                    
                } header: {
                    Text("Uygulama")
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:
                Button("Kapat") {
                    dismiss()
                }
            )
        }
        // Mevcut sheet'ler
        .sheet(isPresented: $vm.showEmailChange) {
            EmailChangeSheet(vm: vm)
        }
        .sheet(isPresented: $showFontSizeSettings) {
            FontSizeSettingsSheet()
        }
        .sheet(isPresented: $showNotificationSettings) {
            NotificationSettingsSheet()
        }
        .sheet(isPresented: $vm.showPasswordChange) {
            PasswordChangeSheet(vm: vm)
        }
        .sheet(isPresented: $vm.showImagePicker) {
            ImagePicker(selectedImage: $vm.selectedImage, sourceType: .photoLibrary)
        }
        
        // 🆕 YENİ AKTİF SHEET'LER
        .sheet(isPresented: $showStorageDetails) {
            StorageDetailsView()
        }
        .sheet(isPresented: $showDataExport) {
            DataExportView(authRepo: vm.authRepo)
        }
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountView(vm: vm)
        }
        .sheet(isPresented: $showAboutApp) {
            AboutAppView()
        }
        
        // Mevcut onChange ve alert'ler
        .onChange(of: vm.selectedImage) { newImage in
            if newImage != nil {
                Task {
                    await vm.saveChanges()
                }
            }
        }
        .alert("Başarılı", isPresented: $vm.showSuccessMessage) {
            Button("Tamam") { }
        } message: {
            Text("Profil bilgileriniz güncellendi")
        }
        .alert("Hata", isPresented: Binding<Bool>(
            get: { vm.errorMessage != nil },
            set: { _ in vm.errorMessage = nil }
        )) {
            Button("Tamam") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .preferredColorScheme(preferredColorScheme.colorScheme)
    }
    
    private var themeDescription: String {
        switch preferredColorScheme {
        case .system:
            return "Sistem ayarını takip eder"
        case .light:
            return "Her zaman açık tema"
        case .dark:
            return "Her zaman koyu tema"
        }
    }
    
    // ✅ App Store Review Request - YENİ FONKSİYON
    private func requestAppReview() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Request review
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - ProfileEditRow (Mevcut - değişiklik yok)
struct ProfileEditRow: View {
    @ObservedObject var vm: ProfileViewModel
    @State private var showNameEditor = false
    @State private var showPhotoOptions = false
    @State private var useCamera = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                ZStack {
                    Group {
                        if let selectedImage = vm.selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if let photoURL = vm.user?.photoURL, !photoURL.isEmpty {
                            AsyncImage(url: URL(string: photoURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                                    .scaleEffect(1.2)
                            }
                        } else {
                            Circle()
                                .fill(.blue.gradient)
                                .overlay {
                                    if let user = vm.user {
                                        Text(user.initials)
                                            .font(.system(size: 32, weight: .medium))
                                            .foregroundStyle(.white)
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 32))
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.gray.opacity(0.2), lineWidth: 2))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    if vm.isLoading {
                        Circle()
                            .fill(.black.opacity(0.6))
                            .frame(width: 80, height: 80)
                            .overlay {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                    }
                }
                .onTapGesture {
                    if !vm.isLoading {
                        showPhotoOptions = true
                    }
                }
                
                Button(action: { showPhotoOptions = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.subheadline)
                        Text("Fotoğrafı Değiştir")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.blue.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(vm.isLoading)
            }
            
            Divider()
            
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ad Soyad")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(vm.user?.displayName ?? "İsimsiz Kullanıcı")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Düzenle") {
                        showNameEditor = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                    .buttonStyle(PlainButtonStyle())
                    .disabled(vm.isLoading)
                }
                .contentShape(Rectangle())
                .onTapGesture { }
            }
        }
        .padding(.vertical, 8)
        .confirmationDialog("Profil Fotoğrafı", isPresented: $showPhotoOptions) {
            Button("Galeriden Seç") {
                useCamera = false
                vm.showImagePicker = true
            }
            
            Button("Fotoğraf Çek") {
                useCamera = true
                vm.showImagePicker = true
            }
            
            if vm.user?.photoURL != nil {
                Button("Fotoğrafı Kaldır", role: .destructive) {
                    Task {
                        await vm.removeProfilePhoto()
                    }
                }
            }
            
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Profil fotoğrafınızı nasıl değiştirmek istiyorsunuz?")
        }
        .sheet(isPresented: $vm.showImagePicker) {
            ImagePicker(
                selectedImage: $vm.selectedImage,
                sourceType: useCamera ? .camera : .photoLibrary
            )
        }
        .sheet(isPresented: $showNameEditor) {
            DisplayNameEditorSheet(vm: vm)
        }
    }
}

// MARK: - DisplayNameEditorSheet (Mevcut - değişiklik yok)
struct DisplayNameEditorSheet: View {
    @ObservedObject var vm: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var newDisplayName: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Görünen Adını Değiştir")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Bu ad diğer kullanıcılar tarafından görülecek")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    TextField("Yeni görünen ad", text: $newDisplayName)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                    
                    if newDisplayName.count > 30 {
                        Text("Görünen ad 30 karakterden kısa olmalı")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    Button("Kaydet") {
                        vm.displayName = newDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
                        Task {
                            await vm.saveChanges()
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             newDisplayName.count > 30 ||
                             vm.isLoading)
                    .frame(maxWidth: .infinity)
                    
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            newDisplayName = vm.user?.displayName ?? ""
        }
        .disabled(vm.isLoading)
        .overlay {
            if vm.isLoading {
                Color.black.opacity(0.3)
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Kaydediliyor...")
                                .foregroundStyle(.white)
                                .font(.caption)
                        }
                    }
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - SettingsRow (Mevcut - değişiklik yok)
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ColorSchemePreference (Mevcut - değişiklik yok)
enum ColorSchemePreference: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "Sistem"
        case .light: return "Açık"
        case .dark: return "Koyu"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - PasswordChangeSheet (Mevcut - değişiklik yok)
struct PasswordChangeSheet: View {
    @ObservedObject var vm: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.orange)
                    
                    Text("Şifre Değiştir")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Güvenliğiniz için önce mevcut şifrenizi girin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    SecureTextFieldWithToggle(placeholder: "Mevcut Şifre", text: $vm.currentPassword)
                    
                    SecureTextFieldWithToggle(placeholder: "Yeni Şifre", text: $vm.newPassword)
                    
                    SecureTextFieldWithToggle(placeholder: "Yeni Şifre Tekrar", text: $vm.confirmPassword)
                    
                    if let validationError = vm.passwordValidationError {
                        Text(validationError)
                            .foregroundStyle(.orange)
                            .font(.caption)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let passwordError = vm.passwordErrorMessage {
                        Text(passwordError)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    Button("Şifre Değiştir") {
                        Task { await vm.changePassword() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!vm.isPasswordFormValid || vm.isChangingPassword)
                    .frame(maxWidth: .infinity)
                    
                    Button("İptal") {
                        vm.cancelPasswordChange()
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .disabled(vm.isChangingPassword)
        .overlay {
            if vm.isChangingPassword {
                Color.black.opacity(0.3)
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Şifre değiştiriliyor...")
                                .foregroundStyle(.white)
                                .font(.caption)
                        }
                    }
                    .ignoresSafeArea()
            }
        }
        .onChange(of: vm.showPasswordChange) { isShowing in
            if !isShowing {
                dismiss()
            }
        }
        .onDisappear {
            vm.passwordErrorMessage = nil
        }
    }
}

// MARK: - 🆕 Enhanced Storage Usage Row
struct StorageUsageRow: View {
    @StateObject private var storageManager = StorageManager.shared
    @Binding var showDetails: Bool
    
    var body: some View {
        SettingsRow(
            icon: "icloud.fill",
            title: "Depolama Kullanımı",
            subtitle: storageManager.isCalculating ? "Hesaplanıyor..." : "Kullanılan alan: \(storageManager.formatStorageSize(storageManager.totalStorageUsed))",
            iconColor: .cyan
        ) {
            showDetails = true
        }
        .onAppear {
            if storageManager.totalStorageUsed == 0 {
                Task {
                    await storageManager.calculateStorageUsage()
                }
            }
        }
    }
}

// MARK: - ClearCacheRow (Mevcut - değişiklik yok)
struct ClearCacheRow: View {
    @StateObject private var storageManager = StorageManager.shared
    @State private var showClearAlert = false
    @State private var isClearing = false
    
    var body: some View {
        SettingsRow(
            icon: "arrow.down.circle.fill",
            title: "Önbellek Temizle",
            subtitle: isClearing ? "Temizleniyor..." : "Geçici dosyaları temizle",
            iconColor: .orange
        ) {
            showClearAlert = true
        }
        .disabled(isClearing)
        .alert("Önbellek Temizle", isPresented: $showClearAlert) {
            Button("İptal", role: .cancel) { }
            Button("Temizle", role: .destructive) {
                Task {
                    isClearing = true
                    do {
                        try await storageManager.clearCache()
                    } catch {
                        print("Cache clear error: \(error)")
                    }
                    isClearing = false
                }
            }
        } message: {
            Text("Önbellek dosyaları temizlenecek. Bu işlem geri alınamaz.")
        }
    }
}
