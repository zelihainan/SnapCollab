//
//  FirestoreUserService.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation
import FirebaseFirestore

final class FirestoreUserService: UserProviding {
    private let db = Firestore.firestore()
    
    func getUser(uid: String) async throws -> User? {
        let doc = try await db.collection("users").document(uid).getDocument()
        return try doc.data(as: User.self)
    }
    
    func createUser(_ user: User) async throws {
        try db.collection("users").document(user.uid).setData(from: user)
    }
    
    func updateUser(_ user: User) async throws {
        try db.collection("users").document(user.uid).setData(from: user, merge: true)
    }
}
