//
//  NotificationRepository.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 12.09.2025.
//

import Foundation
import SwiftUI

final class NotificationRepository: ObservableObject {
    private let service: NotificationProviding
    private let authRepo: AuthRepository
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    init(service: NotificationProviding, authRepo: AuthRepository) {
        self.service = service
        self.authRepo = authRepo
    }
    
    func start() {
        guard let userId = authRepo.uid else { return }
        
        Task {
            for await notificationList in service.getNotifications(for: userId) {
                await MainActor.run {
                    self.notifications = notificationList
                    self.unreadCount = notificationList.filter { !$0.isRead }.count
                }
            }
        }
    }
    
    // MARK: - Notification Creation Methods
    
    func notifyPhotoAdded(
        fromUser: User,
        toUserIds: [String],
        album: Album,
        mediaCount: Int = 1
    ) async {
        let photoText = mediaCount == 1 ? "fotoğraf" : "\(mediaCount) fotoğraf"
        let title = "Yeni Fotoğraf"
        let message = "\(fromUser.displayName ?? fromUser.email) \"\(album.title)\" albümüne \(photoText) ekledi"
        
        for userId in toUserIds {
            guard userId != fromUser.uid else { continue }
            
            let notification = AppNotification(
                type: .photoAdded,
                title: title,
                message: message,
                fromUserId: fromUser.uid,
                toUserId: userId,
                albumId: album.id
            )
            
            do {
                try await service.createNotification(notification)
            } catch {
                print("📬 Error creating photo notification: \(error)")
            }
        }
    }
    
    func notifyVideoAdded(
        fromUser: User,
        toUserIds: [String],
        album: Album,
        mediaCount: Int = 1
    ) async {
        let videoText = mediaCount == 1 ? "video" : "\(mediaCount) video"
        let title = "Yeni Video"
        let message = "\(fromUser.displayName ?? fromUser.email) \"\(album.title)\" albümüne \(videoText) ekledi"
        
        for userId in toUserIds {
            guard userId != fromUser.uid else { continue }
            
            let notification = AppNotification(
                type: .videoAdded,
                title: title,
                message: message,
                fromUserId: fromUser.uid,
                toUserId: userId,
                albumId: album.id
            )
            
            do {
                try await service.createNotification(notification)
            } catch {
                print("📬 Error creating video notification: \(error)")
            }
        }
    }
    
    func notifyMemberJoined(
        newUser: User,
        toUserIds: [String],
        album: Album
    ) async {
        let title = "Yeni Üye"
        let message = "\(newUser.displayName ?? newUser.email) \"\(album.title)\" albümüne katıldı"
        
        for userId in toUserIds {
            guard userId != newUser.uid else { continue }
            
            let notification = AppNotification(
                type: .memberJoined,
                title: title,
                message: message,
                fromUserId: newUser.uid,
                toUserId: userId,
                albumId: album.id
            )
            
            do {
                try await service.createNotification(notification)
            } catch {
                print("📬 Error creating member join notification: \(error)")
            }
        }
    }
    
    func notifyAlbumUpdated(
        fromUser: User,
        toUserIds: [String],
        album: Album,
        changeType: String
    ) async {
        let title = "Albüm Güncellendi"
        let message = "\(fromUser.displayName ?? fromUser.email) \"\(album.title)\" albümünde \(changeType)"
        
        for userId in toUserIds {
            guard userId != fromUser.uid else { continue }
            
            let notification = AppNotification(
                type: .albumUpdated,
                title: title,
                message: message,
                fromUserId: fromUser.uid,
                toUserId: userId,
                albumId: album.id
            )
            
            do {
                try await service.createNotification(notification)
            } catch {
                print("📬 Error creating album update notification: \(error)")
            }
        }
    }
    
    // MARK: - Action Methods
    
    func markAsRead(_ notification: AppNotification) async {
        guard let id = notification.id else { return }
        
        do {
            try await service.markAsRead(id)
        } catch {
            print("📬 Error marking notification as read: \(error)")
        }
    }
    
