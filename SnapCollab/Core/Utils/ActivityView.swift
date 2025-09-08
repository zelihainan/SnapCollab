//
//  ActivityView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
