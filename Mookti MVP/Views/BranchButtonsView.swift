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
        let maxWidth = proposal.width ?? 300
        var width: CGFloat = 0
        var height: CGFloat = 0
        var rowHeight: CGFloat = 0
        var rowWidth: CGFloat = 0
        
        for subview in subviews {
            let idealSize = subview.sizeThatFits(.unspecified)
            // Allow subview to take up to full width if needed
            let size = subview.sizeThatFits(ProposedViewSize(width: min(idealSize.width, maxWidth - spacing * 2), height: nil))
            
            if rowWidth > 0 && rowWidth + spacing + size.width > maxWidth {
                // Start new row
                width = max(width, rowWidth)
                height += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            
            rowHeight = max(rowHeight, size.height)
            rowWidth += (rowWidth > 0 ? spacing : 0) + size.width
        }
        
        width = max(width, rowWidth)
        height += rowHeight
        
        return CGSize(width: min(width, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let idealSize = subview.sizeThatFits(.unspecified)
            // Allow subview to take up to full width if needed
            let constrainedProposal = ProposedViewSize(width: min(idealSize.width, maxWidth - spacing * 2), height: nil)
            let size = subview.sizeThatFits(constrainedProposal)
            
            if x > bounds.minX && x + size.width > bounds.maxX {
                // Start new row
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            
            subview.place(at: CGPoint(x: x, y: y), proposal: constrainedProposal)
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .lineLimit(nil)  // Allow text to wrap to multiple lines
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)  // Allow vertical expansion
                        .frame(minWidth: 60)  // Ensure minimum width
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
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
