import SwiftUI

struct InviteCodeView: View {
    let album: Album
    @Environment(\.dismiss) var dismiss
    @StateObject private var deepLinkHandler = DeepLinkHandler()
    @State private var showShareSheet = false
    @State private var showCopySuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 70))
                            .foregroundStyle(.blue)
                        
                        Text("Albüme Davet Et")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(album.title)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        Text("Davet Kodu")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            ForEach(Array(album.inviteCode ?? "INVALID"), id: \.self) { char in
                                Text(String(char))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                                    .frame(width: 40, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.blue.opacity(0.1))
                                    )
                            }
                        }
                        
                        Button {
                            copyInviteCode()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: showCopySuccess ? "checkmark" : "doc.on.doc")
                                Text(showCopySuccess ? "Kopyalandı!" : "Kodu Kopyala")
                            }
                            .foregroundStyle(showCopySuccess ? .green : .blue)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    VStack(spacing: 16) {
                        Text("Paylaşım Seçenekleri")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            ShareOptionButton(
                                icon: "link",
                                title: "Davet Linkini Paylaş",
                                subtitle: "SnapCollab uygulaması ile doğrudan açılır",
                                color: .blue
                            ) {
                                shareInviteLink()
                            }
                            
                            ShareOptionButton(
                                icon: "text.bubble",
                                title: "Metin Olarak Paylaş",
                                subtitle: "Kodu manuel olarak girebilirler",
                                color: .green
                            ) {
                                shareInviteText()
                            }
                            
                            ShareOptionButton(
                                icon: "doc.on.clipboard",
                                title: "Linki Kopyala",
                                subtitle: "Panoya kopyalar",
                                color: .orange
                            ) {
                                copyInviteLink()
                            }
                        }
                    }
                    
                    AlbumInfoCard(album: album)
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Davet Kodu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
    
    private func copyInviteCode() {
        UIPasteboard.general.string = album.inviteCode
        withAnimation(.spring()) {
            showCopySuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring()) {
                showCopySuccess = false
            }
        }
    }
    
    private func copyInviteLink() {
        if let link = deepLinkHandler.generateInviteLink(for: album) {
            UIPasteboard.general.string = link
        }
    }
    
    private func shareInviteLink() {
        guard let link = deepLinkHandler.generateInviteLink(for: album) else { return }
        
        let shareText = """
        🎉 "\(album.title)" albümüne davet edildiniz!
        
        Bu linke tıklayarak katılabilirsiniz:
        \(link)
        
        📱 SnapCollab uygulaması gereklidir.
        """
        
        showShareWithText(shareText)
    }
    
    private func shareInviteText() {
        if let shareText = deepLinkHandler.generateShareableText(for: album) {
            showShareWithText(shareText)
        }
    }
    
    private func showShareWithText(_ text: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else { return }
        
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topViewController.view
            popover.sourceRect = CGRect(x: topViewController.view.bounds.midX,
                                      y: topViewController.view.bounds.midY,
                                      width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topViewController.present(activityVC, animated: true)
    }
}

struct ShareOptionButton: View {
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

struct AlbumInfoCard: View {
    let album: Album
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Albüm Bilgileri")
                .font(.headline)
            
            VStack(spacing: 12) {
                InfoItem(
                    icon: "person.2",
                    title: "Üye Sayısı",
                    value: "\(album.members.count) kişi",
                    color: .blue
                )
                
                InfoItem(
                    icon: "calendar",
                    title: "Oluşturulma",
                    value: album.createdAt.formatted(date: .abbreviated, time: .omitted),
                    color: .green
                )
                
                InfoItem(
                    icon: "clock",
                    title: "Son Güncelleme",
                    value: album.updatedAt.formatted(date: .abbreviated, time: .shortened),
                    color: .orange
                )
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
}

struct InfoItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
                .frame(width: 20)
            
            Text(title)
                .font(.body)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}
