//
//  VideoPlayerView.swift
//  SnapCollab
//

import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    let videoURL: URL
    let onClose: () -> Void
    
    var body: some View {
        OptimizedVideoPlayer(videoURL: videoURL, onClose: onClose)
    }
}

struct OptimizedVideoPlayer: View {
    let videoURL: URL
    let onClose: () -> Void
    
    @State private var player: AVPlayer?
    @State private var playerItem: AVPlayerItem?
    @State private var isReady = false
    @State private var showControls = true
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        print("OptimizedVideoPlayer: VideoPlayer appeared")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            player.play()
                            isPlaying = true
                            print("OptimizedVideoPlayer: Auto-play started")
                        }
                    }
                    .onTapGesture {
                        if player.rate > 0 {
                            player.pause()
                            isPlaying = false
                        } else {
                            player.play()
                            isPlaying = true
                        }
                    }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Video yükleniyor...")
                        .foregroundColor(.white)
                }
            }
            
            if showControls {
                VStack {
                    HStack {
                        Button(action: onClose) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                Text("Kapat")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.black.opacity(0.6))
                            )
                        }
                        
                        Spacer()
                        
                        Button("Safari") {
                            UIApplication.shared.open(videoURL)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.black.opacity(0.6))
                        )
                    }
                    .padding()
                    
                    Spacer()
                    
                    if let player = player {
                        HStack {
                            Image(systemName: isPlaying ? "pause.circle" : "play.circle")
                                .foregroundColor(.white)
                            
                            Text(isPlaying ? "Oynatılıyor" : "Duraklatıldı")
                                .foregroundColor(.white)
                                .font(.caption)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.black.opacity(0.6))
                        )
                        .padding()
                    }
                }
                .transition(.opacity.animation(.easeInOut))
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanup()
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls.toggle()
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }
    
    private func setupPlayer() {
        print("OptimizedVideoPlayer: Setting up player with direct URL")
        
        let asset = AVAsset(url: videoURL)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        setupPlayerObservers()
        
        isReady = true
        print("OptimizedVideoPlayer: Player ready (no download needed)")
    }
    
    private func setupPlayerObservers() {
        guard let player = player, let playerItem = playerItem else { return }
        
        let statusObserver = playerItem.observe(\.status, options: [.new]) { item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    print("OptimizedVideoPlayer: Ready to play")
                case .failed:
                    print("OptimizedVideoPlayer: Failed: \(item.error?.localizedDescription ?? "Unknown error")")
                case .unknown:
                    print("OptimizedVideoPlayer: Status unknown")
                @unknown default:
                    break
                }
            }
        }
        
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in
            isPlaying = player.rate > 0
            if time.seconds > 0 && time.seconds.truncatingRemainder(dividingBy: 5) < 1 {
                print("OptimizedVideoPlayer: Playing at \(Int(time.seconds))s")
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            print("OptimizedVideoPlayer: Video ended")
            player.seek(to: .zero)
        }
    }
    
    private func cleanup() {
        print("OptimizedVideoPlayer: Cleanup")
        player?.pause()
        NotificationCenter.default.removeObserver(self)
    }
}

struct WebVideoPlayer: View {
    let videoURL: URL
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            WebVideoView(url: videoURL)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Kapat", action: onClose)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Safari") {
                            UIApplication.shared.open(videoURL)
                        }
                    }
                }
        }
    }
}

import WebKit

struct WebVideoView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = .black
        webView.isOpaque = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                    background: #000; 
                    display: flex; 
                    align-items: center; 
                    justify-content: center; 
                    height: 100vh; 
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                }
                video { 
                    max-width: 100%; 
                    max-height: 100%; 
                    object-fit: contain;
                }
                .error {
                    color: white;
                    text-align: center;
                    padding: 20px;
                }
            </style>
        </head>
        <body>
            <video 
                controls 
                autoplay 
                playsinline 
                preload="metadata"
                onloadstart="console.log('Video load started')"
                oncanplay="console.log('Video can play'); this.play();"
                onerror="document.body.innerHTML='<div class=error>Video yüklenemedi</div>'"
            >
                <source src="\(url.absoluteString)" type="video/mp4">
                <div class="error">Video desteklenmiyor</div>
            </video>
            
            <script>
                // Auto-hide controls after 3 seconds
                const video = document.querySelector('video');
                let hideTimeout;
                
                video.addEventListener('loadeddata', () => {
                    console.log('Video loaded, duration:', video.duration);
                });
                
                document.addEventListener('click', () => {
                    if (video.paused) {
                        video.play();
                    } else {
                        video.pause();
                    }
                });
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
}
