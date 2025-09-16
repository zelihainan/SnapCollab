//
//  AboutAppView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 16.09.2025.


import SwiftUI
import UIKit

struct AboutAppView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showLicenses = false
    @State private var showPrivacy = false
    @State private var showTerms = false
    @State private var showChangelog = false
    
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
                    
                    // Developer Info
                    VStack(spacing: 16) {
                        Text("Geliştirici Bilgileri")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            InfoItem(
                                icon: "person.circle.fill",
                                title: "Geliştirici",
                                value: "Zeliha İnan",
                                color: .blue
                            )
                            
                            InfoItem(
                                icon: "envelope.fill",
                                title: "İletişim",
                                value: "zelihainan@snapcollab.com",
                                color: .green
                            )
                            
                            InfoItem(
                                icon: "globe",
                                title: "Web Sitesi",
                                value: "www.snapcollab.com",
                                color: .purple
                            )
                            
                            InfoItem(
                                icon: "calendar",
                                title: "İlk Sürüm",
                                value: "Eylül 2025",
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Technical Info
                    VStack(spacing: 16) {
                        Text("Teknik Bilgiler")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            TechnicalInfoItem(title: "Platform", value: "iOS 18.5+")
                            TechnicalInfoItem(title: "Framework", value: "SwiftUI")
                            TechnicalInfoItem(title: "Backend", value: "Firebase")
                            TechnicalInfoItem(title: "Dil", value: "Swift 5.0")
                            TechnicalInfoItem(title: "Minimum iOS", value: "18.5")
                            TechnicalInfoItem(title: "Cihaz Desteği", value: "iPhone, iPad")
                            TechnicalInfoItem(title: "İnternet", value: "Gerekli")
                            TechnicalInfoItem(title: "Depolama", value: "~50 MB")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Actions
                    VStack(spacing: 16) {
                        Text("Daha Fazla Bilgi")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            AboutActionButton(
                                icon: "doc.text.fill",
                                title: "Sürüm Notları",
                                subtitle: "Yeni özellikler ve düzeltmeler",
                                color: .blue
                            ) {
                                showChangelog = true
                            }
                            
                            AboutActionButton(
                                icon: "books.vertical.fill",
                                title: "Açık Kaynak Lisansları",
                                subtitle: "Kullanılan kütüphaneler ve lisanslar",
                                color: .green
                            ) {
                                showLicenses = true
                            }
                            
                            AboutActionButton(
                                icon: "hand.raised.fill",
                                title: "Gizlilik Politikası",
                                subtitle: "Verileriniz nasıl korunuyor",
                                color: .purple
                            ) {
                                showPrivacy = true
                            }
                            
                            AboutActionButton(
                                icon: "doc.plaintext.fill",
                                title: "Kullanım Koşulları",
                                subtitle: "Uygulama kullanım kuralları",
                                color: .orange
                            ) {
                                showTerms = true
                            }
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
        .sheet(isPresented: $showLicenses) {
            LicensesView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showChangelog) {
            ChangelogView()
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

// MARK: - Info Item
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

// MARK: - Technical Info Item
struct TechnicalInfoItem: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - About Action Button
struct AboutActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Licenses View
struct LicensesView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    LicenseItem(
                        name: "Firebase iOS SDK",
                        version: "12.2.0",
                        license: "Apache License 2.0",
                        url: "https://github.com/firebase/firebase-ios-sdk"
                    )
                    
                    LicenseItem(
                        name: "GoogleSignIn-iOS",
                        version: "9.0.0",
                        license: "Apache License 2.0",
                        url: "https://github.com/google/GoogleSignIn-iOS"
                    )
                    
                    LicenseItem(
                        name: "SwiftUI",
                        version: "Built-in",
                        license: "Apple Software License",
                        url: "https://developer.apple.com/documentation/swiftui"
                    )
                    
                } header: {
                    Text("Üçüncü Taraf Kütüphaneler")
                } footer: {
                    Text("Bu uygulama açık kaynak kütüphanelerini kullanmaktadır. İlgili lisanslar için bağlantılara tıklayabilirsiniz.")
                }
                
                Section {
                    LicenseItem(
                        name: "Albert Sans Font",
                        version: "1.0",
                        license: "SIL Open Font License",
                        url: "https://fonts.google.com/specimen/Albert+Sans"
                    )
                    
                    LicenseItem(
                        name: "SF Symbols",
                        version: "Apple",
                        license: "Apple Software License",
                        url: "https://developer.apple.com/sf-symbols/"
                    )
                    
                } header: {
                    Text("Fontlar ve İkonlar")
                }
            }
            .navigationTitle("Açık Kaynak Lisansları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

// MARK: - License Item
struct LicenseItem: View {
    let name: String
    let version: String
    let license: String
    let url: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(version)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6))
                    )
            }
            
            Text(license)
                .font(.subheadline)
                .foregroundStyle(.blue)
            
            if !url.isEmpty {
                Button(url) {
                    if let websiteURL = URL(string: url) {
                        UIApplication.shared.open(websiteURL)
                    }
                }
                .font(.caption)
                .foregroundStyle(.blue)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Changelog View
struct ChangelogView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ChangelogVersionItem(
                        version: "1.0.0",
                        date: "15 Eylül 2025",
                        changes: [
                            "🎉 İlk sürüm yayınlandı",
                            "📱 Ortak albüm oluşturma ve paylaşma",
                            "👥 Davet kodları ile üye ekleme",
                            "❤️ Favori fotoğraf işaretleme",
                            "🔔 Push bildirimler",
                            "🎨 Koyu/açık tema desteği",
                            "📝 Yazı boyutu ayarları",
                            "🔐 Google Sign-In entegrasyonu",
                            "📊 Depolama kullanımı görüntüleme",
                            "🗂️ Kullanıcı verilerini export etme"
                        ]
                    )
                } header: {
                    Text("Sürüm Geçmişi")
                } footer: {
                    Text("Gelecek güncellemelerde yeni özellikler eklenecek")
                }
            }
            .navigationTitle("Sürüm Notları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Changelog Version Item
struct ChangelogVersionItem: View {
    let version: String
    let date: String
    let changes: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Versiyon \(version)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(changes, id: \.self) { change in
                    Text(change)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
