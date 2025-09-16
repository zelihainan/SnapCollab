//
//  DeleteAccountView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 16.09.2025.
//

import SwiftUI
import FirebaseAuth

struct DeleteAccountView: View {
    @ObservedObject var vm: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var currentPassword = ""
    @State private var confirmationText = ""
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var showFinalConfirmation = false
    @State private var agreedToDelete = false
    @State private var deleteStep: DeleteStep = .warning
    
    enum DeleteStep {
        case warning
        case confirmation
        case authentication
        case processing
    }
    
    private let requiredConfirmationText = "HESABIMI SIL"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header - Warning Icon
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.red.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.red)
                        }
                        
                        Text("Hesabı Kalıcı Olarak Sil")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                        
                        Text("Bu işlem geri alınamaz!")
                            .font(.headline)
                            .foregroundStyle(.red)
                    }
                    .padding(.top, 20)
                    
                    // Content based on step
                    switch deleteStep {
                    case .warning:
                        warningContent
                    case .confirmation:
                        confirmationContent
                    case .authentication:
                        authenticationContent
                    case .processing:
                        processingContent
                    }
                    
                    // Error Message
                    if let error = deleteError {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                            
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.red.opacity(0.1))
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Hesabı Sil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundStyle(.blue)
                }
            }
        }
        .alert("Son Onay", isPresented: $showFinalConfirmation) {
            Button("İptal", role: .cancel) { }
            Button("Evet, Sil", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("Hesabınız ve tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz. Devam etmek istediğinizden emin misiniz?")
        }
    }
    
    // MARK: - Warning Content
    private var warningContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Silme İşlemi Hakkında")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                VStack(spacing: 12) {
                    WarningItem(
                        icon: "person.slash",
                        title: "Hesap Bilgileri",
                        description: "Profil, e-posta ve tüm kişisel bilgiler"
                    )
                    
                    WarningItem(
                        icon: "photo.stack",
                        title: "Albüm Verileri",
                        description: "Oluşturduğunuz albümler ve üyelikler"
                    )
                    
                    WarningItem(
                        icon: "heart.slash",
                        title: "Favoriler",
                        description: "Tüm favori işaretlemeleriniz"
                    )
                    
                    WarningItem(
                        icon: "gear",
                        title: "Uygulama Ayarları",
                        description: "Tüm kişisel tercih ve ayarlar"
                    )
                    
                    WarningItem(
                        icon: "bell.slash",
                        title: "Bildirim Geçmişi",
                        description: "Tüm bildirim kayıtları"
                    )
                }
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Button(action: { agreedToDelete.toggle() }) {
                        Image(systemName: agreedToDelete ? "checkmark.square.fill" : "square")
                            .font(.title2)
                            .foregroundStyle(agreedToDelete ? .red : .gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Uyarıları Okudum ve Anladım")
                            .font(.body)
                            .foregroundStyle(.primary)
                        
                        Text("Yukarıdaki tüm verilerin kalıcı olarak silineceğini kabul ediyorum")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                Button("Devam Et") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        deleteStep = .confirmation
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(!agreedToDelete)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Confirmation Content
    private var confirmationContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Onay Kodu Girin")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Devam etmek için aşağıya '\(requiredConfirmationText)' yazın")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                TextField("Onay kodu", text: $confirmationText)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .foregroundStyle(confirmationText == requiredConfirmationText ? .red : .primary)
                    .padding(.horizontal, 20)
                
                if confirmationText == requiredConfirmationText {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Onay kodu doğru")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            VStack(spacing: 12) {
                Button("Şifre Doğrulamasına Geç") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        deleteStep = .authentication
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(confirmationText != requiredConfirmationText)
                .frame(maxWidth: .infinity)
                
                Button("Geri") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        deleteStep = .warning
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Authentication Content
    private var authenticationContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Şifre Doğrulaması")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Güvenlik için mevcut şifrenizi girin")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 16) {
                SecureField("Mevcut şifreniz", text: $currentPassword)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 20)
                
                if !currentPassword.isEmpty && currentPassword.count >= 6 {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Şifre formatı uygun")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            VStack(spacing: 12) {
                Button("Hesabı Kalıcı Olarak Sil") {
                    showFinalConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(currentPassword.isEmpty || currentPassword.count < 6)
                .frame(maxWidth: .infinity)
                
                Button("Geri") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        deleteStep = .confirmation
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Processing Content
    private var processingContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    .scaleEffect(1.5)
                
                Text("Hesap Siliniyor...")
                    .font(.headline)
                    .foregroundStyle(.red)
                
                Text("Bu işlem birkaç dakika sürebilir. Lütfen uygulamayı kapatmayın.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    // MARK: - Delete Account Function
    private func deleteAccount() async {
        guard let currentUser = Auth.auth().currentUser,
              let email = currentUser.email else {
            deleteError = "Kullanıcı bilgisi bulunamadı"
            return
        }
        
        await MainActor.run {
            deleteStep = .processing
            isDeleting = true
            deleteError = nil
        }
        
        do {
            // Step 1: Re-authenticate user
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await currentUser.reauthenticate(with: credential)
            
            // Step 2: Delete user data from Firestore (if implemented)
            // await deleteUserDataFromFirestore(currentUser.uid)
            
            // Step 3: Delete Firebase Auth account
            try await currentUser.delete()
            
            // Step 4: Clear local data
            await clearLocalUserData()
            
            // Step 5: Sign out and dismiss
            await MainActor.run {
                vm.signOut()
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                isDeleting = false
                deleteStep = .authentication
                
                if error.localizedDescription.contains("wrong-password") ||
                   error.localizedDescription.contains("invalid-credential") {
                    deleteError = "Şifre yanlış"
                } else if error.localizedDescription.contains("requires-recent-login") {
                    deleteError = "Güvenlik nedeniyle tekrar giriş yapmanız gerekiyor"
                } else {
                    deleteError = "Hesap silme hatası: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func clearLocalUserData() async {
        // Clear UserDefaults
        let userDefaults = UserDefaults.standard
        let domain = Bundle.main.bundleIdentifier!
        userDefaults.removePersistentDomain(forName: domain)
        
        // Clear cache directory
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            try? FileManager.default.removeItem(at: cacheURL)
        }
    }
}

// MARK: - Warning Item Component
struct WarningItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.title3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.red.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.red.opacity(0.2), lineWidth: 1)
        )
    }
}
