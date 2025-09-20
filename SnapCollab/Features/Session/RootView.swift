//
//  RootView.swift - Updated without Anonymous Login
//  SnapCollab
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @Environment(\.di) var di
    @EnvironmentObject var state: AppState
    @StateObject private var sessionVMHolder = SessionVMHolder()
    @StateObject private var onboardingManager = OnboardingManager()

    var body: some View {
        let sessionVM = sessionVMHolder.resolve(di: di, state: state)

        Group {
            if !onboardingManager.hasCompletedOnboarding {
                OnboardingView {
                    onboardingManager.completeOnboarding()
                }
            } else if state.isSignedIn {
                MainTabView()
            } else {
                ModernLoginView(vm: sessionVM)
            }
        }
        .onAppear {
            print("RootView: onAppear called")
            sessionVM.syncInitialState()
            
            Auth.auth().addStateDidChangeListener { auth, user in
                print("RootView: Firebase Auth state changed - user: \(user?.uid ?? "nil")")
                DispatchQueue.main.async {
                    let wasSignedIn = state.isSignedIn
                    let isNowSignedIn = user != nil
                    
                    if wasSignedIn != isNowSignedIn {
                        state.isSignedIn = isNowSignedIn
                        state.currentUser = isNowSignedIn ? di.authRepo.currentUser : nil
                    }
                }
            }
        }
    }
}

@MainActor
final class SessionVMHolder: ObservableObject {
    private var cached: SessionViewModel?
    
    func resolve(di: DIContainer, state: AppState) -> SessionViewModel {
        if let c = cached { return c }
        let vm = SessionViewModel(auth: di.authRepo, state: state)
        cached = vm
        return vm
    }
}
