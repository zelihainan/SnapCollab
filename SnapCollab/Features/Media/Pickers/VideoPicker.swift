//
//  VideoPicker.swift - Geliştirilmiş versiyon
//

import SwiftUI
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import AVFoundation

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = .typeHigh // Yüksek kalite
        picker.videoMaximumDuration = 300 // 5 dakika
        picker.allowsEditing = false // Editing kapalı - dosya bozulmaması için
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            
            print("🎬 Video selected from picker")
            
            if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                print("🎬 Original video URL: \(videoURL)")
                
                // Video bilgilerini kontrol et
                Task {
                    await checkVideoInfo(videoURL)
                }
                
                parent.selectedVideoURL = videoURL
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
        
        private func checkVideoInfo(_ url: URL) async {
            do {
                let asset = AVAsset(url: url)
                let duration = try await asset.load(.duration)
                let isPlayable = try await asset.load(.isPlayable)
                
                print("🎬 Selected video info:")
                print("🎬 Duration: \(duration.seconds) seconds")
                print("🎬 Playable: \(isPlayable)")
                print("🎬 URL: \(url.absoluteString)")
                
                // File size kontrol
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    let data = try Data(contentsOf: url)
                    print("🎬 File size: \(data.count) bytes (\(data.count / 1024 / 1024) MB)")
                    
                    // İlk birkaç byte'ı kontrol et
                    if data.count >= 12 {
                        let header = Array(data.prefix(12))
                        print("🎬 File header: \(header.map { String(format: "%02X", $0) }.joined(separator: " "))")
                    }
                }
                
            } catch {
                print("🎬 Error checking video: \(error)")
            }
        }
    }
}

