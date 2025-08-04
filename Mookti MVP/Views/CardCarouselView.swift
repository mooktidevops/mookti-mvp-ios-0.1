//
//  CardCarouselView.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑07‑04.
//

import SwiftUI

/// Preference key for tracking view height
struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Swipeable carousel used for `card-carousel` learning nodes.
struct CardCarouselView: View {

    let payload: CardCarouselPayload
    @State private var index = 0
    @State private var cardHeight: CGFloat = 240
    
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

            ZStack {
                TabView(selection: $index) {
                    ForEach(Array(payload.cards.enumerated()), id: \.offset) { i, card in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(formattedText(card.title))
                                .font(.title3)
                                .fontWeight(.bold)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            ScrollView {
                                Text(formattedText(card.content))
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxHeight: .infinity)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                            }
                        )
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 40)  // Increased padding to make room for arrows
                        .tag(i)
                    }
                }
                .frame(maxWidth: .infinity)
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(minHeight: 240, maxHeight: 400)  // Dynamic height with min/max constraints
                .onPreferenceChange(HeightPreferenceKey.self) { height in
                    if height > 0 {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            cardHeight = min(400, max(240, height + 40))
                        }
                    }
                }
                
                // Navigation arrows overlay
                HStack {
                    // Left arrow
                    if index > 0 {
                        Button(action: {
                            withAnimation {
                                index -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.accentColor)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        .padding(.leading, 8)
                    }
                    
                    Spacer()
                    
                    // Right arrow
                    if index < payload.cards.count - 1 {
                        Button(action: {
                            withAnimation {
                                index += 1
                            }
                        }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.accentColor)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        .padding(.trailing, 8)
                    }
                }
                .allowsHitTesting(true)
                .frame(minHeight: 240, maxHeight: 400)
            }
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
