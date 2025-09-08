//
//  ForgotPasswordView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var vm: SessionViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "envelope.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    Text("Şifre Sıfırlama")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("E-posta adresinize şifre sıfırlama bağlantısı gönderilecek")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                TextField("E-posta adresiniz", text: $vm.resetEmail)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if vm.resetSuccess {
                    Text("✅ Şifre sıfırlama bağlantısı gönderildi")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                Button(action: {
                    Task { await vm.resetPassword() }
                }) {
                    Text("Sıfırlama Bağlantısı Gönder")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.resetEmail.isEmpty || vm.isLoading)
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Şifre Sıfırlama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }
}
