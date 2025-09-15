//
//  NavigationCoordinator.swift
//  SnapCollab
//

import SwiftUI
import Foundation

@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: TabItem = .albums
    @Published var albumsPath = NavigationPath()
    @Published var shouldNavigateToAlbum: String?
    
    func navigateToAlbum(_ albumId: String) {
        print("NavigationCoordinator: Navigating to album: \(albumId)")
        
        selectedTab = .albums
        albumsPath = NavigationPath()
        shouldNavigateToAlbum = albumId
    }
    
    func clearNavigationRequest() {
        shouldNavigateToAlbum = nil
    }
    
    func switchToTab(_ tab: TabItem) {
        selectedTab = tab
    }
    
    func pushToAlbumDetail(albumId: String) {
        albumsPath.append(albumId)
    }
    
    func popToRoot() {
        albumsPath = NavigationPath()
    }
}

enum TabItem: String, CaseIterable {
    case albums = "albums"
    case notifications = "notifications"
    case profile = "profile"
}
