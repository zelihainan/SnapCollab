//
//  AuthProviding.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation

protocol AuthProviding {
    var currentUID: String? { get }
    func signInAnonymously() async throws
    func signOut() throws
}
