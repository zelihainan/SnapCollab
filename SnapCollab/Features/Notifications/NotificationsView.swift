//
//  NotificationsView.swift
//  SnapCollab
//
//  Layout düzeltilmiş - Bildirimler yukarıdan başlıyor
//

import SwiftUI

struct NotificationsView: View {
    @StateObject private var notificationRepo: NotificationRepository
    @Environment(\.di) var di
    @State private var showClearAllAlert = false
    
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: markAllAsRead) {
                            Label("Tümünü Okundu İşaretle", systemImage: "checkmark.circle")
                        }
                        .disabled(notificationRepo.unreadCount == 0)
                        
                        Divider()
                        
                        Button("Bildirimleri Temizle", role: .destructive) {
                            showClearAllAlert = true
                        }
                        .disabled(notificationRepo.notifications.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .alert("Tüm Bildirimleri Temizle", isPresented: $showClearAllAlert) {
                Button("İptal", role: .cancel) { }
                Button("Temizle", role: .destructive) {
                    clearAllNotifications()
                }
            } message: {
                Text("Tüm bildirimleri kalıcı olarak silmek istediğinizden emin misiniz?")
            }
        }
        .onAppear {
            notificationRepo.start()
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "bell.slash")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(.blue)
                }
                
                VStack(spacing: 16) {
                    Text("Henüz Bildirim Yok")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    VStack(spacing: 8) {
                        Text("Arkadaşlarınız albümlere fotoğraf eklediğinde,")
                        Text("albüme yeni üye katıldığında veya")
                        Text("albüm güncellendiğinde burada göreceksiniz.")
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    
                    Text("İpucu")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    tipRow(icon: "photo.badge.plus", text: "Albümlere fotoğraf ekleyin", color: .blue)
                    tipRow(icon: "person.badge.plus", text: "Arkadaşlarınızı davet edin", color: .green)
                    tipRow(icon: "heart", text: "Fotoğrafları favorilerinize ekleyin", color: .red)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func tipRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Notifications List (Fixed - starts from top)
    private var notificationsList: some View {
        List {
            // Unread count header - en üstte
            if notificationRepo.unreadCount > 0 {
                Section {
                    EmptyView()
                } header: {
                    unreadCountHeader
                        .listRowInsets(EdgeInsets())
                        .padding(.top, -20) // Üst boşluğu azalt
                }
            }
            
            // Notifications list
            ForEach(groupedNotifications.keys.sorted(by: >), id: \.self) { date in
                Section {
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
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task {
                                    await notificationRepo.deleteNotification(notification)
                                }
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    // Section header - "Bugün" vs
                    HStack {
                        Text(relativeDateString(from: date))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, notificationRepo.unreadCount > 0 ? 8 : -10) // Unread varsa az, yoksa daha az spacing
                    .padding(.bottom, 4)
                    .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }
    
    private var unreadCountHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
                
                Text("\(notificationRepo.unreadCount) okunmamış bildirim")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }
            
            Spacer()
            
            Button("Tümünü Okundu İşaretle") {
                markAllAsRead()
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBlue).opacity(0.1))
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
    
    private func relativeDateString(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "tr_TR")
        
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        if Calendar.current.isDateInToday(date) {
            return "Bugün"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Dün"
        } else if Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.contains(date) == true {
            let weekFormatter = DateFormatter()
            weekFormatter.dateFormat = "EEEE"
            weekFormatter.locale = Locale(identifier: "tr_TR")
            return weekFormatter.string(from: date)
        } else {
            return dateString
        }
    }
    
    // MARK: - Actions
    private func handleNotificationTap(_ notification: AppNotification) {
        Task {
            await notificationRepo.markAsRead(notification)
        }
        
        if let albumId = notification.albumId {
            print("📬 Navigate to album: \(albumId)")
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func markAllAsRead() {
        Task {
            await notificationRepo.markAllAsRead()
        }
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func clearAllNotifications() {
        print("Clear all notifications - to be implemented")
    }
}

// MARK: - Enhanced Notification Row View (Unchanged)
struct NotificationRowView: View {
    let notification: AppNotification
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(notification.isRead ? 0.1 : 0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(iconBackgroundColor.opacity(notification.isRead ? 0.3 : 0.5), lineWidth: notification.isRead ? 1 : 2)
                    )
                
                Image(systemName: notification.type.icon)
                    .font(.system(size: 18, weight: notification.isRead ? .regular : .medium))
                    .foregroundStyle(iconBackgroundColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(notification.title)
                        .font(.headline)
                        .fontWeight(notification.isRead ? .medium : .semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text(relativeTimeString)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        
                        if !notification.isRead {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                
                Text(notification.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(notification.isRead ? Color.clear : Color(.systemBlue).opacity(0.05))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                onTap()
            }
        }
        .contextMenu {
            Button(notification.isRead ? "Okunmadı İşaretle" : "Okundu İşaretle") {
                onTap()
            }
            
            if let albumId = notification.albumId {
                Button("Albüme Git") {
                    print("Navigate to album: \(albumId)")
                }
            }
            
            Divider()
            
            Button("Sil", role: .destructive) {
                onDelete()
            }
        }
        .scaleEffect(notification.isRead ? 1.0 : 1.02)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: notification.isRead)
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
