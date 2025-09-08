//
//  MediaItem.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation
import FirebaseFirestore

struct MediaItem: Identifiable, Codable {
    @DocumentID var id: String?
    var path: String         
    var thumbPath: String?
    var type: String
    var uploaderId: String
    var createdAt: Date
}
