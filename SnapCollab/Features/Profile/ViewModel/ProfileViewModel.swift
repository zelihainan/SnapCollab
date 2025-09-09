//
//  ProfileViewModel.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation
import UIKit

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
    
    private let authRepo: AuthRepository
    private let mediaRepo: MediaRepository
    
    init(authRepo: AuthRepository, mediaRepo: MediaRepository) {
        self.authRepo = authRepo
        self.mediaRepo = mediaRepo
        
        // İlk yükleme
        self.user = authRepo.currentUser
        self.displayName = authRepo.currentUser?.displayName ?? ""
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
            // Display name güncelleme
            let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            print("ProfileVM: Trimmed name: '\(trimmedName)' vs current: '\(user?.displayName ?? "nil")'")
            
            if !trimmedName.isEmpty && trimmedName != user?.displayName {
                print("ProfileVM: Updating display name to: \(trimmedName)")
                updatedUser.displayName = trimmedName
            }
            
            // Profil fotoğrafı yükleme
            if let newImage = selectedImage {
                print("ProfileVM: Uploading new profile photo")
                isUploadingPhoto = true
                let photoURL = try await uploadProfilePhoto(newImage)
                updatedUser.photoURL = photoURL
                isUploadingPhoto = false
                print("ProfileVM: Profile photo uploaded successfully")
            }
            
            // Kullanıcı bilgilerini güncelle
            print("ProfileVM: Calling authRepo.updateUser...")
            try await authRepo.updateUser(updatedUser)
            print("ProfileVM: Update successful!")
            
            // Local state güncelle
            user = updatedUser
            isEditing = false
            selectedImage = nil
            showSuccessMessage = true
            
            // Success message'ı otomatik gizle
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
            
            // Kullanıcı bilgilerini güncelle
            try await authRepo.updateUser(updatedUser)
            
            // Local state güncelle
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
        
        // Resmi boyutlandır
        let resizedImage = await resizeImage(image, to: 300)
        guard let resizedData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProfilePhoto", code: -1, userInfo: [NSLocalizedDescriptionKey: "Fotoğraf boyutlandırılamadı"])
        }
        
        let fileName = "profile_\(uid)_\(Date().timeIntervalSince1970).jpg"
        let storagePath = "users/\(uid)/profile/\(fileName)"
        
        // Storage'a yükle
        try await mediaRepo.storage.put(data: resizedData, to: storagePath)
        
        // Download URL'i al
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
                    // Landscape
                    newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
                } else {
                    // Portrait or square
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
    
    func signOut() {
        do {
            try authRepo.signOut()
        } catch {
            errorMessage = "Çıkış hatası: \(error.localizedDescription)"
        }
    }
    
    func refreshUser() {
        print("ProfileVM: refreshUser called")
        user = authRepo.currentUser
        displayName = user?.displayName ?? ""
        print("ProfileVM: user: \(user?.displayName ?? "nil"), displayName: \(displayName)")
    }
    
    var isAnonymous: Bool {
        guard let email = user?.email else { return true }
        return email.isEmpty
    }
    
    var joinDateText: String {
        guard let user = user else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: user.createdAt)
    }
}
