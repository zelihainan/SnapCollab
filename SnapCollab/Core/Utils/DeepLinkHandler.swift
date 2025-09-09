//
//  DeepLinkHandler.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 9.09.2025.
//

import Foundation
import SwiftUI

class DeepLinkHandler: ObservableObject {
    @Published var pendingInviteCode: String?
    
    func handleURL(_ url: URL) {
        print("DeepLink: Handling URL: \(url.absoluteString)")
        // Şimdilik sadece log'la, implementation sonra
    }
    
    func clearPendingInvite() {
        pendingInviteCode = nil
    }
}
