//
//  Conversation.swift
//  Mookti
//

import Foundation
import SwiftData

/// Groups a series of StoredMessage rows into one session.
///
/// Deleting a Conversation cascades and removes its messages automatically.
@Model final class Conversation {

    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var title: String          // you can update this later (e.g. “CQ Intro”)
    @Relationship(deleteRule: .cascade) var messages: [StoredMessage]

    init(id: UUID = UUID(), startedAt: Date = .now, title: String) {
        self.id        = id
        self.startedAt = startedAt
        self.title     = title
        self.messages  = []
    }
}
