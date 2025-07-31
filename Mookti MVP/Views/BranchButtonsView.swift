//
//  BranchButtonsView.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑07‑03.
//

import SwiftUI

/// Renders the “aporia‑user” options as tappable buttons.
///
/// The caller passes the nodes representing each option
/// and receives the selected node’s ID via a callback.
struct BranchButtonsView: View {

    var options: [LearningNode]
    var onSelect: (LearningNode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(options) { node in
                Button {
                    onSelect(node)
                } label: {
                    Text(node.content)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
