//
//  NavigationCoordinator.swift (Alternative - ID Based)
//  SnapCollab
//
//  Deep navigation sistemi - ID tabanlı (daha temiz)
//

import SwiftUI
import Foundation

@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: TabItem = .albums
    @Published var albumsPath = NavigationPath()
    @Published var shouldNavigateToAlbum: String?
    
    // Ana navigation action
    func navigateToAlbum(_ albumId: String) {
        print("🧭 NavigationCoordinator: Navigating to album: \(albumId)")
        
        // Önce Albums tab'ına geç
        selectedTab = .albums
        
        // Path'i temizle
        albumsPath = NavigationPath()
        
        // Albumı set et - bu AlbumsView'da dinlenecek
        shouldNavigateToAlbum = albumId
    }
    
    func clearNavigationRequest() {
        shouldNavigateToAlbum = nil
    }
    
    // Tab switching
    func switchToTab(_ tab: TabItem) {
        selectedTab = tab
    }
    
    // Albums navigation helpers - ID tabanlı
    func pushToAlbumDetail(albumId: String) {
        albumsPath.append(albumId)
    }
    
    func popToRoot() {
        albumsPath = NavigationPath()
    }
}

// Tab enum
enum TabItem: String, CaseIterable {
    case albums = "albums"
    case notifications = "notifications"
    case profile = "profile"
}
