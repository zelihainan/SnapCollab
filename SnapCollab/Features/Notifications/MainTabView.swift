//
//  MainTabView.swift
//  SnapCollab
//
//  Ana tab bar navigasyonu - Bildirim badge'i ile
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.di) var di
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: TabItem = .albums
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Albums Tab
            NavigationStack {
                AlbumsView(vm: AlbumsViewModel(repo: di.albumRepo))
            }
            .tabItem {
                Label("Albümler", systemImage: selectedTab == .albums ? "photo.stack.fill" : "photo.stack")
            }
            .tag(TabItem.albums)
                            
            NotificationsView(notificationRepo: di.notificationRepo)
            .tabItem {
                Label("Bildirimler", systemImage: selectedTab == .notifications ? "bell.fill" : "bell")
            }
            .badge(di.notificationRepo.unreadCount > 0 ? di.notificationRepo.unreadCount : 0)
            .tag(TabItem.notifications)

            NavigationStack {
                ProfileContainerView()
            }
            .tabItem {
                Label("Profil", systemImage: selectedTab == .profile ? "person.fill" : "person")
            }
            .tag(TabItem.profile)
        }
        .tint(.blue)
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

enum TabItem: String, CaseIterable {
    case albums = "albums"
    case notifications = "notifications"
    case profile = "profile"
    
    var title: String {
        switch self {
        case .albums: return "Albümler"
        case .notifications: return "Bildirimler"
        case .profile: return "Profil"
        }
    }
    
    var icon: String {
        switch self {
        case .albums: return "photo.stack"
        case .notifications: return "bell"
        case .profile: return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .albums: return "photo.stack.fill"
        case .notifications: return "bell.fill"
        case .profile: return "person.fill"
        }
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