    func markAllAsRead() async {
        guard let userId = authRepo.uid else { return }
        
        do {
            try await service.markAllAsRead(for: userId)
        } catch {
            print("📬 Error marking all notifications as read: \(error)")
        }
    }
    
    func deleteNotification(_ notification: AppNotification) async {
        guard let id = notification.id else { return }
        
        do {
            try await service.deleteNotification(id)
        } catch {
            print("📬 Error deleting notification: \(error)")
        }
    }
}

#if DEBUG
extension NotificationRepository {
    func createTestNotifications() async {
        guard let currentUser = authRepo.currentUser else {
            print("📬 Cannot create test notifications - no current user")
            return
        }
        
        print("📬 Creating test notifications for user: \(currentUser.uid)")
        
        // Test için sahte kullanıcı bilgileri oluştur
        let testFromUsers = [
            ("test-user-1", "John Doe", "john@example.com"),
            ("test-user-2", "Jane Smith", "jane@example.com"),
            ("test-user-3", "Mike Johnson", "mike@example.com"),
            ("test-user-4", "Alice Brown", "alice@example.com"),
            ("test-user-5", "Bob Wilson", "bob@example.com")
        ]
        
        let testNotifications: [AppNotification] = [
            AppNotification(
                type: .photoAdded,
                title: "Yeni Fotoğraf",
                message: "\(testFromUsers[0].1) \"Tatil Fotoğrafları\" albümüne 3 fotoğraf ekledi",
                fromUserId: testFromUsers[0].0,
                toUserId: currentUser.uid,
                albumId: "test-album-1"
            ),
            AppNotification(
                type: .memberJoined,
                title: "Yeni Üye",
                message: "\(testFromUsers[1].1) \"Okul Anıları\" albümüne katıldı",
                fromUserId: testFromUsers[1].0,
                toUserId: currentUser.uid,
                albumId: "test-album-2"
            ),
            AppNotification(
                type: .videoAdded,
                title: "Yeni Video",
                message: "\(testFromUsers[2].1) \"Doğum Günü\" albümüne video ekledi",
                fromUserId: testFromUsers[2].0,
                toUserId: currentUser.uid,
                albumId: "test-album-3"
            ),
            AppNotification(
                type: .albumUpdated,
                title: "Albüm Güncellendi",
                message: "\(testFromUsers[3].1) \"Mezuniyet\" albümünün adını değiştirdi",
                fromUserId: testFromUsers[3].0,
                toUserId: currentUser.uid,
                albumId: "test-album-4"
            ),
            AppNotification(
                type: .albumInvite,
                title: "Albüm Daveti",
                message: "\(testFromUsers[4].1) sizi \"Yaz Kampı\" albümüne davet etti",
                fromUserId: testFromUsers[4].0,
                toUserId: currentUser.uid,
                albumId: "test-album-5"
            )
        ]
        
        for notification in testNotifications {
            do {
                try await service.createNotification(notification)
                print("📬 Test notification created successfully: \(notification.type.rawValue)")
                
                // Test bildirimlerini aralıklı oluştur
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 saniye bekle
                
            } catch {
                print("📬 Test notification error: \(error)")
            }
        }
        
        print("📬 All test notifications creation completed!")
    }
    
    // Basit test bildirimi oluştur
    func createSingleTestNotification() async {
        guard let currentUser = authRepo.currentUser else { return }
        
        let notification = AppNotification(
            type: .photoAdded,
            title: "Test Bildirim",
            message: "Bu bir test bildirimidir - \(Date().formatted())",
            fromUserId: "test-sender",
            toUserId: currentUser.uid,
            albumId: "test-album"
        )
        
        do {
            try await service.createNotification(notification)
            print("📬 Single test notification created successfully")
        } catch {
            print("📬 Single test notification error: \(error)")
        }
    }
}
#endif
