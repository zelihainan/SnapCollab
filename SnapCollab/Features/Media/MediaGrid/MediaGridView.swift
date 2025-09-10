//
//  MediaGridView.swift
//  SnapCollab
//
//  Main entry point for MediaGrid - clean and simple
//

import SwiftUI

struct MediaGridView: View {
    @ObservedObject var vm: MediaViewModel
    @StateObject private var gridState = MediaGridState()
    
    var body: some View {
        MediaGridContainer(vm: vm, state: gridState)
            .task { vm.start() }
            .onChange(of: gridState.currentSort) { _ in
                // Sorting is applied automatically in sortedItems computed property
            }
    }
}
