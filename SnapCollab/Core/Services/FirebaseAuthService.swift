//
//  FirebaseAuthService.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation
import FirebaseAuth

final class FirebaseAuthService: AuthProviding {
    var currentUID: String? { Auth.auth().currentUser?.uid }
    func signInAnonymously() async throws { _ = try await Auth.auth().signInAnonymously() }
    func signOut() throws { try Auth.auth().signOut() }
}
