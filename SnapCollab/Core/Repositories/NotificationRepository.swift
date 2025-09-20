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
                    self.notifications = notificationList.sorted { $0.createdAt > $1.createdAt }
                    self.unreadCount = notificationList.filter { !$0.isRead }.count
                }
            }
        }
    }
    
    func stop() {
        // Observable pattern'i durdurmak için
        notifications = []
        unreadCount = 0
    }
}

// MARK: - Media Notifications
extension NotificationRepository {
    
    func notifyPhotoAdded(
        fromUser: User,
        toUserIds: [String],
        album: Album,
        mediaCount: Int = 1
    ) async {
        let photoText = mediaCount == 1 ? "fotoğraf" : "\(mediaCount) fotoğraf"
        let title = "Yeni Fotoğraf"
        let message = "\(fromUser.displayName ?? fromUser.email) \"\(album.title)\" albümüne \(photoText) ekledi"
        
        await createNotificationsForUsers(
            type: .photoAdded,
            title: title,
            message: message,
            fromUser: fromUser,
            toUserIds: toUserIds,
            albumId: album.id
        )
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
        
        await createNotificationsForUsers(
            type: .videoAdded,
            title: title,
            message: message,
            fromUser: fromUser,
            toUserIds: toUserIds,
            albumId: album.id
        )
    }
    
    func notifyMixedMediaAdded(
        fromUser: User,
        toUserIds: [String],
        album: Album,
        photoCount: Int,
        videoCount: Int
    ) async {
        var mediaText = ""
        if photoCount > 0 && videoCount > 0 {
            mediaText = "\(photoCount) fotoğraf ve \(videoCount) video"
        } else if photoCount > 0 {
            mediaText = photoCount == 1 ? "fotoğraf" : "\(photoCount) fotoğraf"
        } else if videoCount > 0 {
            mediaText = videoCount == 1 ? "video" : "\(videoCount) video"
        }
        
        let title = "Yeni Medya"
        let message = "\(fromUser.displayName ?? fromUser.email) \"\(album.title)\" albümüne \(mediaText) ekledi"
        
        await createNotificationsForUsers(
            type: .photoAdded, // Mixed için photo type kullanıyoruz
            title: title,
            message: message,
            fromUser: fromUser,
            toUserIds: toUserIds,
            albumId: album.id
        )
    }
}

// MARK: - Album & Member Notifications
extension NotificationRepository {
    
    func notifyMemberJoined(
        newUser: User,
        toUserIds: [String],
        album: Album
    ) async {
        let title = "Yeni Üye"
        let message = "\(newUser.displayName ?? newUser.email) \"\(album.title)\" albümüne katıldı"
        
        await createNotificationsForUsers(
            type: .memberJoined,
            title: title,
            message: message,
            fromUser: newUser,
            toUserIds: toUserIds,
            albumId: album.id
        )
    }
    
    func notifyAlbumUpdated(
        fromUser: User,
        toUserIds: [String],
        album: Album,
        changeType: String
    ) async {
        let title = "Albüm Güncellendi"
        let message = "\(fromUser.displayName ?? fromUser.email) \"\(album.title)\" albümünde \(changeType)"
        
        await createNotificationsForUsers(
            type: .albumUpdated,
            title: title,
            message: message,
            fromUser: fromUser,
            toUserIds: toUserIds,
            albumId: album.id
        )
    }
    
    func notifyOwnershipTransferred(
        fromUser: User,
        toUserId: String,
        album: Album,
        oldOwnerId: String
    ) async {
        // Yeni owner'a özel bildirim
        let newOwnerNotification = AppNotification(
            type: .ownershipTransferred,
            title: "Albüm Yöneticisi Oldunuz",
            message: "\(fromUser.displayName ?? fromUser.email) sizi \"\(album.title)\" albümünün yöneticisi yaptı",
            fromUserId: fromUser.uid,
            toUserId: toUserId,
            albumId: album.id
        )
        
        do {
            try await service.createNotification(newOwnerNotification)
            print("NotificationRepo: Ownership transfer notification sent to new owner")
        } catch {
            print("Error creating ownership transfer notification: \(error)")
        }
        
        // Diğer üyelere genel bildirim
        let otherMemberIds = album.members.filter { $0 != oldOwnerId && $0 != toUserId }
        
        if !otherMemberIds.isEmpty {
            await createNotificationsForUsers(
                type: .albumUpdated,
                title: "Albüm Yöneticisi Değişti",
                message: "\"\(album.title)\" albümünün yöneticisi değişti",
                fromUser: fromUser,
                toUserIds: otherMemberIds,
                albumId: album.id
            )
        }
    }
}

