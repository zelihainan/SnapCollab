//
//  PinterestGrid.swift
//  SnapCollab
//
//  Pinterest-style grid layout
//

import SwiftUI

struct PinterestGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let spacing: CGFloat
    let columns: Int
    let containerWidth: CGFloat
    let content: (Item) -> Content
    
    private var columnWidth: CGFloat {
        let totalSpacing = spacing * CGFloat(columns - 1) + 24 // 12 padding each side
        return (containerWidth - totalSpacing) / CGFloat(columns)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    ForEach(itemsForColumn(columnIndex)) { item in
                        content(item)
                            .frame(width: columnWidth)
                    }
                }
            }
        }
    }
    
    private func itemsForColumn(_ columnIndex: Int) -> [Item] {
        var columnItems: [Item] = []
        
        for (index, item) in items.enumerated() {
            if index % columns == columnIndex {
                columnItems.append(item)
            }
        }
        
        return columnItems
    }
}
