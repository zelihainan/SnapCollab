//
//  FirebaseAuthService.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

final class FirebaseAuthService: AuthProviding {
    var currentUID: String? {
        Auth.auth().currentUser?.uid
    }
    
    var currentUser: User? {
        get async {
            guard let firebaseUser = Auth.auth().currentUser else { return nil }
            return User(
                uid: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                displayName: firebaseUser.displayName,
                photoURL: firebaseUser.photoURL?.absoluteString
            )
        }
    }
    
    func signInAnonymously() async throws {
        _ = try await Auth.auth().signInAnonymously()
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signUpWithEmail(email: String, password: String) async throws {
        _ = try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "No client ID found"])
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token"])
        }
        
        let accessToken = result.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        _ = try await Auth.auth().signIn(with: credential)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}
