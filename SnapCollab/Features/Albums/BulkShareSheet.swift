//
//  BulkShareSheet.swift
//  SnapCollab
//

import SwiftUI
import UIKit

struct BulkShareSheet: View {
    let album: Album
    let mediaItems: [MediaItem]
    let mediaRepo: MediaRepository
    @Environment(\.dismiss) private var dismiss

    // UI State
    @State private var isCreatingZip = false
    @State private var zipProgress: Double = 0.0
    @State private var zipStatus: String = ""
    @State private var zipURL: URL?
    @State private var zipError: String?
    @State private var selectedShareOption: ShareOption = .photosOnly
    @State private var showDoneAlert = false

    // Cancel Support
    @State private var zipTask: Task<Void, Never>?

    enum ShareOption: String, CaseIterable {
        case photosOnly = "Sadece Fotoğraflar"
        case videosOnly = "Sadece Videolar"
        case all        = "Tümü (Fotoğraf + Video)"

        /// Güvenli SF Symbols
        var icon: String {
            switch self {
            case .photosOnly: return "photo.on.rectangle"
            case .videosOnly: return "film"
            case .all:        return "square.stack.3d.down.right"
            }
        }
    }

    // Seçime göre filtrelenmiş öğeler
    private var filteredItems: [MediaItem] {
        switch selectedShareOption {
        case .photosOnly: return mediaItems.filter { !$0.isVideo }
        case .videosOnly: return mediaItems.filter {  $0.isVideo }
        case .all:        return mediaItems
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                // MARK: Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle().fill(.blue.opacity(0.12))
                            .frame(width: 110, height: 110)

                        if isCreatingZip {
                            // Tek, dairesel progress
                            ProgressView(value: zipProgress)
                                .progressViewStyle(.circular)
                                .frame(width: 110, height: 110)
                                .tint(.blue)

                            Text("\(Int(zipProgress * 100))%")
                                .font(.footnote)
                                .monospacedDigit()
                                .foregroundStyle(.blue)
                        } else {
                            Image(systemName: UIImage(systemName: "doc.zipper") != nil ? "doc.zipper" : "archivebox.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.blue)
                        }
                    }

                    Text("Albümü ZIP ile Paylaş")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\"\(album.title)\" albümündeki medyalar ZIP dosyası olarak paylaşılacak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // MARK: Seçenekler
                VStack(spacing: 16) {
                    Text("Paylaşım İçeriği")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 12) {
                        ForEach(ShareOption.allCases, id: \.self) { option in
                            ShareOptionRow(
                                option: option,
                                isSelected: selectedShareOption == option,
                                count: countForOption(option)
                            ) {
                                selectedShareOption = option
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                // MARK: Durum Metni (tek progress: header’da)
                if isCreatingZip {
                    Text(zipStatus)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                // MARK: Hata
                if let error = zipError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // MARK: Aksiyonlar
                VStack(spacing: 12) {
                    Button(zipURL == nil ? (isCreatingZip ? "Hazırlanıyor…" : "ZIP Oluştur") : "Paylaş") {
                        if let url = zipURL {
                            shareZipFile(url)
                        } else {
                            createZip()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(isCreatingZip || filteredItems.isEmpty)

                    if isCreatingZip {
                        Button("İptal Et", role: .destructive) { cancelZip() }
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 8)
            }
            .navigationTitle("Toplu Paylaşım")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
            .alert("ZIP oluşturuldu", isPresented: $showDoneAlert) {
                Button("Paylaş") { if let url = zipURL { shareZipFile(url) } }
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(zipURL?.lastPathComponent ?? "")
            }
        }
    }

    // MARK: Helpers

    private func countForOption(_ option: ShareOption) -> Int {
        switch option {
        case .photosOnly: return mediaItems.filter { !$0.isVideo }.count
        case .videosOnly: return mediaItems.filter {  $0.isVideo }.count
        case .all:        return mediaItems.count
        }
    }

    // ZIP oluşturma (paylaşımı butona bıraktık)
    private func createZip() {
        guard !filteredItems.isEmpty else { return }

        isCreatingZip = true
        zipError = nil
        zipURL = nil
        zipProgress = 0
        zipStatus = "Hazırlanıyor…"

        zipTask = Task {
            do {
                let url = try await ZipManager.shared.createZipArchive(
                    albumTitle: album.title,
                    mediaItems: filteredItems,
                    mediaRepo: mediaRepo
                ) { progress, status in
                        self.zipProgress = progress
                        self.zipStatus = status
                    
                }

                await MainActor.run {
                    self.zipURL = url
                    self.isCreatingZip = false
                    self.zipStatus = "ZIP hazır"
                    self.showDoneAlert = true
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.isCreatingZip = false
                    self.zipStatus = "İptal edildi"
                }
            } catch {
                await MainActor.run {
                    self.zipError = error.localizedDescription
                    self.isCreatingZip = false
                    self.zipStatus = "Hata oluştu"
                }
            }
        }
    }

    private func cancelZip() {
        zipTask?.cancel()
        zipTask = nil
        isCreatingZip = false
        zipStatus = "İptal edildi"
    }

    private func shareZipFile(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.excludedActivityTypes = [.assignToContact, .saveToCameraRoll, .addToReadingList]

        if let top = UIApplication.topMostViewController() {
            if let pop = activityVC.popoverPresentationController {
                pop.sourceView = top.view
                pop.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
                pop.permittedArrowDirections = []
            }
            top.present(activityVC, animated: true)
        }
    }
}

// MARK: - Option Row

struct ShareOptionRow: View {
    let option: BulkShareSheet.ShareOption
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: option.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.rawValue)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(.primary)

                    Text("\(count) öğe")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(isSelected ? .blue : Color(.systemGray5))
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue.opacity(0.3) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - UIKit Helpers

private extension UIApplication {
    static func topMostViewController(
        base: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.rootViewController
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topMostViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topMostViewController(base: presented)
        }
        return base
    }
}
