//
//  AppState.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation
final class AppState: ObservableObject {
    @Published var isSignedIn = false
    @Published var currentUser: User?
}
