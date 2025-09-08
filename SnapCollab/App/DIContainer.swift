//
//  DIContainer.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation

struct DIContainer {
    let authRepo: AuthRepository

    static func bootstrap() -> DIContainer {
        // Services
        let authService = FirebaseAuthService()
        // Repos
        let authRepo = AuthRepository(service: authService)
        return DIContainer(authRepo: authRepo)
    }
}
