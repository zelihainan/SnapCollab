//
//  VideoPicker.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 11.09.2025.
//

import SwiftUI
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = .typeMedium
        picker.videoMaximumDuration = 60 // 60 saniye maksimum
        picker.allowsEditing = true
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
            
            // Edited veya original video URL'sini al
            if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                parent.selectedVideoURL = videoURL
            } else if let videoURL = info[.mediaURL] as? URL {
                parent.selectedVideoURL = videoURL
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
