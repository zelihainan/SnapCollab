//
//  AboutAppView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 16.09.2025.

import SwiftUI
import UIKit

struct AboutAppView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // App Icon ve Temel Bilgiler
                    VStack(spacing: 20) {
                        // App Icon
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 60, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        VStack(spacing: 8) {
                            Text("SnapCollab")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundStyle(.primary)
                            
                            Text("Fotoğrafları Birlikte Paylaşın")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("Versiyon \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // App Description
                    VStack(spacing: 16) {
                        Text("Uygulama Hakkında")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("SnapCollab, arkadaşlarınızla fotoğrafları kolayca paylaşmanızı sağlayan modern bir uygulamadır. Ortak albümler oluşturun, davet kodlarıyla arkadaşlarınızı ekleyin ve anılarınızı birlikte saklayın.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 20)
                    
                    // Features
                    VStack(spacing: 16) {
                        Text("Özellikler")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            FeatureItem(
                                icon: "photo.stack.fill",
                                title: "Ortak Albümler",
                                description: "Arkadaşlarınızla birlikte albüm oluşturun"
                            )
                            
                            FeatureItem(
                                icon: "person.badge.plus",
                                title: "Kolay Davet",
                                description: "Davet kodlarıyla hızlı üye ekleme"
                            )
                            
                            FeatureItem(
                                icon: "heart.fill",
                                title: "Favoriler",
                                description: "Beğendiğiniz fotoğrafları favorilerinize ekleyin"
                            )
                            
                            FeatureItem(
                                icon: "bell.fill",
                                title: "Bildirimler",
                                description: "Yeni fotoğraflar için anında bildirim"
                            )
                            
                            FeatureItem(
                                icon: "shield.checkered",
                                title: "Güvenli",
                                description: "Verileriniz Firebase ile güvenle korunur"
                            )
                            
                            FeatureItem(
                                icon: "paintbrush.fill",
                                title: "Özelleştirilebilir",
                                description: "Koyu/açık tema ve yazı boyutu ayarları"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Contact Info - Professional approach
                    VStack(spacing: 16) {
                        Text("İletişim")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            ContactInfoItem(
                                icon: "envelope.fill",
                                title: "Genel Destek",
                                value: "support@snapcollab.com",
                                color: .blue
                            )
                            
                            ContactInfoItem(
                                icon: "person.2.fill",
                                title: "İş Birliği",
                                value: "partnership@snapcollab.com",
                                color: .green
                            )
                            
                            ContactInfoItem(
                                icon: "exclamationmark.triangle.fill",
                                title: "Hata Bildirimi",
                                value: "bugs@snapcollab.com",
                                color: .orange
                            )
                            
                            ContactInfoItem(
                                icon: "lightbulb.fill",
                                title: "Öneriler",
                                value: "feedback@snapcollab.com",
                                color: .purple
                            )
                            
                            ContactInfoItem(
                                icon: "globe",
                                title: "Web Sitesi",
                                value: "www.snapcollab.com",
                                color: .cyan
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Copyright
                    VStack(spacing: 8) {
                        Text("© 2025 SnapCollab")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        
                        Text("Tüm hakları saklıdır.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        
                        Text("Made with ❤️ in Turkey")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Uygulama Hakkında")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Feature Item
struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Contact Info Item
struct ContactInfoItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        Button(action: { openContact() }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func openContact() {
        if value.contains("@") {
            // Email
            if let url = URL(string: "mailto:\(value)") {
                UIApplication.shared.open(url)
            }
        } else if value.contains("www.") {
            // Website
            if let url = URL(string: "https://\(value)") {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - Info Item (Shared Component)
struct InfoItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

