//
//  VideoPlayerView.swift
//  SnapCollab
//
//  Kesin çalışan versiyon - AVPlayer sorunlarını çözer
//

import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    let videoURL: URL
    let onClose: () -> Void
    
    var body: some View {
        StableVideoPlayer(videoURL: videoURL, onClose: onClose)
    }
}

// MARK: - Stable Video Player (Temp file kullanır)
struct StableVideoPlayer: View {
    let videoURL: URL
    let onClose: () -> Void
    
    @State private var localVideoURL: URL?
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var downloadProgress: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: {
                        cleanup()
                        onClose()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                            Text("Kapat")
                        }
                        .foregroundColor(.white)
                        .padding()
                    }
                    
                    Spacer()
                    
                    Button("Safari'de Aç") {
                        UIApplication.shared.open(videoURL)
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                .background(Color.black.opacity(0.8))
                
                // Content area
                if showError {
                    errorView
                } else if isLoading {
                    loadingView
                } else if let player = player {
                    // Working video player
                    VideoPlayer(player: player)
                        .onAppear {
                            print("🎬 StableVideoPlayer: VideoPlayer appeared")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                player.play()
                                print("🎬 StableVideoPlayer: Started playing")
                            }
                        }
                        .onDisappear {
                            print("🎬 StableVideoPlayer: VideoPlayer disappeared")
                        }
                }
            }
        }
        .onAppear {
            print("🎬 StableVideoPlayer: onAppear")
            downloadAndSetupVideo()
        }
        .onDisappear {
            print("🎬 StableVideoPlayer: onDisappear")
            cleanup()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: downloadProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                .frame(width: 200)
            
            Text(downloadProgress > 0 ? "İndiriliyor: \(Int(downloadProgress * 100))%" : "Video hazırlanıyor...")
                .foregroundColor(.white)
                .font(.body)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Video Hatası")
                .font(.title2)
                .foregroundColor(.white)
            
            Text(errorMessage)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Tekrar Dene") {
                showError = false
                isLoading = true
                downloadAndSetupVideo()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func downloadAndSetupVideo() {
        print("🎬 StableVideoPlayer: Starting download")
        
        Task {
            do {
                // Video'yu temp file'a indir
                let localURL = try await downloadVideoToTemp()
                
                await MainActor.run {
                    self.localVideoURL = localURL
                    setupPlayerWithLocalFile(localURL)
                }
                
            } catch {
                print("🎬 StableVideoPlayer: Download error: \(error)")
                await MainActor.run {
                    showError = true
                    errorMessage = "Video indirilemedi: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func downloadVideoToTemp() async throws -> URL {
        // Temp directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "video_\(UUID().uuidString).mp4"
        let localURL = tempDir.appendingPathComponent(fileName)
        
        print("🎬 StableVideoPlayer: Downloading to: \(localURL.path)")
        
        // Progress tracking delegate
        let delegate = DownloadDelegate { progress in
            DispatchQueue.main.async {
                self.downloadProgress = progress
            }
        }
        
        // Download with progress
        let (data, response) = try await URLSession.shared.data(from: videoURL, delegate: delegate)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VideoError.downloadFailed
        }
        
        print("🎬 StableVideoPlayer: Downloaded \(data.count) bytes")
        
        // Write to temp file
        try data.write(to: localURL)
        print("🎬 StableVideoPlayer: Saved to temp file")
        
        return localURL
    }
    
    private func setupPlayerWithLocalFile(_ localURL: URL) {
        print("🎬 StableVideoPlayer: Setting up player with local file")
        
        Task {
            do {
                // Local file ile asset oluştur
                let asset = AVAsset(url: localURL)
                let playable = try await asset.load(.isPlayable)
                let duration = try await asset.load(.duration)
                
                print("🎬 StableVideoPlayer: Local asset - Playable: \(playable), Duration: \(duration.seconds)")
                
                await MainActor.run {
                    if playable && duration.seconds > 0 {
                        let playerItem = AVPlayerItem(asset: asset)
                        player = AVPlayer(playerItem: playerItem)
                        
                        // Player observers
                        setupPlayerObservers()
                        
                        isLoading = false
                        print("🎬 StableVideoPlayer: Player ready with local file!")
                        
                    } else {
                        showError = true
                        errorMessage = "Video dosyası oynatılamıyor"
                        isLoading = false
                    }
                }
                
            } catch {
                print("🎬 StableVideoPlayer: Local setup error: \(error)")
                await MainActor.run {
                    showError = true
                    errorMessage = "Video hazırlama hatası: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func setupPlayerObservers() {
        guard let player = player else { return }
        
        // Playback monitoring
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in
            if time.seconds > 0 {
                print("🎬 StableVideoPlayer: Playing at \(time.seconds)s")
            }
        }
        
        // End time observer
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            print("🎬 StableVideoPlayer: Video ended, looping")
            player.seek(to: .zero)
            player.play()
        }
    }
    
    private func cleanup() {
        print("🎬 StableVideoPlayer: Cleanup")
        player?.pause()
        player = nil
        
        // Temp file'ı sil
        if let localURL = localVideoURL {
            try? FileManager.default.removeItem(at: localURL)
            print("🎬 StableVideoPlayer: Temp file deleted")
        }
        
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Download Delegate
class DownloadDelegate: NSObject, URLSessionDataDelegate {
    private let progressCallback: (Double) -> Void
    private var expectedContentLength: Int64 = 0
    private var receivedContentLength: Int64 = 0
    
    init(progressCallback: @escaping (Double) -> Void) {
        self.progressCallback = progressCallback
        super.init()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        expectedContentLength = response.expectedContentLength
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedContentLength += Int64(data.count)
        let progress = Double(receivedContentLength) / Double(expectedContentLength)
        progressCallback(progress)
    }
}

// MARK: - Video Error
enum VideoError: LocalizedError {
    case downloadFailed
    case invalidFormat
    case setupFailed
    
    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Video indirilemedi"
        case .invalidFormat:
            return "Video formatı desteklenmiyor"
        case .setupFailed:
            return "Video oynatıcı hazırlanamadı"
        }
    }
}

// MARK: - Alternative: WebView Solution
struct WebViewVideoPlayer: View {
    let videoURL: URL
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            WebVideoView(url: videoURL)
                .navigationTitle("Video")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Kapat", action: onClose)
                    }
                }
        }
    }
}

import WebKit

struct WebVideoView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .black
        
        // Video autoplay için configuration
        let configuration = webView.configuration
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // HTML video player oluştur
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { margin: 0; padding: 0; background: black; }
                video { 
                    width: 100%; 
                    height: 100vh; 
                    object-fit: contain; 
                }
            </style>
        </head>
        <body>
            <video controls autoplay>
                <source src="\(url.absoluteString)" type="video/mp4">
                Video yüklenemedi.
            </video>
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
}
