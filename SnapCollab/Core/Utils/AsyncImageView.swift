import SwiftUI

struct AsyncImageView: View {
    let pathProvider: () async -> URL?

    @State private var url: URL?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                    case .failure(_):
                        failurePlaceholder
                    case .empty:
                        loadingPlaceholder
                    @unknown default:
                        loadingPlaceholder
                    }
                }
            } else {
                if isLoading {
                    loadingPlaceholder
                } else {
                    failurePlaceholder
                }
            }
        }
        .onAppear {
            Task {
                url = await pathProvider()
                if url == nil {
                    isLoading = false
                }
            }
        }
    }

    private var loadingPlaceholder: some View {
        Rectangle()
            .fill(.secondary.opacity(0.1))
            .overlay {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
            }
    }
    
    private var failurePlaceholder: some View {
        Rectangle()
            .fill(.secondary.opacity(0.1))
            .overlay {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }
}
