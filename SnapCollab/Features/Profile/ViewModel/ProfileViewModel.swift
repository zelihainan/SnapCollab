//
//  ProfileViewModel.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var displayName = ""
    @Published var isEditing = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessMessage = false
    
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
            
            // Kullanıcı bilgilerini güncelle
            print("ProfileVM: Calling authRepo.updateUser...")
            try await authRepo.updateUser(updatedUser)
            print("ProfileVM: Update successful!")
            
            // Local state güncelle
            user = updatedUser
            isEditing = false
            showSuccessMessage = true
            
            // Success message'ı otomatik gizle
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showSuccessMessage = false
            }
            
        } catch {
            print("ProfileVM: Update error: \(error)")
            errorMessage = "Güncelleme hatası: \(error.localizedDescription)"
        }
        
        isLoading = false
        print("ProfileVM: Save changes completed")
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
