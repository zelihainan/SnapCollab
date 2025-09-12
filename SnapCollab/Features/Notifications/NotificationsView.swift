//
//  NotificationsView.swift
//  SnapCollab
//
//  Bildirimler sayfası - Test butonu eklendi
//

import SwiftUI

struct NotificationsView: View {
    @StateObject private var notificationRepo: NotificationRepository
    @Environment(\.di) var di
    
    init(notificationRepo: NotificationRepository) {
        _notificationRepo = StateObject(wrappedValue: notificationRepo)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if notificationRepo.notifications.isEmpty {
                    emptyState
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    #if DEBUG
                    Button("Test") {
                        Task {
                            await notificationRepo.createTestNotifications()
                        }
                    }
                    .foregroundStyle(.blue)
                    #endif
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Tümünü Okundu İşaretle") {
                            Task {
                                await notificationRepo.markAllAsRead()
                            }
                        }
                        .disabled(notificationRepo.unreadCount == 0)
                        
                        #if DEBUG
                        Button("Test Bildirimleri Oluştur") {
                            Task {
                                await notificationRepo.createTestNotifications()
                            }
                        }
                        #endif
                        
                        Button("Bildirimleri Temizle", role: .destructive) {
                            // TODO: Implement clear all
                        }
                        .disabled(notificationRepo.notifications.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            notificationRepo.start()
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("Bildirim Yok")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Henüz hiç bildirim almadınız. Arkadaşlarınız albümlere fotoğraf eklediğinde burada göreceksiniz.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            #if DEBUG
            Button("Test Bildirimleri Oluştur") {
                Task {
                    await notificationRepo.createTestNotifications()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Notifications List
    private var notificationsList: some View {
        List {
            ForEach(groupedNotifications.keys.sorted(by: >), id: \.self) { date in
                Section(header: sectionHeader(for: date)) {
                    ForEach(groupedNotifications[date] ?? []) { notification in
                        NotificationRowView(
                            notification: notification,
                            onTap: {
                                handleNotificationTap(notification)
                            },
                            onDelete: {
                                Task {
                                    await notificationRepo.deleteNotification(notification)
                                }
                            }
                        )
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            // Otomatik refresh - repository zaten real-time
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }
    
    // MARK: - Grouped Notifications
    private var groupedNotifications: [String: [AppNotification]] {
        Dictionary(grouping: notificationRepo.notifications) { notification in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: notification.createdAt)
        }
    }
    
    private func sectionHeader(for dateString: String) -> some View {
        Text(relativeDateString(from: dateString))
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(nil)
    }
    
    private func relativeDateString(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "tr_TR")
        
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        if Calendar.current.isDateInToday(date) {
            return "Bugün"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Dün"
        } else {
            return dateString
        }
    }
    
    // MARK: - Actions
    private func handleNotificationTap(_ notification: AppNotification) {
        // Mark as read
        Task {
            await notificationRepo.markAsRead(notification)
        }
        
        // Navigate to relevant screen
        if let albumId = notification.albumId {
            // TODO: Navigate to album detail
            print("📬 Navigate to album: \(albumId)")
        }
    }
}

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: AppNotification
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: notification.type.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconBackgroundColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if !notification.isRead {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(notification.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                Text(relativeTimeString)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
        .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button(notification.isRead ? "Okunmadı İşaretle" : "Okundu İşaretle") {
                // Toggle read status
                Task {
                    if notification.isRead {
                        // TODO: Mark as unread
                    } else {
                        // Already handled in onTap
                    }
                }
            }
            
            Button("Sil", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private var iconBackgroundColor: Color {
        switch notification.type.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        default: return .gray
        }
    }
    
    private var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.localizedString(for: notification.createdAt, relativeTo: Date())
    }
}

// MARK: - Badge View for Tab Bar
struct NotificationBadgeView: View {
    let count: Int
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell")
                .font(.system(size: 24))
            
            if count > 0 {
                ZStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 18, height: 18)
                    
                    Text("\(min(count, 99))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(x: 8, y: -8)
            }
        }
    }
}
