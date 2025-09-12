//
//  ProfileView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import SwiftUI
import UIKit

struct ProfileView: View {
    @State private var showPrivacy = false
    @State private var showTerms = false
    @State private var showSupport = false

    @StateObject var vm: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Photo Section
                    VStack(spacing: 12) {
                        ZStack {
                            if let selectedImage = vm.selectedImage {
                                // Preview of selected image
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(.gray.opacity(0.3), lineWidth: 2))
                            } else if let photoURL = vm.user?.photoURL, !photoURL.isEmpty {
                                // Current profile photo
                                AsyncImage(url: URL(string: photoURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.gray.opacity(0.3), lineWidth: 2))
                            } else {
                                // Default avatar
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.gray)
                                    .font(.system(size: 100))
                            }
                            
                            // Edit overlay when editing
                            if vm.isEditing {
                                Circle()
                                    .fill(.black.opacity(0.4))
                                    .frame(width: 100, height: 100)
                                    .overlay {
                                        Image(systemName: "camera.fill")
                                            .foregroundStyle(.white)
                                            .font(.title2)
                                    }
                            }
                        }
                        .onTapGesture {
                            if vm.isEditing {
                                vm.showImagePicker = true
                            }
                        }
                    }
                    .padding(.top, 16)
                    
                    // Display Name Section
                    VStack(spacing: 8) {
                        if vm.isEditing {
                            TextField("Ad Soyad", text: $vm.displayName)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.center)
                                .font(.title2)
                                .frame(maxWidth: 250)
                        } else {
                            Text(vm.user?.displayName ?? "İsimsiz Kullanıcı")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // User Info Section
                    VStack(spacing: 0) {
                        InfoRow(
                            icon: vm.isAnonymous ? "person.crop.circle.dashed" : "person.crop.circle",
                            title: "Hesap Türü",
                            value: vm.isAnonymous ? "Misafir Hesap" : "Kayıtlı Hesap",
                            iconColor: vm.isAnonymous ? .orange : .green
                        )
                        
                        if !vm.isAnonymous {
                            Divider()
                                .padding(.leading, 44)
                            
                            InfoRow(
                                icon: "envelope",
                                title: "E-posta",
                                value: vm.user?.email ?? "",
                                iconColor: .blue
                            )
                        }
                        
                        Divider()
                            .padding(.leading, 44)
                        
                        InfoRow(
                            icon: "calendar",
                            title: "Katılma Tarihi",
                            value: vm.joinDateText,
                            iconColor: .purple
                        )
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        if vm.isAnonymous {
                            ActionButton(
                                icon: "arrow.up.circle.fill",
                                title: "Hesabı Kayıtlı Hesaba Dönüştür",
                                color: .blue,
                                action: {
                                    print("Upgrade account tapped")
                                }
                            )
                        }
                        
                        // Şifre değiştirme butonu - sadece email kullanıcıları için
                        if !vm.isAnonymous {
                            ActionButton(
                                icon: "key.fill",
                                title: "Şifre Değiştir",
                                color: .orange,
                                showChevron: true,
                                action: {
                                    print("Password change tapped")
                                    vm.showPasswordChange = true
                                }
                            )
                        }
                        
                        ActionButton(
                            icon: "hand.raised",
                            title: "Gizlilik Politikası",
                            color: .primary,
                            showChevron: true,
                            action: {
                                showPrivacy = true
                            }
                        )
                        
                        ActionButton(
                            icon: "doc.text",
                            title: "Kullanım Koşulları",
                            color: .primary,
                            showChevron: true,
                            action: {
                                showTerms = true
                            }
                        )
                        
                        ActionButton(
                            icon: "questionmark.circle",
                            title: "Destek",
                            color: .primary,
                            showChevron: true,
                            action: {
                                showSupport = true
                            }
                        )
                        
                        ActionButton(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Çıkış Yap",
                            color: .red,
                            action: {
                                vm.signOut()
                            }
                        )
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if vm.isEditing {
                        HStack(spacing: 12) {
                            Button("İptal") {
                                vm.cancelEditing()
                            }
                            .foregroundStyle(.blue)
                            
                            Button("Kaydet") {
                                Task { await vm.saveChanges() }
                            }
                            .fontWeight(.semibold)
                            .disabled(vm.isLoading)
                            .foregroundStyle(vm.isLoading ? .gray : .blue)
                        }
                    } else {
                        Button("Düzenle") {
                            vm.startEditing()
                        }
                        .foregroundStyle(.blue)
                    }
                }
            }
        }
        
        .navigationViewStyle(.stack)
        .sheet(isPresented: $vm.showImagePicker) {
            ImagePicker(selectedImage: $vm.selectedImage)
        }
        .sheet(isPresented: $vm.showPasswordChange) {
            PasswordChangeSheet(vm: vm)
        }
        .fullScreenCover(isPresented: $showPrivacy) {
            NavigationView { PrivacyPolicyView() }
        }

        .fullScreenCover(isPresented: $showTerms) {
            NavigationView { TermsOfServiceView() }
        }

        .fullScreenCover(isPresented: $showSupport) {
            NavigationView { SupportView() }
        }

        
        .onAppear {
            print("ProfileView appeared")
            print("DEBUG: User email: '\(vm.user?.email ?? "nil")'")
            print("DEBUG: isAnonymous: \(vm.isAnonymous)")
            vm.refreshUser()
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
                            Text("Güncelleniyor...")
                                .foregroundStyle(.white)
                                .font(.caption)
                        }
                    }
                    .ignoresSafeArea()
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
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title3)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Action Button Component
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let showChevron: Bool
    let action: () -> Void
    
    init(icon: String, title: String, color: Color, showChevron: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 20)
                
                Text(title)
                    .font(.body)
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Password Change Sheet
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
                    
                    // Real-time validasyon mesajları
                    if let validationError = vm.passwordValidationError {
                        Text(validationError)
                            .foregroundStyle(.orange)
                            .font(.caption)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Firebase auth hatası (yanlış şifre vs)
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
        // Sheet kapanırken şifre state'ini koruyoruz - sadece error temizleniyor
        .onDisappear {
            vm.passwordErrorMessage = nil
        }
    }
}

#Preview {
    let mockAuthRepo = AuthRepository(
        service: FirebaseAuthService(),
        userService: FirestoreUserService()
    )
    let mockMediaRepo = MediaRepository(
        service: FirestoreMediaService(),
        storage: FirebaseStorageService(),
        auth: mockAuthRepo
    )
    
    ProfileView(vm: ProfileViewModel(authRepo: mockAuthRepo, mediaRepo: mockMediaRepo))
}
