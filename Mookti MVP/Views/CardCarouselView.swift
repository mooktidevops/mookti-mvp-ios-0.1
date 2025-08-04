//
//  CardCarouselView.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑07‑04.
//

import SwiftUI

/// Swipeable carousel used for `card-carousel` learning nodes.
struct CardCarouselView: View {

    let payload: CardCarouselPayload
    @State private var index = 0
    
    /// Convert HTML-like tags to AttributedString
    private func formattedText(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Replace HTML-like tags with proper formatting
        let cleanText = text
            .replacingOccurrences(of: "<b>", with: "**")
            .replacingOccurrences(of: "</b>", with: "**")
            .replacingOccurrences(of: "<i>", with: "*")
            .replacingOccurrences(of: "</i>", with: "*")
        
        do {
            attributedString = try AttributedString(markdown: cleanText)
        } catch {
            // Fallback to plain text if markdown parsing fails
            attributedString = AttributedString(text)
        }
        
        return attributedString
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let heading = payload.heading {
                Text(heading)
                    .font(.headline)
            }

            TabView(selection: $index) {
                ForEach(Array(payload.cards.enumerated()), id: \.offset) { i, card in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formattedText(card.title))
                            .font(.title3).bold()
                        Text(formattedText(card.content))
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 12)
                    .tag(i)
                }
            }
            .frame(maxWidth: .infinity)
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 160)            // Reduced height to match card content
        }
        .padding(.vertical, 8)
    }
}

#if DEBUG
struct CardCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        let demo = CardCarouselPayload(
            heading: "Core Concepts",
            cards: [
                .init(title: "Communication", content: "Communication is more than transmitting information…"),
                .init(title: "EQ", content: "Emotional intelligence emerged…")
            ]
        )
        CardCarouselView(payload: demo)
            .previewDevice("iPhone 15")
    }
}
#endif
