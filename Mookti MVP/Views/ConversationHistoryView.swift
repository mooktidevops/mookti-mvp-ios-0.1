//
//  ConversationHistoryView.swift
//  Mookti
//

import SwiftUI
import SwiftData

struct ConversationHistoryView: View {

    // SwiftData query, sorted newest first
    @Query(sort: \Conversation.startedAt, order: .reverse)
    private var conversations: [Conversation]

    @Environment(\.modelContext) private var context

    var body: some View {
        List {
            ForEach(conversations) { convo in
                NavigationLink(value: convo) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(convo.title)
                            .font(.headline)
                        Text(convo.startedAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("History")
        .navigationDestination(for: Conversation.self) { convo in
            ConversationDetailView(conversation: convo)
        }
    }

    private func delete(at offsets: IndexSet) {
        offsets.forEach { context.delete(conversations[$0]) }
        try? context.save()
    }
}

#if DEBUG
struct ConversationHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { ConversationHistoryView() }
            .modelContainer(for: Conversation.self)
    }
}
#endif
