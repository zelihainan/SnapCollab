//
//  AuthRepository.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation

final class AuthRepository {
    private let service: AuthProviding
    init(service: AuthProviding) { self.service = service }

    var isSignedIn: Bool { service.currentUID != nil }
    var uid: String? { service.currentUID }

    func signInAnon() async throws { try await service.signInAnonymously() }
    func signOut() throws { try service.signOut() }
}
