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
    @State private var deleteStep: DeleteStep = .information
    
    enum DeleteStep {
        case information
        case confirmation
        case authentication
        case processing
    }
    
    private let requiredConfirmationText = "HESABIMI SIL"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.orange.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "person.badge.minus")
                                .font(.system(size: 50))
                                .foregroundStyle(.orange)
                        }
                        
                        Text("Hesabı Sil")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Text("Hesabınızı kalıcı olarak silmek istiyorsunuz")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Content based on step
                    switch deleteStep {
                    case .information:
                        informationContent
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
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.orange.opacity(0.1))
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Hesap Yönetimi")
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
    
    // MARK: - Information Content
    private var informationContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Silinecek Veriler")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                VStack(spacing: 12) {
                    DeletionInfoItem(
                        icon: "person.circle",
                        title: "Profil Bilgileri",
                        description: "Ad, e-posta, profil fotoğrafı"
                    )
                    
                    DeletionInfoItem(
                        icon: "photo.stack",
                        title: "Albüm Verileri",
                        description: "Oluşturduğunuz albümler ve üyelikler"
                    )
                    
                    DeletionInfoItem(
                        icon: "heart",
                        title: "Favoriler",
                        description: "Tüm favori işaretlemeleriniz"
                    )
                    
                    DeletionInfoItem(
                        icon: "gear",
                        title: "Uygulama Ayarları",
                        description: "Tüm kişisel tercih ve ayarlar"
                    )
                    
                    DeletionInfoItem(
                        icon: "bell",
                        title: "Bildirim Geçmişi",
                        description: "Tüm bildirim kayıtları"
                    )
                }
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Önemli Uyarı")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Bu işlem geri alınamaz. Hesabınız silindikten sonra verilerinize erişemezsiniz.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.orange.opacity(0.1))
                )
                .padding(.horizontal, 20)
                
                Button("Devam Et") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        deleteStep = .confirmation
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Confirmation Content
    private var confirmationContent: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Onay Gerekli")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                VStack(spacing: 12) {
                    Text("Devam etmek için aşağıya")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Text("'\(requiredConfirmationText)'")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                    
                    Text("yazın")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                TextField("Onay kodu", text: $confirmationText)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .foregroundStyle(confirmationText == requiredConfirmationText ? .orange : .primary)
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
                .tint(.orange)
                .disabled(confirmationText != requiredConfirmationText)
                .frame(maxWidth: .infinity)
                
                Button("Geri") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        deleteStep = .information
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
                Text("Güvenlik Doğrulaması")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Güvenliğiniz için mevcut şifrenizi girin")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
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
                    .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                    .scaleEffect(1.5)
                
                Text("Hesap Siliniyor...")
                    .font(.headline)
                    .foregroundStyle(.orange)
                
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

// MARK: - Deletion Info Item Component
struct DeletionInfoItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.orange)
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
            
            Image(systemName: "minus.circle")
                .foregroundStyle(.orange)
                .font(.title3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}
