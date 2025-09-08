//
//  AuthProviding.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation

protocol AuthProviding {
    var currentUID: String? { get }
    var currentUser: User? { get async }
    
    // Authentication methods
    func signInAnonymously() async throws
    func signInWithEmail(email: String, password: String) async throws
    func signUpWithEmail(email: String, password: String) async throws
    func signInWithGoogle() async throws
    func signOut() throws
    func resetPassword(email: String) async throws
}
