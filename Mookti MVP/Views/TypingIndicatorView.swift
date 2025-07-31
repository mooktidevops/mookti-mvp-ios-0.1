//
//  TypingIndicatorView.swift
//  Mookti MVP
//
//  Created on 2025-07-21.
//

import SwiftUI

struct TypingIndicatorView: View {
    @State private var animatingDot = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatingDot == index ? 1.3 : 1.0)
                    .opacity(animatingDot == index ? 0.6 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: animatingDot
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onAppear {
            animatingDot = 0
            withAnimation {
                animatingDot = 2
            }
        }
    }
}

struct TypingIndicatorBubble: View {
    var body: some View {
        HStack {
            TypingIndicatorView()
            Spacer()
        }
        .padding(.horizontal)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

#Preview {
    VStack {
        TypingIndicatorView()
        Spacer()
        TypingIndicatorBubble()
    }
    .padding()
}