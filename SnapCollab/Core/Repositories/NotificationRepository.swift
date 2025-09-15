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
                print("Error creating photo notification: \(error)")
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
                print("Error creating video notification: \(error)")
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
                print("Error creating member join notification: \(error)")
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
                print("Error creating album update notification: \(error)")
            }
        }
    }
        
    func markAsRead(_ notification: AppNotification) async {
        guard let id = notification.id else { return }
        
        do {
            try await service.markAsRead(id)
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }
    
    func markAllAsRead() async {
        guard let userId = authRepo.uid else { return }
        
        do {
            try await service.markAllAsRead(for: userId)
        } catch {
            print("Error marking all notifications as read: \(error)")
        }
    }
    
    func deleteNotification(_ notification: AppNotification) async {
        guard let id = notification.id else { return }
        
        do {
            try await service.deleteNotification(id)
        } catch {
            print("Error deleting notification: \(error)")
        }
    }
}
