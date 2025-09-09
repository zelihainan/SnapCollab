//  PrivacyPolicyView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 9.09.2025.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {


                    HStack {
                        Spacer()  
                        Button("Kapat") { dismiss() }
                            .foregroundColor(.blue)
                            .font(.body)
                            .padding(.trailing, 8)
                            .padding(.vertical, 8)
                    }
                    .padding(.top, 8)


                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gizlilik Politikası")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Son Güncelleme: \(formattedDate)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        PolicySection(
                            title: "1. Toplanan Bilgiler",
                            content: """
                            SnapCollab uygulaması aşağıdaki bilgileri toplayabilir:
                            
                            • E-posta adresi (kayıt için)
                            • Profil fotoğrafı (isteğe bağlı)
                            • Kullanıcı adı/görünen ad
                            • Paylaştığınız fotoğraflar ve medya dosyaları
                            • Uygulama kullanım istatistikleri
                            """
                        )
                        
                        PolicySection(
                            title: "2. Bilgilerin Kullanımı",
                            content: """
                            Toplanan bilgiler şu amaçlarla kullanılır:
                            
                            • Hesap oluşturma ve yönetme
                            • Uygulama hizmetlerini sağlama
                            • Kullanıcı deneyimini geliştirme
                            • Teknik destek sağlama
                            • Güvenlik ve dolandırıcılık önleme
                            """
                        )
                        
                        PolicySection(
                            title: "3. Bilgi Paylaşımı",
                            content: """
                            Kişisel bilgileriniz üçüncü taraflarla paylaşılmaz. Sadece aşağıdaki durumlar istisnadır:
                            
                            • Yasal zorunluluklar
                            • Güvenlik tehditleri
                            • Kullanıcı izni ile
                            """
                        )
                        
                        PolicySection(
                            title: "4. Veri Güvenliği",
                            content: """
                            Verilerinizin güvenliği için:
                            
                            • Firebase güvenlik altyapısı kullanılır
                            • Veriler şifrelenerek saklanır
                            • Düzenli güvenlik güncellemeleri yapılır
                            • Erişim kontrolleri uygulanır
                            """
                        )
                        
                        PolicySection(
                            title: "5. Kullanıcı Hakları",
                            content: """
                            Kullanıcı olarak aşağıdaki haklara sahipsiniz:
                            
                            • Verilerinizi görüntüleme
                            • Verilerinizi güncelleme
                            • Hesabınızı silme
                            • Veri taşınabilirliği
                            """
                        )
                        
                        PolicySection(
                            title: "6. Çerezler ve İzleme",
                            content: """
                            Uygulama performansını artırmak için:
                            
                            • Firebase Analytics kullanılabilir
                            • Crash raporları toplanabilir
                            • Kullanım istatistikleri analiz edilir
                            """
                        )
                        
                        PolicySection(
                            title: "7. Değişiklikler",
                            content: """
                            Bu gizlilik politikası zaman zaman güncellenebilir. Önemli değişiklikler kullanıcılara bildirilir.
                            """
                        )
                        
                        PolicySection(
                            title: "8. İletişim",
                            content: """
                            Gizlilik politikası ile ilgili sorularınız için:
                            
                            📧 E-posta: privacy@snapcollab.com
                            🌐 Web: www.snapcollab.com/privacy
                            """
                        )
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .toolbar(.hidden, for: .navigationBar)
            .contentMargins(.top, 0, for: .scrollContent)

        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: Date())
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
