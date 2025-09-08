//
//  SessionViewModel.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import Foundation

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let auth: AuthRepository
    private let state: AppState

    init(auth: AuthRepository, state: AppState) {
        self.auth = auth
        self.state = state
        self.state.isSignedIn = auth.isSignedIn
    }

    func signInAnon() async {
        isLoading = true; defer { isLoading = false }
        do {
            try await auth.signInAnon()
            state.isSignedIn = true
        } catch {
            let ns = error as NSError
            print("AUTH ERROR:", ns.code, ns.domain)
            print("DETAILS:", ns.userInfo) // <- burada asıl neden yazar (API key invalid, app not authorized vs.)
            errorMessage = ns.localizedDescription + " [\(ns.code)]"
        }
    }


    func signOut() {
        do { try auth.signOut(); state.isSignedIn = false }
        catch { errorMessage = error.localizedDescription }
    }
}
