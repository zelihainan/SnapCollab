//
//  AsyncImageView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import SwiftUI

struct AsyncImageView: View {
    let pathProvider: () async -> URL?

    @State private var url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable()
                    case .failure(_): placeholder
                    case .empty: placeholder
                    @unknown default: placeholder
                    }
                }
            } else {
                placeholder
                    .task { url = await pathProvider() }
            }
        }
    }

    private var placeholder: some View {
        Rectangle().fill(.secondary.opacity(0.1)).overlay {
            Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary)
        }
    }
}
