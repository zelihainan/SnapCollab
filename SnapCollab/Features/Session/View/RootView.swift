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
    @StateObject private var sessionVMHolder = SessionVMHolder()

    var body: some View {
        let sessionVM = sessionVMHolder.resolve(di: di, state: state)

        Group {
            if state.isSignedIn {
                NavigationStack {
                    AlbumsView(vm: .init(repo: di.albumRepo))
                        .toolbar {
                            Button("Sign Out") { sessionVM.signOut() }
                        }
                }
            } else {
                LoginView(vm: sessionVM)
            }
        }
        .onAppear(){
            sessionVM.syncInitialState()
        }
    }
}

final class SessionVMHolder: ObservableObject {
    private var cached: SessionViewModel?
    @MainActor func resolve(di: DIContainer, state: AppState) -> SessionViewModel {
        if let c = cached { return c }
        let vm = SessionViewModel(auth: di.authRepo, state: state)
        cached = vm
        return vm
    }
}

