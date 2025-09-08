//
//  DIContainer.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation

struct DIContainer {
    let authRepo: AuthRepository
    let albumRepo: AlbumRepository
    let mediaRepo: MediaRepository

    static func bootstrap() -> DIContainer {
        let authService = FirebaseAuthService()
        let userService = FirestoreUserService()
        let authRepo = AuthRepository(service: authService, userService: userService)

        let albumService = FirestoreAlbumService()
        let albumRepo = AlbumRepository(service: albumService, auth: authRepo)

        let mediaService = FirestoreMediaService()
        let storageService = FirebaseStorageService()
        let mediaRepo = MediaRepository(service: mediaService, storage: storageService, auth: authRepo)

        return DIContainer(authRepo: authRepo, albumRepo: albumRepo, mediaRepo: mediaRepo)
    }
}

