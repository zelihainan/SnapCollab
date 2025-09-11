//
//  SimpleVideoTestView.swift
//  SnapCollab
//
//  Test için basit video oynatıcı
//

import SwiftUI
import AVKit

struct SimpleVideoTestView: View {
    let videoURL: URL
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Video Test")
                    .font(.title)
                    .padding()
                
                Text("URL: \(videoURL.absoluteString)")
                    .font(.caption)
                    .padding()
                
                // En basit VideoPlayer kullanımı
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 300)
                    .onAppear {
                        print("🎥 Simple Video Player appeared with URL: \(videoURL)")
                    }
                
                Button("Kapat") {
                    onClose()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            print("🎥 SimpleVideoTestView appeared")
        }
    }
}
