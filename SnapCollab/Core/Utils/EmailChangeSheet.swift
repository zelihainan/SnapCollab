//
//  EmailChangeSheet.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 15.09.2025.

import SwiftUI
import FirebaseAuth

struct EmailChangeSheet: View {
    @ObservedObject var vm: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var newEmail = ""
    @State private var password = ""
    @State private var isChangingEmail = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showVerificationAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("E-posta Değiştir")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Yeni e-posta adresinizi girin. Değişiklik için doğrulama gerekecek.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mevcut E-posta")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundStyle(.secondary)
                            Text(vm.user?.email ?? "")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yeni E-posta")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("Yeni e-posta adresiniz", text: $newEmail)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mevcut Şifre")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        SecureField("Mevcut şifreniz", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.red.opacity(0.1))
                        )
                    }
                    
                    if let success = successMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(success)
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.green.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    Button("E-posta Değiştir") {
                        Task { await changeEmail() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isFormValid || isChangingEmail)
                    .frame(maxWidth: .infinity)
                    
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .disabled(isChangingEmail)
        .overlay {
            if isChangingEmail {
                Color.black.opacity(0.3)
                    .overlay {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("E-posta değiştiriliyor...")
                                .foregroundStyle(.white)
                                .font(.caption)
                        }
                    }
                    .ignoresSafeArea()
            }
        }
        .alert("Doğrulama E-postası Gönderildi", isPresented: $showVerificationAlert) {
            Button("Tamam") { dismiss() }
        } message: {
            Text("Yeni e-posta adresinize doğrulama linki gönderildi. Linke tıklayarak değişikliği onaylamanız gerekmektedir.")
        }
    }
    
    private var isFormValid: Bool {
        return !newEmail.isEmpty &&
               !password.isEmpty &&
               newEmail.contains("@") &&
               newEmail != vm.user?.email
    }
    
    private func changeEmail() async {
        guard let currentUser = Auth.auth().currentUser,
              let currentEmail = currentUser.email else {
            errorMessage = "Kullanıcı bulunamadı"
            return
        }
        
        isChangingEmail = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // Önce kullanıcıyı doğrula
            let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: password)
            try await currentUser.reauthenticate(with: credential)
            
            // E-posta adresini güncelle (doğrulama e-postası gönderir)
            try await currentUser.sendEmailVerification(beforeUpdatingEmail: newEmail)
            
            await MainActor.run {
                successMessage = "Doğrulama e-postası gönderildi"
                showVerificationAlert = true
            }
            
        } catch {
            await MainActor.run {
                if error.localizedDescription.contains("wrong-password") ||
                   error.localizedDescription.contains("invalid-credential") {
                    errorMessage = "Mevcut şifre yanlış"
                } else if error.localizedDescription.contains("email-already-in-use") {
                    errorMessage = "Bu e-posta adresi zaten kullanımda"
                } else if error.localizedDescription.contains("invalid-email") {
                    errorMessage = "Geçersiz e-posta adresi"
                } else {
                    errorMessage = "E-posta değiştirme hatası: \(error.localizedDescription)"
                }
            }
        }
        
        isChangingEmail = false
    }
}
