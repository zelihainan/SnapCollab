//
//  LoginView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject var vm: SessionViewModel
    @State private var showSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    VStack(spacing: 8) {
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        Text("SnapCollab")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 40)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        TextField("E-posta", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Şifre", text: $password)
                            .textFieldStyle(.roundedBorder)
                        
                        if showSignUp {
                            TextField("Ad Soyad (isteğe bağlı)", text: $displayName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    // Error Message
                    if let error = vm.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Main Action Button
                        Button(action: {
                            Task {
                                if showSignUp {
                                    await vm.signUp(email: email, password: password, displayName: displayName)
                                } else {
                                    await vm.signIn(email: email, password: password)
                                }
                            }
                        }) {
                            Text(showSignUp ? "Hesap Oluştur" : "Giriş Yap")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(email.isEmpty || password.isEmpty || vm.isLoading)
                        
                        // Toggle Sign Up/In
                        Button(showSignUp ? "Zaten hesabım var" : "Hesap oluştur") {
                            showSignUp.toggle()
                            vm.errorMessage = nil
                        }
                        .foregroundColor(.blue)
                        
                        // Forgot Password
                        if !showSignUp {
                            Button("Şifremi Unuttum") {
                                vm.showForgotPassword = true
                            }
                            .foregroundColor(.blue)
                            .font(.caption)
                        }
                    }
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("veya")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.vertical, 8)
                    
                    // Social Login Buttons
                    VStack(spacing: 12) {
                        // Google Sign In
                        Button(action: {
                            Task { await vm.signInWithGoogle() }
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Google ile Devam Et")
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                        .disabled(vm.isLoading)
                        
                        // Anonymous Login
                        Button(action: {
                            Task { await vm.signInAnon() }
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.dashed")
                                Text("Misafir Olarak Devam Et")
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.bordered)
                        .disabled(vm.isLoading)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarHidden(true)
        }
        .disabled(vm.isLoading)
        .overlay {
            if vm.isLoading {
                Color.black.opacity(0.3)
                    .overlay(ProgressView().tint(.white))
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $vm.showForgotPassword) {
            ForgotPasswordView(vm: vm)
        }
    }
}


