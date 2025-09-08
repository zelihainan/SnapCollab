//
//  User.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var uid: String
    var email: String
    var displayName: String?
    var photoURL: String?
    var createdAt: Date
    
    init(uid: String, email: String, displayName: String? = nil, photoURL: String? = nil) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = .now
    }
}
