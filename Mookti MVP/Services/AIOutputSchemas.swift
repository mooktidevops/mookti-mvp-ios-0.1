//
//  AIOutputSchemas.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑06‑30.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels   // brings in @Generable - iOS 26+
#endif

// MARK: - Menu option the model can generate
#if canImport(FoundationModels)
// @Generable // TODO: Fix for iOS 26 API changes
#endif
struct MenuOption: Codable, Sendable, Hashable {
    /// Title shown on the choice button (e.g. “Sure, let’s do it!”).
    var title: String
    /// ID of the next `LearningNode` this option should activate.
    var nextChunkID: String
}

/// A list of branching options Ellen can present.
/// Limiting to max 6 keeps UI tidy and satisfies the model guide.
#if canImport(FoundationModels)
// @Generable // TODO: Fix for iOS 26 API changes
#endif
struct BranchMenu: Codable, Sendable {
    var prompt: String                    // the question Ellen asks
    var options: [MenuOption]             // 1‒6 items
}
