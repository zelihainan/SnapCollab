//
//  VideoPlayerView.swift
//  SnapCollab
//
//

import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    let videoURL: URL
    let onClose: () -> Void
    
    @State private var player: AVPlayer?
    @State private var showControls = true
    @State private var isPlaying = false
    @State private var controlsTimer: Timer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .onTapGesture {
                        toggleControls()
                    }
                    .onAppear {
                        setupPlayer()
                    }
                    .onDisappear {
                        cleanupPlayer()
                    }
            } else {
                ProgressView("Video yükleniyor...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .onAppear {
                        loadVideo()
                    }
            }
            
            // Custom Controls Overlay
            if showControls {
                VStack {
                    // Top bar
                    HStack {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(.black.opacity(0.6)))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Center play/pause button
                    Button(action: togglePlayPause) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(.black.opacity(0.3))
                                    .frame(width: 100, height: 100)
                            )
                    }
                    
                    Spacer()
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 {
                        onClose()
                    }
                }
        )
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
            // Video sonunda kontrolları göster
            withAnimation {
                showControls = true
                isPlaying = false
            }
        }
    }
    
    private func loadVideo() {
        let asset = AVAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        // Player state observer
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { _ in
            isPlaying = player?.rate != 0
        }
    }
    
    private func setupPlayer() {
        // Auto-play when loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            player?.play()
            startControlsTimer()
        }
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        controlsTimer?.invalidate()
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
            startControlsTimer()
        }
        
        isPlaying.toggle()
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        
        if showControls && isPlaying {
            startControlsTimer()
        } else {
            stopControlsTimer()
        }
    }
    
    private func startControlsTimer() {
        stopControlsTimer()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            if isPlaying {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls = false
                }
            }
        }
    }
    
    private func stopControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = nil
    }
}

// MARK: - Simple Video Player (Alternative)
struct SimpleVideoPlayerView: UIViewControllerRepresentable {
    let videoURL: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: videoURL)
        controller.player = player
        controller.showsPlaybackControls = true
        
        // Auto-play
        DispatchQueue.main.async {
            player.play()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
