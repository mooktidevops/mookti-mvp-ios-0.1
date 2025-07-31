//
//  LearningNode.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑06‑29.
//

import Foundation

/// A single row from the expert‑authored CSV, expressed as a strongly‑typed model
/// that Ellen can traverse at runtime.
struct LearningNode: Identifiable, Codable, Hashable, Sendable {

    // MARK: - Nested types

    /// How this node should be rendered in the chat interface.
    enum DisplayType: String, Codable {
        case system           = "system"          // plain narration
        case aporiaSystem     = "aporia-system"   // AI poses a branching question
        case aporiaUser       = "aporia-user"     // user‑selectable reply option
        case cardCarousel     = "card-carousel"   // horizontal card scroller
        case moduleTitle      = "module_title"    // title for the learning module
        case moduleDescription = "module_description" // module overview/description
        case media            = "media"           // media files (PDFs, images, videos)
    }

    /// What Ellen should do after showing this node.
    ///
    /// Leave this as `String` for now because the CSV may evolve.
    /// Your view‑model can switch on known values (e.g. "getNextChunk").
    typealias NextAction = String

    // MARK: - Stored properties

    /// CSV column `sequence_id`
    let id: String

    /// CSV column `display_type`
    let type: DisplayType

    /// CSV column `content`
    ///
    /// May contain plain text **or** a JSON payload (for card carousels).
    var content: String

    /// CSV column `nextAction`
    let nextAction: NextAction

    /// CSV column `nextChunk`, already split on `" | "` and trimmed
    let nextChunkIDs: [String]

    // MARK: - Convenience flags

    /// `true` when this node yields multiple `nextChunkIDs`
    /// that the learner can choose between.
    var isBranch: Bool {
        switch type {
        case .aporiaSystem:
            return true
        default:
            return false
        }
    }

    /// `true` if the learner can tap this node (used for aporia‑user options).
    var isUserSelectable: Bool {
        type == .aporiaUser
    }
}

// MARK: - Sample node for previews / tests
#if DEBUG
extension LearningNode {
    static let sample = LearningNode(
        id: "6",
        type: .aporiaSystem,
        content: "Why might self‑reflection improve workplace success?",
        nextAction: "getNextAporia-User",
        nextChunkIDs: ["6.1", "6.2", "6.3"]
    )
}
#endif
