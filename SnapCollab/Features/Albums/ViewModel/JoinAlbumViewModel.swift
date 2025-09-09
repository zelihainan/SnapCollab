//
//  JoinAlbumViewModel.swift
//  SnapCollab
//
//  Created by Your Name on Date.
//

import Foundation
import SwiftUI

@MainActor
final class JoinAlbumViewModel: ObservableObject {
    @Published var inviteCode = ""
    @Published var foundAlbum: Album?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var joinSuccess = false
    @Published var isInputFocused = false
    
    // UI State
    @Published var activeIndex = 0
    
    private let repo: AlbumRepository
    private var searchTask: Task<Void, Never>?
    
    init(repo: AlbumRepository, initialCode: String? = nil) {
        self.repo = repo
        
        // Eğer initial code varsa (deep link'ten geliyorsa) otomatik set et
        if let code = initialCode?.uppercased() {
            self.inviteCode = String(code.prefix(6))
            self.activeIndex = min(code.count, 6)
            
            // Otomatik olarak albüm ara
            Task { await searchAlbum() }
        }
    }
    
    var isFormValid: Bool {
        inviteCode.count == 6
    }
    
    // MARK: - Input Management
    
    func getDigit(at index: Int) -> String {
        guard index < inviteCode.count else { return "" }
        let char = inviteCode[inviteCode.index(inviteCode.startIndex, offsetBy: index)]
        return String(char)
    }
    
    func focusOnDigit(_ index: Int) {
        activeIndex = index
        // Focus state View'de yönetilecek
    }
    
    func validateAndFormatCode(_ newValue: String) {
        // Sadece harf ve rakam kabul et, 6 karakter sınırı
        let filtered = newValue.uppercased()
            .filter { $0.isLetter || $0.isNumber }
            .prefix(6)
        
        inviteCode = String(filtered)
        activeIndex = min(inviteCode.count, 5)
        
        // Otomatik olarak albüm ara (debounced)
        searchTask?.cancel()
        if inviteCode.count == 6 {
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye bekle
                await searchAlbum()
            }
        } else {
            // Kod tam değilse albüm bilgisini temizle
            foundAlbum = nil
            errorMessage = nil
        }
    }
    
    func pasteFromClipboard() {
        if let clipboardString = UIPasteboard.general.string {
            let cleanCode = clipboardString.uppercased()
                .filter { $0.isLetter || $0.isNumber }
                .prefix(6)
            
            if !cleanCode.isEmpty {
                inviteCode = String(cleanCode)
                activeIndex = min(inviteCode.count, 5)
                
                if inviteCode.count == 6 {
                    Task { await searchAlbum() }
                }
            }
        }
    }
    
    // MARK: - Album Operations
    
    private func searchAlbum() async {
        guard inviteCode.count == 6 else { return }
        
        isLoading = true
        errorMessage = nil
        foundAlbum = nil
        
        do {
            print("JoinAlbumVM: Searching for album with code: \(inviteCode)")
            
            if let album = try await repo.getAlbumByInviteCode(inviteCode) {
                print("JoinAlbumVM: Found album: \(album.title)")
                
                // Kullanıcı zaten üye mi kontrol et
                guard let currentUID = repo.auth.uid else {
                    errorMessage = "Giriş yapmanız gerekiyor"
                    return
                }
                
                if album.isMember(currentUID) {
                    errorMessage = "Bu albümün zaten üyesisiniz"
                    foundAlbum = album
                } else {
                    foundAlbum = album
                    errorMessage = nil
                }
            } else {
                print("JoinAlbumVM: No album found with code: \(inviteCode)")
                errorMessage = "Geçersiz davet kodu"
                foundAlbum = nil
            }
            
        } catch {
            print("JoinAlbumVM: Search error: \(error)")
            errorMessage = "Albüm arama hatası: \(error.localizedDescription)"
            foundAlbum = nil
        }
        
        isLoading = false
    }
    
    func joinAlbum() async {
        guard var album = foundAlbum else {
            await searchAlbum()
            return
        }
        
        guard let currentUID = repo.auth.uid else {
            errorMessage = "Giriş yapmanız gerekiyor"
            return
        }
        
        // Zaten üye kontrolü
        if album.isMember(currentUID) {
            errorMessage = "Bu albümün zaten üyesisiniz"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("JoinAlbumVM: Joining album: \(album.title)")
            
            // Albüme üye ekle
            album.addMember(currentUID)
            
            // Firestore'da güncelle
            try await repo.updateAlbum(album)
            
            print("JoinAlbumVM: Successfully joined album")
            joinSuccess = true
            foundAlbum = album // Güncellenmiş albüm bilgisini göster
            
        } catch {
            print("JoinAlbumVM: Join error: \(error)")
            errorMessage = "Albüme katılma hatası: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    func reset() {
        inviteCode = ""
        foundAlbum = nil
        errorMessage = nil
        joinSuccess = false
        activeIndex = 0
        searchTask?.cancel()
    }
}
