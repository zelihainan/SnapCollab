//
//  Notification.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 15.09.2025.
//

import Foundation
import FirebaseFirestore

struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    var type: NotificationType
    var title: String
    var message: String
    var fromUserId: String
    var toUserId: String
    var albumId: String?
    var mediaId: String?
    var isRead: Bool
    var createdAt: Date
    
    init(
        type: NotificationType,
        title: String,
        message: String,
        fromUserId: String,
        toUserId: String,
        albumId: String? = nil,
        mediaId: String? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.albumId = albumId
        self.mediaId = mediaId
        self.isRead = false
        self.createdAt = .now
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case photoAdded = "photo_added"
    case videoAdded = "video_added"
    case memberJoined = "member_joined"
    case albumInvite = "album_invite"
    case albumUpdated = "album_updated"
    case ownershipTransferred = "ownership_transferred"
    
    var icon: String {
        switch self {
        case .photoAdded:
            return "photo.fill"
        case .videoAdded:
            return "video.fill"
        case .memberJoined:
            return "person.badge.plus"
        case .albumInvite:
            return "envelope.fill"
        case .albumUpdated:
            return "pencil.circle.fill"
        case .ownershipTransferred:
            return "crown.fill"
        }
    }
    
    var color: String {
        switch self {
        case .photoAdded:
            return "blue"
        case .videoAdded:
            return "purple"
        case .memberJoined:
            return "green"
        case .albumInvite:
            return "orange"
        case .albumUpdated:
            return "blue"
        case .ownershipTransferred:
            return "orange"
        }
    }
}

// MARK: - Notification Extensions
extension AppNotification {
    
    var isRecent: Bool {
        let timeInterval = Date().timeIntervalSince(createdAt)
        return timeInterval < 24 * 60 * 60 // Son 24 saat
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    func markAsRead() -> AppNotification {
        var notification = self
        notification.isRead = true
        return notification
    }
}

// MARK: - Notification Type Extensions
extension NotificationType {
    
    var localizedTitle: String {
        switch self {
        case .photoAdded:
            return "Yeni Fotoğraf"
        case .videoAdded:
            return "Yeni Video"
        case .memberJoined:
            return "Yeni Üye"
        case .albumInvite:
            return "Albüm Daveti"
        case .albumUpdated:
            return "Albüm Güncellendi"
        case .ownershipTransferred:
            return "Albüm Sahipliği"
        }
    }
    
    var priority: Int {
        switch self {
        case .ownershipTransferred:
            return 5
        case .albumInvite:
            return 4
        case .memberJoined:
            return 3
        case .albumUpdated:
            return 2
        case .photoAdded, .videoAdded:
            return 1
        }
    }
}
