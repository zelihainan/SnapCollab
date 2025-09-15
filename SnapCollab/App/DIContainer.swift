//
//  DIContainer.swift - Updated with Notifications
//  SnapCollab

import Foundation

struct DIContainer {
    let authRepo: AuthRepository
    let albumRepo: AlbumRepository
    let mediaRepo: MediaRepository
    let notificationRepo: NotificationRepository

    static func bootstrap() -> DIContainer {
        let authService = FirebaseAuthService()
        let userService = FirestoreUserService()
        let authRepo = AuthRepository(service: authService, userService: userService)

        let albumService = FirestoreAlbumService()
        let albumRepo = AlbumRepository(service: albumService, auth: authRepo, userService: userService)

        let mediaService = FirestoreMediaService()
        let storageService = FirebaseStorageService()
        let mediaRepo = MediaRepository(service: mediaService, storage: storageService, auth: authRepo)

        let notificationService = FirestoreNotificationService()
        let notificationRepo = NotificationRepository(service: notificationService, authRepo: authRepo)

        return DIContainer(
            authRepo: authRepo,
            albumRepo: albumRepo,
            mediaRepo: mediaRepo,
            notificationRepo: notificationRepo
        )
    }
}
