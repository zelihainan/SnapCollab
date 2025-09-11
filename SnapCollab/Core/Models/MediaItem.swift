//
//  MediaItem.swift
//  SnapCollab
//
//  Video desteği eklendi
//

import Foundation
import FirebaseFirestore
import SwiftUI

struct MediaItem: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var path: String
    var thumbPath: String?
    var type: String
    var uploaderId: String
    var createdAt: Date
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.path == rhs.path &&
               lhs.uploaderId == rhs.uploaderId
    }
}

// MARK: - Media Type Extensions
extension MediaItem {
    var isVideo: Bool {
        return type == "video"
    }
    
    var isImage: Bool {
        return type == "image"
    }
    
    var displayPath: String {
        return isVideo ? (thumbPath ?? path) : path
    }
    
    var typeIcon: String {
        switch type {
        case "video":
            return "video.fill"
        case "image":
            return "photo.fill"
        default:
            return "doc.fill"
        }
    }
    
    var typeColor: Color {
        switch type {
        case "video":
            return .purple
        case "image":
            return .blue
        default:
            return .gray
        }
    }
}
