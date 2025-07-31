//
//  UserProgressService.swift
//  Mookti
//

import Foundation
import Combine

/// Publishes learner progress percentages for each topic.
/// In Phase 8 you’ll update these from real data (StoredMessage, etc.).
@MainActor
final class UserProgressService: ObservableObject {

    /// Keys: topic names. Values: 0…1.
    @Published var progress: [String: Double] = [
        "CQ": 0.25,
        "EQ": 0.10,
        "Communication": 0.40
    ]

    /// Convenience: overall mean
    var overall: Double {
        let vals = progress.values
        return vals.isEmpty ? 0 : vals.reduce(0,+) / Double(vals.count)
    }

    // Call this after every completed `LearningNode` to update stats.
    func update(topic: String, percent: Double) {
        progress[topic] = percent
    }
}
