//
//  RootView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import SwiftUI
import FirebaseAuth

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
                }
            } else {
                LoginView(vm: sessionVM)
            }
        }
        .onAppear {
            print("RootView: onAppear called")
            sessionVM.syncInitialState()
            
            // Firebase Auth state listener ekle
            Auth.auth().addStateDidChangeListener { auth, user in
                print("RootView: Firebase Auth state changed - user: \(user?.uid ?? "nil")")
                DispatchQueue.main.async {
                    let wasSignedIn = state.isSignedIn
                    let isNowSignedIn = user != nil
                    
                    print("RootView: wasSignedIn: \(wasSignedIn), isNowSignedIn: \(isNowSignedIn)")
                    
                    if wasSignedIn != isNowSignedIn {
                        state.isSignedIn = isNowSignedIn
                        state.currentUser = isNowSignedIn ? di.authRepo.currentUser : nil
                        print("RootView: AppState updated - isSignedIn: \(state.isSignedIn)")
                    }
                }
            }
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
