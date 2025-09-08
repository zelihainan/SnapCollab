//
//  LoginView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject var vm: SessionViewModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("SnapCollab").font(.largeTitle).bold()
            Button {
                Task { await vm.signInAnon() }
            } label: {
                Text("Hızlı Başla (Anonim)")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            Spacer()
            if let err = vm.errorMessage {
                Text(err).foregroundStyle(.red)
            }
        }
    }
}


