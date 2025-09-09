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
    var updatedAt: Date
    var inviteCode: String?
    
    init(title: String, ownerId: String) {
        self.title = title
        self.ownerId = ownerId
        self.members = [ownerId]
        self.createdAt = .now
        self.updatedAt = .now
        self.inviteCode = Album.generateInviteCode()
    }
    
    // Davet kodu oluşturma
    private static func generateInviteCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
    
    // Helper functions
    func isOwner(_ userId: String) -> Bool {
        return ownerId == userId
    }
    
    func isMember(_ userId: String) -> Bool {
        return members.contains(userId)
    }
    
    mutating func addMember(_ userId: String) {
        if !members.contains(userId) {
            members.append(userId)
            updatedAt = .now
        }
    }
    
    mutating func removeMember(_ userId: String) {
        members.removeAll { $0 == userId }
        updatedAt = .now
    }
}
