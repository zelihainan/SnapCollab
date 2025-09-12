//
//  RootView.swift - Basit Çözüm
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
            // ÖNCE ONBOARDING KONTROL ET
            if !onboardingManager.hasCompletedOnboarding {
                // Onboarding göster
                OnboardingView {
                    onboardingManager.completeOnboarding()
                }
            } else if state.isSignedIn {
                // Ana uygulama
                NavigationStack {
                    AlbumsView(vm: .init(repo: di.albumRepo))
                }
            } else {
                // Login ekranı
                CleanLoginView(vm: sessionVM)
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

final class SessionVMHolder: ObservableObject {
    private var cached: SessionViewModel?
    @MainActor
    func resolve(di: DIContainer, state: AppState) -> SessionViewModel {
        if let c = cached { return c }
        let vm = SessionViewModel(auth: di.authRepo, state: state)
        cached = vm
        return vm
    }
}
