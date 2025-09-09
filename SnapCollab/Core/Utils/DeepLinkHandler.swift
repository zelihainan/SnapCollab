import Foundation
import SwiftUI

class DeepLinkHandler: ObservableObject {
    @Published var pendingInviteCode: String?
    @Published var shouldShowJoinView = false
    
    func handleURL(_ url: URL) {
        print("DeepLink: Handling URL: \(url.absoluteString)")
        
        // snapcollab://invite/ABC123 format
        guard url.scheme == "snapcollab" else {
            print("DeepLink: Invalid scheme: \(url.scheme ?? "nil")")
            return
        }
        
        let pathComponents = url.pathComponents
        print("DeepLink: Path components: \(pathComponents)")
        
        // "/invite/CODE" formatını kontrol et
        if pathComponents.count >= 3 && pathComponents[1] == "invite" {
            let inviteCode = pathComponents[2].uppercased()
            print("DeepLink: Found invite code: \(inviteCode)")
            
            // Kod formatını validate et (6 karakter, alfanumerik)
            if isValidInviteCode(inviteCode) {
                DispatchQueue.main.async {
                    self.pendingInviteCode = inviteCode
                    self.shouldShowJoinView = true
                }
                print("DeepLink: Valid invite code, showing join view")
            } else {
                print("DeepLink: Invalid invite code format: \(inviteCode)")
            }
        }
        
        // snapcollab://join?code=ABC123 format (alternatif)
        else if url.host == "join" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let codeParam = components?.queryItems?.first(where: { $0.name == "code" })?.value {
                let inviteCode = codeParam.uppercased()
                print("DeepLink: Found invite code from query: \(inviteCode)")
                
                if isValidInviteCode(inviteCode) {
                    DispatchQueue.main.async {
                        self.pendingInviteCode = inviteCode
                        self.shouldShowJoinView = true
                    }
                }
            }
        }
        
        else {
            print("DeepLink: Unknown URL format: \(url.absoluteString)")
        }
    }
    
    private func isValidInviteCode(_ code: String) -> Bool {
        // 6 karakter, sadece harf ve rakam
        guard code.count == 6 else { return false }
        return code.allSatisfy { $0.isLetter || $0.isNumber }
    }
    
    func clearPendingInvite() {
        pendingInviteCode = nil
        shouldShowJoinView = false
    }
    
    func generateInviteLink(for album: Album) -> String? {
        guard let inviteCode = album.inviteCode else { return nil }
        return "snapcollab://invite/\(inviteCode)"
    }
    
    func generateShareableText(for album: Album) -> String? {
        guard let inviteCode = album.inviteCode else { return nil }
        
        return """
        🎉 "\(album.title)" albümüne davet edildiniz!
        
        📱 SnapCollab uygulamasını indirin
        🔗 Bu linke tıklayın: snapcollab://invite/\(inviteCode)
        
        Veya uygulama içinde bu kodu girin: \(inviteCode)
        
        SnapCollab ile fotoğraflarınızı kolayca paylaşın! 📸
        """
    }
}
