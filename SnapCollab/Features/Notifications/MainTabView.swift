//
//  MainTabView.swift
//  SnapCollab
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.di) var di
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    var body: some View {
        ZStack {
            // Elevated dark background'ı zorla uygula
            themeManager.backgroundColor.ignoresSafeArea(.all)
            
            TabView(selection: $navigationCoordinator.selectedTab) {
                NavigationStack(path: $navigationCoordinator.albumsPath) {
                    AlbumsView(vm: AlbumsViewModel(repo: di.albumRepo))
                        .background(themeManager.backgroundColor.ignoresSafeArea())
                        .navigationDestination(for: String.self) { albumId in
                            AlbumDetailViewWrapper(albumId: albumId, di: di)
                                .background(themeManager.backgroundColor.ignoresSafeArea())
                        }
                }
                .tabItem {
                    Label("Albümler", systemImage: navigationCoordinator.selectedTab == .albums ? "photo.stack.fill" : "photo.stack")
                }
                .tag(TabItem.albums)
                
                NotificationsView(
                    notificationRepo: di.notificationRepo,
                    navigationCoordinator: navigationCoordinator
                )
                .background(themeManager.backgroundColor.ignoresSafeArea())
                .tabItem {
                    Label("Bildirimler", systemImage: navigationCoordinator.selectedTab == .notifications ? "bell.fill" : "bell")
                }
                .badge(di.notificationRepo.unreadCount > 0 ? di.notificationRepo.unreadCount : 0)
                .tag(TabItem.notifications)

                NavigationStack {
                    ProfileContainerView()
                        .background(themeManager.backgroundColor.ignoresSafeArea())
                }
                .tabItem {
                    Label("Profil", systemImage: navigationCoordinator.selectedTab == .profile ? "person.fill" : "person")
                }
                .tag(TabItem.profile)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea(.all))
        }
        .tint(.blue)
        .environmentObject(navigationCoordinator)
        .onAppear {
            setupTabBarAppearance()
            di.notificationRepo.start()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Theme göre background rengi ayarla
        switch themeManager.colorSchemePreference {
        case .elevatedDark:
            appearance.backgroundColor = UIColor.systemGray5
        default:
            appearance.backgroundColor = UIColor.systemBackground
        }
        
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

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
