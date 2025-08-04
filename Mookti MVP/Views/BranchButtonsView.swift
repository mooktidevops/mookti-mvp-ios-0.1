//
//  BranchButtonsView.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑07‑03.
//

import SwiftUI

// Simple flow layout to wrap option buttons across lines
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var rowHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if width + size.width > maxWidth {
                width = 0
                height += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            width += size.width + spacing
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Renders the “aporia‑user” options as tappable buttons.
///
/// The caller passes the nodes representing each option
/// and receives the selected node’s ID via a callback.
struct BranchButtonsView: View {

    var options: [LearningNode]
    var onSelect: (LearningNode) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options) { node in
                Button {
                    onSelect(node)
                } label: {
                    Text(node.content)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#if DEBUG
struct BranchButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        let opt = LearningNode(id: "6.1", type: .aporiaUser,
                               content: "Yes, let's go!", nextAction: "",
                               nextChunkIDs: [])
        BranchButtonsView(options: [opt]) { _ in }
    }
}
#endif
