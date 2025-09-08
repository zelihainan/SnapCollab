//
//  AlbumsPlaceholderView.swift
//  SnapCollab
//
//  Created by Zeliha İnan on 8.09.2025.
//

import SwiftUI

struct AlbumsPlaceholderView: View {
    let onSignOut: () -> Void
    var body: some View {
        List { Text("Albüm listesi burada olacak.") }
            .navigationTitle("Albums")
            .toolbar { Button("Sign Out", action: onSignOut) }
    }
}