// MARK: - Notification Management
extension NotificationRepository {
    
    func markAsRead(_ notification: AppNotification) async {
        guard let id = notification.id else { return }
        
        do {
            try await service.markAsRead(id)
            print("NotificationRepo: Marked notification as read: \(id)")
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }
    
    func markAllAsRead() async {
        guard let userId = authRepo.uid else { return }
        
        do {
            try await service.markAllAsRead(for: userId)
            print("NotificationRepo: Marked all notifications as read for user: \(userId)")
        } catch {
            print("Error marking all notifications as read: \(error)")
        }
    }
    
    func deleteNotification(_ notification: AppNotification) async {
        guard let id = notification.id else { return }
        
        do {
            try await service.deleteNotification(id)
            print("NotificationRepo: Deleted notification: \(id)")
        } catch {
            print("Error deleting notification: \(error)")
        }
    }
    
    func deleteAllNotifications() async {
        guard let userId = authRepo.uid else { return }
        
        do {
            let notificationsToDelete = notifications.filter { $0.toUserId == userId }
            
            for notification in notificationsToDelete {
                if let id = notification.id {
                    try await service.deleteNotification(id)
                }
            }
            
            print("NotificationRepo: Deleted all notifications for user: \(userId)")
        } catch {
            print("Error deleting all notifications: \(error)")
        }
    }
}

// MARK: - Helper Methods
extension NotificationRepository {
    
    private func createNotificationsForUsers(
        type: NotificationType,
        title: String,
        message: String,
        fromUser: User,
        toUserIds: [String],
        albumId: String? = nil,
        mediaId: String? = nil
    ) async {
        for userId in toUserIds {
            guard userId != fromUser.uid else { continue }
            
            let notification = AppNotification(
                type: type,
                title: title,
                message: message,
                fromUserId: fromUser.uid,
                toUserId: userId,
                albumId: albumId,
                mediaId: mediaId
            )
            
            do {
                try await service.createNotification(notification)
            } catch {
                print("Error creating \(type.rawValue) notification for user \(userId): \(error)")
            }
        }
        
        print("NotificationRepo: Created \(type.rawValue) notifications for \(toUserIds.count) users")
    }
    
    var groupedNotifications: [String: [AppNotification]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: notifications) { notification in
            if calendar.isDateInToday(notification.createdAt) {
                return "Bugün"
            } else if calendar.isDateInYesterday(notification.createdAt) {
                return "Dün"
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "tr_TR")
                formatter.dateFormat = "d MMMM"
                return formatter.string(from: notification.createdAt)
            }
        }
        
        return grouped.mapValues { $0.sorted { $0.createdAt > $1.createdAt } }
    }
    
    var sortedGroupKeys: [String] {
        let keys = Array(groupedNotifications.keys)
        return keys.sorted { key1, key2 in
            if key1 == "Bugün" { return true }
            if key2 == "Bugün" { return false }
            if key1 == "Dün" { return true }
            if key2 == "Dün" { return false }
            return key1 > key2
        }
    }
    
    func getUnreadNotifications() -> [AppNotification] {
        return notifications.filter { !$0.isRead }
    }
    
    func getNotificationsForAlbum(_ albumId: String) -> [AppNotification] {
        return notifications.filter { $0.albumId == albumId }
    }
    
    func hasUnreadNotificationsForAlbum(_ albumId: String) -> Bool {
        return notifications.contains { $0.albumId == albumId && !$0.isRead }
    }
}
