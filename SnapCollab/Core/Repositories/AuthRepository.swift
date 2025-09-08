//
//  AuthRepository.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation
import FirebaseAuth

final class AuthRepository: ObservableObject {
    private let service: AuthProviding
    private let userService: UserProviding
    
    @Published var currentUser: User?
    
    init(service: AuthProviding, userService: UserProviding) {
        self.service = service
        self.userService = userService
        
        // Auth state listener ekle
        Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            Task {
                await self?.syncCurrentUser()
            }
        }
    }
    
    var isSignedIn: Bool { service.currentUID != nil }
    var uid: String? { service.currentUID }
    
    @MainActor
    func syncCurrentUser() async {
        do {
            if let uid = service.currentUID {
                // Önce Firestore'dan kullanıcı bilgilerini çek
                currentUser = try await userService.getUser(uid: uid)
                
                // Eğer Firestore'da yok ama Firebase Auth'da varsa oluştur
                if currentUser == nil, let authUser = await service.currentUser {
                    try await userService.createUser(authUser)
                    currentUser = authUser
                }
            } else {
                currentUser = nil
            }
        } catch {
            print("User sync error:", error)
            currentUser = nil
        }
    }
    
    // Auth methods
    func signInAnon() async throws {
        try await service.signInAnonymously()
    }
    
    func signIn(email: String, password: String) async throws {
        try await service.signInWithEmail(email: email, password: password)
    }
    
    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        try await service.signUpWithEmail(email: email, password: password)
        
        // Kullanıcı bilgilerini Firestore'a kaydet
        if let uid = service.currentUID {
            let user = User(uid: uid, email: email, displayName: displayName)
            try await userService.createUser(user)
        }
    }
    
    func signInWithGoogle() async throws {
        try await service.signInWithGoogle()
        
        // Google'dan gelen bilgileri Firestore'a kaydet
        if let authUser = await service.currentUser {
            let existingUser = try? await userService.getUser(uid: authUser.uid)
            if existingUser == nil {
                try await userService.createUser(authUser)
            }
        }
    }
    
    func resetPassword(email: String) async throws {
        try await service.resetPassword(email: email)
    }
    
    func signOut() throws {
        try service.signOut()
    }
}
