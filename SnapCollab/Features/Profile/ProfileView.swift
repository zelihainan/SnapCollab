//
//  ProfileView.swift
//  SnapCollab
//

import SwiftUI
import UIKit

struct ProfileView: View {
    @State private var showPrivacy = false
    @State private var showTerms = false
    @State private var showSupport = false
    @State private var showSettings = false

    @StateObject var vm: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 20) {
                    Group {
                        if let photoURL = vm.user?.photoURL, !photoURL.isEmpty {
                            AsyncImage(url: URL(string: photoURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                                    .scaleEffect(1.2)
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.gray.opacity(0.2), lineWidth: 2))
                        } else {
                            Circle()
                                .fill(.blue.gradient)
                                .frame(width: 120, height: 120)
                                .overlay {
                                    if let user = vm.user {
                                        Text(user.initials)
                                            .font(.system(size: 48, weight: .medium))
                                            .foregroundStyle(.white)
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 48))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .overlay(Circle().stroke(.gray.opacity(0.1), lineWidth: 2))
                        }
                    }
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 8) {
                        Text(vm.user?.displayName ?? "İsimsiz Kullanıcı")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        if !vm.isAnonymous {
                            Text(vm.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 20)
                
                HStack(spacing: 30) {
                    StatItem(
                        title: "Katılma Tarihi",
                        value: formattedJoinDate,
                        icon: "calendar"
                    )
                    
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                        .frame(width: 1, height: 40)
                    
                    StatItem(
                        title: "Hesap Türü",
                        value: vm.isAnonymous ? "Misafir" : "Kayıtlı",
                        icon: vm.isAnonymous ? "person.crop.circle.dashed" : "checkmark.shield"
                    )
                }
                .padding(.horizontal, 40)
                
                VStack(spacing: 16) {
                    Text("Hızlı İşlemler")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        QuickActionButton(
                            icon: "gear",
                            title: "Ayarlar",
                            subtitle: "Profil ve uygulama ayarları",
                            color: .blue,
                            isPrimary: true
                        ) {
                            showSettings = true
                        }
                        
                        QuickActionButton(
                            icon: "hand.raised",
                            title: "Gizlilik Politikası",
                            subtitle: "Gizlilik ve veri koruma",
                            color: .purple
                        ) {
                            showPrivacy = true
                        }
                        
                        QuickActionButton(
                            icon: "doc.text",
                            title: "Kullanım Koşulları",
                            subtitle: "Uygulama kullanım kuralları",
                            color: .green
                        ) {
                            showTerms = true
                        }
                        
                        QuickActionButton(
                            icon: "questionmark.circle",
                            title: "Destek",
                            subtitle: "Yardım ve destek alma",
                            color: .orange
                        ) {
                            showSupport = true
                        }
                        
                        if vm.isAnonymous {
                            QuickActionButton(
                                icon: "arrow.up.circle.fill",
                                title: "Hesabı Geliştir",
                                subtitle: "Kayıtlı hesaba dönüştür",
                                color: .blue
                            ) {
                                print("Upgrade account tapped")
                            }
                        }
                        
                        QuickActionButton(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Çıkış Yap",
                            subtitle: "Hesaptan çıkış yap",
                            color: .red
                        ) {
                            vm.signOut()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "gear")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(vm: vm)
        }
        .fullScreenCover(isPresented: $showPrivacy) {
            NavigationView { PrivacyPolicyView() }
        }
        .fullScreenCover(isPresented: $showTerms) {
            NavigationView { TermsOfServiceView() }
        }
        .fullScreenCover(isPresented: $showSupport) {
            NavigationView { SupportView() }
        }
        .onAppear {
            print("ProfileView appeared")
            vm.refreshUser()
        }
    }
    
    private var formattedJoinDate: String {
        guard let user = vm.user else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: user.createdAt)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isPrimary: Bool = false
    var isCompact: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: isCompact ? 8 : 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isPrimary ? 0.15 : 0.1))
                        .frame(width: isCompact ? 32 : 40, height: isCompact ? 32 : 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: isCompact ? 14 : 18, weight: isPrimary ? .semibold : .medium))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(isCompact ? .subheadline : .body)
                        .fontWeight(isPrimary ? .semibold : .medium)
                        .foregroundStyle(.primary)
                    
                    if !isCompact {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                if !isCompact {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, isCompact ? 12 : 16)
            .padding(.vertical, isCompact ? 10 : 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: isPrimary ? color.opacity(0.2) : .black.opacity(0.05), radius: isPrimary ? 8 : 2, x: 0, y: isPrimary ? 4 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPrimary ? color.opacity(0.3) : .gray.opacity(0.1), lineWidth: isPrimary ? 2 : 1)
            )
            .scaleEffect(isPrimary ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
