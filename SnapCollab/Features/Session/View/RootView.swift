//
//  RootView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import SwiftUI

struct RootView: View {
    @Environment(\.di) var di
    @EnvironmentObject var state: AppState

    var body: some View {
        Group {
            if state.isSignedIn {
                NavigationStack {
                    AlbumsPlaceholderView(onSignOut: {
                        SessionViewModel(auth: di.authRepo, state: state).signOut()
                    })
                }
            } else {
                LoginView(vm: SessionViewModel(auth: di.authRepo, state: state))
            }
        }
    }
}
