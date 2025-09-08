//
//  UserProviding.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation

protocol UserProviding {
    func getUser(uid: String) async throws -> User?
    func createUser(_ user: User) async throws
    func updateUser(_ user: User) async throws
}
