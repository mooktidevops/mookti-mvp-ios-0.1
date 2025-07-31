//
//  ConversationStore.swift
//  Mookti
//

import Foundation
import SwiftData

/// Manages the current Conversation and persists messages as they arrive.
@MainActor
final class ConversationStore: ObservableObject {

    private let context: ModelContext
    private var current: Conversation?

    init(modelContext: ModelContext) {
        self.context = modelContext
    }

    /// Call when a chat screen opens.
    func startNew(title: String = "Untitled") {
        let convo = Conversation(title: title)
        context.insert(convo)
        current = convo
    }

    /// Append a single in‑memory `Message` to the current session.
    func append(_ msg: Message) {
        guard let convo = current else { return }
        let stored = StoredMessage(from: msg)
        convo.messages.append(stored)
        // SwiftData auto‑saves on its own tick; explicit save optional.
    }
    
    /// Clear all conversations.
    func clearAll() {
            let fetch = FetchDescriptor<Conversation>()
            if let conversations = try? context.fetch(fetch) {
                conversations.forEach(context.delete)
            }
            // Optional explicit save; SwiftData autosaves eventually
            try? context.save()
        }
}
