//
//  NotificationSettingsSheet.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 15.09.2025.
//

import SwiftUI
import UserNotifications

struct NotificationSettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("photoNotificationsEnabled") private var photoNotificationsEnabled = true
    @AppStorage("videoNotificationsEnabled") private var videoNotificationsEnabled = true
    @AppStorage("memberNotificationsEnabled") private var memberNotificationsEnabled = true
    @AppStorage("albumUpdateNotificationsEnabled") private var albumUpdateNotificationsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("badgeEnabled") private var badgeEnabled = true
    
    @State private var systemNotificationsEnabled = false
    @State private var showPermissionAlert = false
    @State private var showSettingsAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(systemNotificationsEnabled ? .green.opacity(0.1) : .red.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: systemNotificationsEnabled ? "bell.fill" : "bell.slash.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(systemNotificationsEnabled ? .green : .red)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sistem Bildirimleri")
                                .font(.body)
                                .foregroundStyle(.primary)
                            
                            Text(systemNotificationsEnabled ? "Etkin" : "Kapalı - Ayarlardan açın")
                                .font(.caption)
                                .foregroundStyle(systemNotificationsEnabled ? .green : .red)
                        }
                        
                        Spacer()
                        
                        if !systemNotificationsEnabled {
                            Button("Aç") {
                                openSystemSettings()
                            }
                            .font(.caption)
                            .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Sistem Ayarları")
                } footer: {
                    Text("Bildirimlerin çalışması için sistem ayarlarından izin vermeniz gerekir")
                }
                
                Section {
                    NotificationToggleRow(
                        icon: "bell.fill",
                        title: "Tüm Bildirimler",
                        subtitle: "Uygulama bildirimlerini etkinleştir/kapat",
                        iconColor: .blue,
                        isEnabled: $notificationsEnabled
                    )
                    .disabled(!systemNotificationsEnabled)
                } header: {
                    Text("Genel Ayarlar")
                }
                
                if notificationsEnabled && systemNotificationsEnabled {
                    Section {
                        NotificationToggleRow(
                            icon: "photo.fill",
                            title: "Yeni Fotoğraflar",
                            subtitle: "Albüme fotoğraf eklendiğinde bildir",
                            iconColor: .blue,
                            isEnabled: $photoNotificationsEnabled
                        )
                        
                        NotificationToggleRow(
                            icon: "video.fill",
                            title: "Yeni Videolar",
                            subtitle: "Albüme video eklendiğinde bildir",
                            iconColor: .purple,
                            isEnabled: $videoNotificationsEnabled
                        )
                        
                        NotificationToggleRow(
                            icon: "person.badge.plus",
                            title: "Yeni Üyeler",
                            subtitle: "Albüme yeni üye katıldığında bildir",
                            iconColor: .green,
                            isEnabled: $memberNotificationsEnabled
                        )
                        
                        NotificationToggleRow(
                            icon: "pencil.circle.fill",
                            title: "Albüm Güncellemeleri",
                            subtitle: "Albüm bilgileri değiştiğinde bildir",
                            iconColor: .orange,
                            isEnabled: $albumUpdateNotificationsEnabled
                        )
                    } header: {
                        Text("Bildirim Türleri")
                    }
                    
                    Section {
                        NotificationToggleRow(
                            icon: "speaker.wave.2.fill",
                            title: "Sesler",
                            subtitle: "Bildirim sesleri",
                            iconColor: .red,
                            isEnabled: $soundEnabled
                        )
                        
                        NotificationToggleRow(
                            icon: "app.badge",
                            title: "Uygulama Rozeti",
                            subtitle: "Okunmamış bildirim sayısını göster",
                            iconColor: .red,
                            isEnabled: $badgeEnabled
                        )
                    } header: {
                        Text("Görünüm ve Ses")
                    }
                }
                
                if notificationsEnabled && systemNotificationsEnabled {
                    Section {
                        Button(action: sendTestNotification) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(.purple.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.purple)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Test Bildirimi Gönder")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    Text("Ayarlarınızı test edin")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } header: {
                        Text("Test")
                    }
                }
            }
            .navigationTitle("Bildirim Ayarları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
            .onAppear {
                checkNotificationPermission()
            }
            .alert("Bildirimler Kapalı", isPresented: $showPermissionAlert) {
                Button("Ayarlara Git") {
                    openSystemSettings()
                }
                Button("İptal", role: .cancel) { }
            } message: {
                Text("Bildirimleri açmak için Ayarlar > SnapCollab > Bildirimler'e gidin")
            }
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                systemNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func openSystemSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func sendTestNotification() {
        guard systemNotificationsEnabled else {
            showPermissionAlert = true
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Test Bildirimi"
        content.body = "Bildirim ayarlarınız çalışıyor!"
        content.sound = soundEnabled ? .default : nil
        content.badge = badgeEnabled ? 1 : nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Test notification error: \(error)")
            } else {
                print("Test notification scheduled")
                
                DispatchQueue.main.async {
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                }
            }
        }
    }
}

struct NotificationToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    func checkPermission() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    func scheduleNotification(
        title: String,
        body: String,
        identifier: String,
        delay: TimeInterval = 0
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(delay, 1),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error)")
            }
        }
    }
}
