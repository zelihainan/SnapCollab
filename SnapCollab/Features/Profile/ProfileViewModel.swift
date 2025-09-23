import Foundation
import UIKit
import FirebaseAuth

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var displayName = ""
    @Published var isEditing = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessMessage = false
    @Published var showImagePicker = false
    @Published var selectedImage: UIImage?
    @Published var isUploadingPhoto = false
    @Published var showPasswordChange = false
    @Published var showEmailChange = false  
    @Published var currentPassword = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isChangingPassword = false
    @Published var passwordErrorMessage: String?
    
    let authRepo: AuthRepository
    private let mediaRepo: MediaRepository
    
    private var sessionVM: SessionViewModel?
    
    init(authRepo: AuthRepository, mediaRepo: MediaRepository) {
        self.authRepo = authRepo
        self.mediaRepo = mediaRepo
        
        self.user = authRepo.currentUser
        self.displayName = authRepo.currentUser?.displayName ?? ""
    }
    
    func setSessionViewModel(_ sessionVM: SessionViewModel) {
        self.sessionVM = sessionVM
    }
    
    func startEditing() {
        isEditing = true
        displayName = user?.displayName ?? ""
        errorMessage = nil
    }
    
    func cancelEditing() {
        isEditing = false
        displayName = user?.displayName ?? ""
        selectedImage = nil
        errorMessage = nil
    }
    
    func saveChanges() async {
        guard var updatedUser = user else {
            print("ProfileVM: No user to update")
            return
        }
        
        print("ProfileVM: Starting save changes...")
        isLoading = true
        errorMessage = nil
        
        do {
            let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            print("ProfileVM: Trimmed name: '\(trimmedName)' vs current: '\(user?.displayName ?? "nil")'")
            
            if !trimmedName.isEmpty && trimmedName != user?.displayName {
                print("ProfileVM: Updating display name to: \(trimmedName)")
                updatedUser.displayName = trimmedName
            }
            
            if let newImage = selectedImage {
                print("ProfileVM: Uploading new profile photo")
                isUploadingPhoto = true
                let photoURL = try await uploadProfilePhoto(newImage)
                updatedUser.photoURL = photoURL
                isUploadingPhoto = false
                print("ProfileVM: Profile photo uploaded successfully")
            }
            
            print("ProfileVM: Calling authRepo.updateUser...")
            try await authRepo.updateUser(updatedUser)
            print("ProfileVM: Update successful!")
            
            user = updatedUser
            isEditing = false
            selectedImage = nil
            showSuccessMessage = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showSuccessMessage = false
            }
            
        } catch {
            print("ProfileVM: Update error: \(error)")
            errorMessage = "Güncelleme hatası: \(error.localizedDescription)"
            isUploadingPhoto = false
        }
        
        isLoading = false
        print("ProfileVM: Save changes completed")
    }
    
    func removeProfilePhoto() async {
        guard var updatedUser = user else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            updatedUser.photoURL = nil
            
            try await authRepo.updateUser(updatedUser)
            
            user = updatedUser
            showSuccessMessage = true
            
        } catch {
            errorMessage = "Fotoğraf silinirken hata: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func uploadProfilePhoto(_ image: UIImage) async throws -> String {
        guard let uid = authRepo.uid,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProfilePhoto", code: -1, userInfo: [NSLocalizedDescriptionKey: "Fotoğraf işlenemedi"])
        }
        
        let resizedImage = await resizeImage(image, to: 300)
        guard let resizedData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProfilePhoto", code: -1, userInfo: [NSLocalizedDescriptionKey: "Fotoğraf boyutlandırılamadı"])
        }
        
        let fileName = "profile_\(uid)_\(Date().timeIntervalSince1970).jpg"
        let storagePath = "users/\(uid)/profile/\(fileName)"
        
        try await mediaRepo.storage.put(data: resizedData, to: storagePath)
        
        let downloadURL = try await mediaRepo.storage.url(for: storagePath)
        return downloadURL.absoluteString
    }
    
    private func resizeImage(_ image: UIImage, to maxSize: CGFloat) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let size = image.size
                let aspectRatio = size.width / size.height
                
                var newSize: CGSize
                if aspectRatio > 1 {
                    newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
                } else {
                    newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
                }
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                continuation.resume(returning: resizedImage ?? image)
            }
        }
    }
    
    var passwordValidationError: String? {
        if currentPassword.isEmpty && newPassword.isEmpty && confirmPassword.isEmpty {
            return nil
        }
        
        if currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty {
            return "Lütfen tüm alanları doldurun"
        }
        
        if newPassword.count < 6 {
            return "Yeni şifre en az 6 karakter olmalı"
        }
        
        if newPassword != confirmPassword {
            return "Yeni şifreler eşleşmiyor"
        }
        
        if currentPassword == newPassword {
            return "Yeni şifre eski şifre ile aynı olamaz"
        }
        
        return nil
    }
    
    var isPasswordFormValid: Bool {
        return passwordValidationError == nil && !currentPassword.isEmpty && !newPassword.isEmpty && !confirmPassword.isEmpty
    }
    
    func changePassword() async {
        isChangingPassword = true
        passwordErrorMessage = nil
        
        do {
            guard let currentUser = Auth.auth().currentUser,
                  let email = currentUser.email else {
                throw NSError(domain: "PasswordChange", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı"])
            }
            
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await currentUser.reauthenticate(with: credential)
            
            try await currentUser.updatePassword(to: newPassword)
            
            await MainActor.run {
                // Sadece başarılı olduğunda şifreleri temizle
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
                showPasswordChange = false
                showSuccessMessage = true
            }
            
            print("Password changed successfully")
            
        } catch {
            await MainActor.run {
                if error.localizedDescription.contains("wrong-password") || error.localizedDescription.contains("invalid-credential") {
                    passwordErrorMessage = "Mevcut şifre yanlış"
                } else {
                    passwordErrorMessage = "Şifre değiştirme hatası: \(error.localizedDescription)"
                }
            }
        }
        
        isChangingPassword = false
    }

    func cancelPasswordChange() {
        showPasswordChange = false
        passwordErrorMessage = nil
    }
    
    func signOut() {
        print("ProfileVM: signOut called")
        
        if let sessionVM = sessionVM {
            print("ProfileVM: Using SessionViewModel for signOut")
            sessionVM.signOut()
        } else {
            print("ProfileVM: Using AuthRepository directly for signOut")
            do {
                try authRepo.signOut()
            } catch {
                errorMessage = "Çıkış hatası: \(error.localizedDescription)"
            }
        }
    }
    
    func refreshUser() {
        print("ProfileVM: refreshUser called")
        user = authRepo.currentUser
        displayName = user?.displayName ?? ""
        print("ProfileVM: user: \(user?.displayName ?? "nil"), displayName: \(displayName)")
    }
    
    var joinDateText: String {
        guard let user = user else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: user.createdAt)
    }
}
