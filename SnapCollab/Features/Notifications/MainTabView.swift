//
//  MainTabView.swift
//  SnapCollab
//
//  Ana tab bar navigasyonu - Deep Navigation ile
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.di) var di
    @EnvironmentObject var appState: AppState
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    var body: some View {
        TabView(selection: $navigationCoordinator.selectedTab) {
            // Albums Tab - NavigationStack ile (ID tabanlı)
            NavigationStack(path: $navigationCoordinator.albumsPath) {
                AlbumsView(vm: AlbumsViewModel(repo: di.albumRepo))
                    .navigationDestination(for: String.self) { albumId in
                        // Album ID'sinden Album objesini bul ve detay sayfasını göster
                        AlbumDetailViewWrapper(albumId: albumId, di: di)
                    }
            }
            .tabItem {
                Label("Albümler", systemImage: navigationCoordinator.selectedTab == .albums ? "photo.stack.fill" : "photo.stack")
            }
            .tag(TabItem.albums)
            
            // Notifications Tab - Navigation Coordinator ile
            NotificationsView(
                notificationRepo: di.notificationRepo,
                navigationCoordinator: navigationCoordinator
            )
            .tabItem {
                Label("Bildirimler", systemImage: navigationCoordinator.selectedTab == .notifications ? "bell.fill" : "bell")
            }
            .badge(di.notificationRepo.unreadCount > 0 ? di.notificationRepo.unreadCount : 0)
            .tag(TabItem.notifications)

            NavigationStack {
                ProfileContainerView()
            }
            .tabItem {
                Label("Profil", systemImage: navigationCoordinator.selectedTab == .profile ? "person.fill" : "person")
            }
            .tag(TabItem.profile)
        }
        .tint(.blue)
        .environmentObject(navigationCoordinator) // Environment'a inject et
        .onAppear {
            setupTabBarAppearance()
            di.notificationRepo.start()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Shadow for modern look
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        
        // Selected item styling
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Normal item styling
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Profile Container View
struct ProfileContainerView: View {
    @Environment(\.di) var di
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        let profileVM = ProfileViewModel(authRepo: di.authRepo, mediaRepo: di.mediaRepo)
        let sessionVM = SessionViewModel(auth: di.authRepo, state: appState)
        
        ProfileView(vm: profileVM)
            .onAppear {
                profileVM.setSessionViewModel(sessionVM)
            }
            .navigationBarHidden(true)
    }
}
