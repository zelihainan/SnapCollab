import SwiftUI
import MessageUI

struct SupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var subject = ""
    @State private var message = ""
    @State private var showMailComposer = false
    @State private var showMailAlert = false
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    HStack {
                        Spacer()
                        Button("Kapat") { dismiss() }
                            .foregroundColor(.blue)
                            .font(.body)
                            .padding(.trailing, 8)     
                            .padding(.vertical, 8)
                    }
                    .padding(.top, 5)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text("Destek Merkezi")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Size nasıl yardımcı olabiliriz?")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                    
                    // Quick Help Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Hızlı Yardım")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 8) {
                            SupportQuickOption(
                                icon: "photo.on.rectangle.angled",
                                title: "Fotoğraf Yükleme Sorunu",
                                description: "Fotoğraf yüklenmiyor veya hata alıyorum",
                                action: {
                                    subject = "Fotoğraf Yükleme Sorunu"
                                    showMailComposer = true
                                }
                            )
                            
                            SupportQuickOption(
                                icon: "person.2",
                                title: "Albüm Paylaşma",
                                description: "Albümü nasıl paylaşırım?",
                                action: {
                                    subject = "Albüm Paylaşma Yardımı"
                                    showMailComposer = true
                                }
                            )
                            
                            SupportQuickOption(
                                icon: "lock.shield",
                                title: "Hesap Güvenliği",
                                description: "Hesabımı nasıl güvende tutarım?",
                                action: {
                                    subject = "Hesap Güvenliği"
                                    showMailComposer = true
                                }
                            )
                            
                            SupportQuickOption(
                                icon: "exclamationmark.triangle",
                                title: "Hata Bildirimi",
                                description: "Uygulama çöküyor veya donuyor",
                                action: {
                                    subject = "Hata Bildirimi"
                                    showMailComposer = true
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Custom Message
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Özel Mesaj Gönder")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            
                            // Subject
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Konu")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("Konu başlığı girin", text: $subject)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            // Message
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mesaj")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextEditor(text: $message)
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            Button("Destek Talebi Gönder") {
                                sendSupportEmail()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(subject.isEmpty || message.isEmpty)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Contact Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("İletişim Bilgileri")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            ContactInfoRow(
                                icon: "envelope.fill",
                                title: "E-posta",
                                value: "support@snapcollab.com",
                                color: .blue
                            )
                            
                            ContactInfoRow(
                                icon: "clock.fill",
                                title: "Yanıt Süresi",
                                value: "24-48 saat içinde",
                                color: .green
                            )
                            
                            ContactInfoRow(
                                icon: "globe",
                                title: "Web Sitesi",
                                value: "www.snapcollab.com",
                                color: .purple
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .toolbar(.hidden, for: .navigationBar)
            .contentMargins(.top, 0, for: .scrollContent)
        }
        .sheet(isPresented: $showMailComposer) {
            if MFMailComposeViewController.canSendMail() {
                MailComposeView(
                    subject: subject,
                    message: message,
                    onComplete: { result in
                        showMailComposer = false
                        if result == .sent {
                            showSuccessAlert = true
                        }
                    }
                )
            } else {
                MailNotAvailableView()
            }
        }
        .alert("Mail Uygulaması Bulunamadı", isPresented: $showMailAlert) {
            Button("Tamam") { }
        } message: {
            Text("E-posta göndermek için Mail uygulamasını kurun veya support@snapcollab.com adresine manuel olarak yazın.")
        }
        .alert("Başarılı", isPresented: $showSuccessAlert) {
            Button("Tamam") { }
        } message: {
            Text("Destek talebiniz gönderildi. En kısa sürede size dönüş yapacağız.")
        }
    }
    
    private func sendSupportEmail() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            showMailAlert = true
        }
    }
}


// MARK: - Support Quick Option
struct SupportQuickOption: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 30)
                
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
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Contact Info Row
struct ContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Mail Compose View
struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let message: String
    let onComplete: (MFMailComposeResult) -> Void
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(["support@snapcollab.com"])
        let deviceInfo = """
        
        
        ---
        Cihaz Bilgileri:
        • Uygulama Versiyonu: 1.0
        • iOS Versiyonu: \(UIDevice.current.systemVersion)
        • Cihaz Modeli: \(UIDevice.current.model)
        • Cihaz Adı: \(UIDevice.current.name)
        """
        
        composer.setMessageBody(message + deviceInfo, isHTML: false)
        
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onComplete: (MFMailComposeResult) -> Void
        
        init(onComplete: @escaping (MFMailComposeResult) -> Void) {
            self.onComplete = onComplete
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            onComplete(result)
        }
    }
}

// MARK: - Mail Not Available View
struct MailNotAvailableView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            
            Text("Mail Uygulaması Bulunamadı")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("E-posta göndermek için Mail uygulamasını kurun veya aşağıdaki adrese manuel olarak yazın:")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Text("support@snapcollab.com")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.blue)
                .textSelection(.enabled)
            
            Button("Kapat") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}


