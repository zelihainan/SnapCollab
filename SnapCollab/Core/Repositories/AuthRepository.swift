//
//  AuthRepository.swift 
//  SnapCollab
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
                print("AuthRepo: Syncing user for UID: \(uid)")
                
                do {
                    currentUser = try await userService.getUser(uid: uid)
                    print("AuthRepo: Got user from Firestore: \(currentUser?.displayName ?? "nil")")
                } catch {
                    print("AuthRepo: User not found in Firestore, creating...")
                    currentUser = nil
                }
                
                if currentUser == nil {
                    let firebaseUser = Auth.auth().currentUser
                    let email = firebaseUser?.email ?? ""
                    let displayName = firebaseUser?.displayName ?? "İsimsiz Kullanıcı"
                    let photoURL = firebaseUser?.photoURL?.absoluteString
                    
                    print("AuthRepo: Creating user - email: \(email), displayName: \(displayName)")
                    
                    let newUser = User(uid: uid, email: email, displayName: displayName, photoURL: photoURL)
                    try await userService.createUser(newUser)
                    currentUser = newUser
                    print("AuthRepo: Successfully created user in Firestore!")
                }
            } else {
                print("AuthRepo: No current UID")
                currentUser = nil
            }
        } catch {
            print("AuthRepo: User sync error: \(error)")
            currentUser = nil
        }
    }
    
    func signIn(email: String, password: String) async throws {
        try await service.signInWithEmail(email: email, password: password)
    }
    
    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        try await service.signUpWithEmail(email: email, password: password)
        
        if let uid = service.currentUID {
            let user = User(uid: uid, email: email, displayName: displayName)
            try await userService.createUser(user)
        }
    }
    
    func signInWithGoogle() async throws {
        try await service.signInWithGoogle()
        
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

extension AuthRepository {
    func updateUser(_ user: User) async throws {
        print("AuthRepo: updateUser called for: \(user.displayName ?? "nil")")
        
        try await userService.updateUser(user)
        print("AuthRepo: Firestore update completed")
        
        if let displayName = user.displayName {
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = displayName
            try await changeRequest?.commitChanges()
            print("AuthRepo: Firebase Auth display name updated")
        }
        
        await MainActor.run {
            self.currentUser = user
        }
        print("AuthRepo: currentUser updated directly")
    }
}
