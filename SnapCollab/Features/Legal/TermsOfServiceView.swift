//  TermsOfServiceView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 9.09.2025.
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

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
                        Text("Kullanım Koşulları")
                            .font(.largeTitle).bold()

                        Text("Son Güncelleme: \(formattedDate)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Bu koşulları kabul ederek SnapCollab uygulamasını kullanmayı onaylıyorsunuz.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        TermsSection(
                            title: "1. Kabul ve Onay",
                            content: """
                            SnapCollab uygulamasını kullanarak bu kullanım koşullarını kabul etmiş olursunuz. Koşulları kabul etmiyorsanız uygulamayı kullanmayınız.
                            """
                        )
                        TermsSection(
                            title: "2. Hizmet Tanımı",
                            content: """
                            SnapCollab, kullanıcıların fotoğraf paylaşmasına ve albüm oluşturmasına imkan tanıyan bir mobil uygulamadır.

                            Sağlanan özellikler:
                            • Fotoğraf yükleme ve paylaşma
                            • Ortak albüm oluşturma
                            • Kullanıcı hesabı yönetimi
                            • Sosyal etkileşim araçları
                            """
                        )
                        TermsSection(
                            title: "3. Kullanıcı Sorumlulukları",
                            content: """
                            Kullanıcı olarak aşağıdaki kurallara uymayı kabul ediyorsunuz:

                            • Gerçek ve doğru bilgiler sağlamak
                            • Hesap güvenliğinizi korumak
                            • Yasal ve etik kurallara uymak
                            • Diğer kullanıcılara saygı göstermek

                            • Yasadışı içerik paylaşmamak
                            • Telif hakkı ihlali yapmamak
                            • Spam veya zararlı içerik göndermemek
                            • Başkalarının hesaplarını ele geçirmeye çalışmamak
                            """
                        )
                        TermsSection(
                            title: "4. İçerik Politikası",
                            content: """
                            Paylaştığınız içerikler için tamamen sorumlusunuz:
                            
                            • Telif hakları saklı içerik paylaşmayın
                            • Özel hayatın gizliliğini ihlal etmeyin
                            • Nefret söylemi veya ayrımcılık içermesin
                            • Şiddet, pornografi içermesin
                            • Spam veya reklam amacı taşımasın
                            """
                        )
                        
                        TermsSection(
                            title: "5. Hesap Yönetimi",
                            content: """
                            • Hesabınız sadece kişisel kullanımınıza aittir
                            • Şifrenizi güvenli tutun
                            • Şüpheli aktiviteleri rapor edin
                            • Hesap paylaşımı yasaktır
                            • İhlal durumunda hesap askıya alınabilir
                            """
                        )
                        
                        TermsSection(
                            title: "6. Gizlilik",
                            content: """
                            Gizliliğiniz bizim için önemlidir. Detaylar için Gizlilik Politikası'nı inceleyin.
                            
                            • Kişisel verileriniz korunur
                            • Üçüncü taraflarla paylaşılmaz
                            • İzniniz olmadan kullanılmaz
                            """
                        )
                        
                        TermsSection(
                            title: "7. Hizmet Kesintileri",
                            content: """
                            Aşağıdaki durumlar söz konusu olabilir:
                            
                            • Planlı bakım çalışmaları
                            • Teknik sorunlar
                            • Güvenlik güncellemeleri
                            • Yasal zorunluluklar
                            """
                        )
                        
                        TermsSection(
                            title: "8. Sorumluluk Reddi",
                            content: """
                            SnapCollab:
                            
                            • Hizmet kesintilerinden sorumlu değildir
                            • Veri kaybına karşı garanti vermez
                            • Üçüncü taraf hizmetlerden sorumlu değildir
                            • Kullanıcı içeriklerinden sorumlu değildir
                            """
                        )
                        
                        TermsSection(
                            title: "9. Değişiklikler",
                            content: """
                            Bu kullanım koşulları önceden bildirim ile değiştirilebilir. Değişiklikler yürürlüğe girdikten sonra uygulamayı kullanmaya devam ederseniz yeni koşulları kabul etmiş sayılırsınız.
                            """
                        )
                        
                        TermsSection(
                            title: "10. İletişim",
                            content: """
                            Sorularınız için bizimle iletişime geçin:
                            
                            📧 E-posta: legal@snapcollab.com
                            🌐 Web: www.snapcollab.com/terms
                            📞 Destek: +90 (XXX) XXX XX XX
                            """
                        )                    }

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

struct TermsSection: View {
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
