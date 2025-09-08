//
//  Album.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation
import FirebaseFirestore

struct Album: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var ownerId: String
    var members: [String]
    var createdAt: Date
}
