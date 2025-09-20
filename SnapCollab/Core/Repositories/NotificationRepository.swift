//
//  NotificationRepository.swift - Toplu Bildirim Sistemi
//  SnapCollab
//

import Foundation
import SwiftUI

final class NotificationRepository: ObservableObject {
    private let service: NotificationProviding
    private let authRepo: AuthRepository
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    // Toplu bildirim yönetimi için
    private let batchingTimeWindow: TimeInterval = 300 // 5 dakika
    private var pendingBatches: [String: NotificationBatch] = [:]
    private var batchTimers: [String: Timer] = [:]
    
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
        
        // Bekleyen batch timer'ları temizle
        batchTimers.values.forEach { $0.invalidate() }
        batchTimers.removeAll()
        pendingBatches.removeAll()
    }
}

// MARK: - Batch Notification Structure
private struct NotificationBatch {
    let albumId: String
    let fromUserId: String
    let albumTitle: String
    var photoCount: Int = 0
    var videoCount: Int = 0
    var firstCreatedAt: Date
    var lastCreatedAt: Date
    
    mutating func addPhoto() {
        photoCount += 1
        lastCreatedAt = Date()
    }
    
    mutating func addVideo() {
        videoCount += 1
        lastCreatedAt = Date()
    }
    
    var totalMediaCount: Int {
        photoCount + videoCount
    }
    
    var batchKey: String {
        return "\(fromUserId)_\(albumId)"
    }
}

// MARK: - Toplu Medya Bildirimleri
extension NotificationRepository {
    
    /// Toplu fotoğraf bildirimi - batch mantığı ile
    func notifyPhotoAddedBatch(
        fromUser: User,
        toUserIds: [String],
        album: Album
    ) async {
        let batchKey = "\(fromUser.uid)_\(album.id ?? "")"
        
        await MainActor.run {
            // Mevcut batch'i güncelle veya yeni oluştur
            if var existingBatch = pendingBatches[batchKey] {
                existingBatch.addPhoto()
                pendingBatches[batchKey] = existingBatch
                
                // Timer'ı yenile
                batchTimers[batchKey]?.invalidate()
            } else {
                // Yeni batch oluştur
                let newBatch = NotificationBatch(
                    albumId: album.id ?? "",
                    fromUserId: fromUser.uid,
                    albumTitle: album.title,
                    photoCount: 1,
                    videoCount: 0,
                    firstCreatedAt: Date(),
                    lastCreatedAt: Date()
                )
                pendingBatches[batchKey] = newBatch
            }
            
            // Batch timer'ını başlat/yenile
            startBatchTimer(batchKey: batchKey, toUserIds: toUserIds)
        }
    }
    
    /// Toplu video bildirimi - batch mantığı ile
    func notifyVideoAddedBatch(
        fromUser: User,
        toUserIds: [String],
        album: Album
    ) async {
        let batchKey = "\(fromUser.uid)_\(album.id ?? "")"
        
        await MainActor.run {
            // Mevcut batch'i güncelle veya yeni oluştur
            if var existingBatch = pendingBatches[batchKey] {
                existingBatch.addVideo()
                pendingBatches[batchKey] = existingBatch
                
                // Timer'ı yenile
                batchTimers[batchKey]?.invalidate()
            } else {
                // Yeni batch oluştur
                let newBatch = NotificationBatch(
                    albumId: album.id ?? "",
                    fromUserId: fromUser.uid,
                    albumTitle: album.title,
                    photoCount: 0,
                    videoCount: 1,
                    firstCreatedAt: Date(),
                    lastCreatedAt: Date()
                )
                pendingBatches[batchKey] = newBatch
            }
            
            // Batch timer'ını başlat/yenile
            startBatchTimer(batchKey: batchKey, toUserIds: toUserIds)
        }
    }
    
    /// Batch timer'ını başlat
    private func startBatchTimer(batchKey: String, toUserIds: [String]) {
        let timer = Timer.scheduledTimer(withTimeInterval: batchingTimeWindow, repeats: false) { [weak self] _ in
            Task {
                await self?.processBatch(batchKey: batchKey, toUserIds: toUserIds)
            }
        }
        batchTimers[batchKey] = timer
    }
    
    /// Batch'i işle ve bildirim gönder
    private func processBatch(batchKey: String, toUserIds: [String]) async {
        await MainActor.run {
            guard let batch = pendingBatches[batchKey] else { return }
            
            // Batch'i temizle
            pendingBatches.removeValue(forKey: batchKey)
            batchTimers[batchKey]?.invalidate()
            batchTimers.removeValue(forKey: batchKey)
            
            // Toplu bildirim gönder
            Task {
                await self.sendBatchNotification(batch: batch, toUserIds: toUserIds)
            }
        }
    }
    
    /// Toplu bildirimi gönder
    private func sendBatchNotification(batch: NotificationBatch, toUserIds: [String]) async {
        guard let fromUser = try? await FirestoreUserService().getUser(uid: batch.fromUserId) else { return }
        
        let (title, message) = generateBatchMessage(batch: batch, fromUser: fromUser)
        let notificationType: NotificationType = batch.photoCount > 0 ? .photoAdded : .videoAdded
        
        await createNotificationsForUsers(
            type: notificationType,
            title: title,
            message: message,
            fromUser: fromUser,
            toUserIds: toUserIds,
            albumId: batch.albumId
        )
    }
    
    /// Batch mesajını oluştur
    private func generateBatchMessage(batch: NotificationBatch, fromUser: User) -> (title: String, message: String) {
        let userName = fromUser.displayName ?? fromUser.email
        let albumTitle = batch.albumTitle
        
        if batch.photoCount > 0 && batch.videoCount > 0 {
            // Karma medya
            let title = "Yeni Medya"
            let message = "\(userName) \"\(albumTitle)\" albümüne \(batch.photoCount) fotoğraf ve \(batch.videoCount) video ekledi"
            return (title, message)
        } else if batch.photoCount > 0 {
            // Sadece fotoğraf
            let title = batch.photoCount == 1 ? "Yeni Fotoğraf" : "Yeni Fotoğraflar"
            let photoText = batch.photoCount == 1 ? "fotoğraf" : "\(batch.photoCount) fotoğraf"
            let message = "\(userName) \"\(albumTitle)\" albümüne \(photoText) ekledi"
            return (title, message)
        } else {
            // Sadece video
            let title = batch.videoCount == 1 ? "Yeni Video" : "Yeni Videolar"
            let videoText = batch.videoCount == 1 ? "video" : "\(batch.videoCount) video"
            let message = "\(userName) \"\(albumTitle)\" albümüne \(videoText) ekledi"
            return (title, message)
        }
    }
    
    /// Anında tek bildirim gönder (batch'lenmeyen durumlar için)
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
}

// MARK: - Album & Member Notifications (Değişiklik yok)
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
}

// MARK: - Notification Management (Değişiklik yok)
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

// MARK: - Helper Methods (Değişiklik yok)
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
