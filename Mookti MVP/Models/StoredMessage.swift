//
//  StoredMessage.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑06‑29.
//

import Foundation
import SwiftData

/// A persisted chat bubble.
///
/// Mirrors `Message` but conforms to SwiftData’s `@Model` macro
/// so Ellen’s chat history can be saved and re‑loaded off‑line.
@Model final class StoredMessage: Sendable {

    // MARK: - Nested types
    enum Role: String, Codable, Sendable {
        case user, ellen, system
    }

    // MARK: - Persisted properties
    /// Stable identifier for SwiftData (you can use the default `persistentModelID`
    /// in queries, but a UUID mirrors the in‑memory `Message.id` 1‑to‑1).
    @Attribute(.unique) var id: UUID
    var role: Role
    var content: String
    var timestamp: Date

    // MARK: - Convenience initialiser
    init(id: UUID = UUID(),
         role: Role,
         content: String,
         timestamp: Date = .now)
    {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    // MARK: - Mapping helpers
    /// Convert an in‑memory `Message` to a `StoredMessage`.
    convenience init(from message: Message) {
        self.init(id: message.id,
                  role: .init(rawValue: message.role.rawValue) ?? .system,
                  content: message.content,
                  timestamp: message.timestamp)
    }

    /// Back to the lightweight struct for UI use.
    var asMessage: Message {
        .init(id: id,
              role: .init(rawValue: role.rawValue) ?? .system,
              content: content,
              timestamp: timestamp)
    }
}
