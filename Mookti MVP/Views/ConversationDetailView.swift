//
//  ConversationDetailView.swift
//  Mookti
//

import SwiftUI

struct ConversationDetailView: View {

    let conversation: Conversation

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(sortedMessages, id: \.id) { stored in
                    BubbleView(message: stored.asMessage)
                }
            }
            .padding()
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sortedMessages: [StoredMessage] {
        conversation.messages.sorted { $0.timestamp < $1.timestamp }
    }
}

#if DEBUG
struct ConversationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Simple in‑memory mock
        let convo = Conversation(title: "Preview")
        convo.messages.append(StoredMessage(
            id: UUID(), role: .ellen, content: "Hi!", timestamp: .now))
        convo.messages.append(StoredMessage(
            id: UUID(), role: .user, content: "Hello!", timestamp: .now))

        return NavigationStack {
            ConversationDetailView(conversation: convo)
        }
    }
}
#endif
