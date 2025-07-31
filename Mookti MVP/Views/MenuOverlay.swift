//
//  MenuOverlayView.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑07‑03.
//

import SwiftUI

/// Slide‑out sidebar shown from the left edge.
///
/// Usage in `RootNavigationView`:
/// ```swift
/// MenuOverlayView(isVisible: $showMenu,
///                 onHome: { path = [] },
///                 onSettings: { path.append(.settings) },
///                 onHistory: { path.append(.history) },
///                 onLogout: { Task { await AuthService.shared.logout() } })
/// ```
struct MenuOverlayView: View {

    // MARK: - Controls
    @Binding var isVisible: Bool

    var onHome:     () -> Void = {}
    var onSettings: () -> Void = {}
    var onHistory:  () -> Void = {}
    var onLogout:   () -> Void = {}

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .leading) {
            // Tap‑to‑dismiss translucent scrim
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { isVisible = false } }

            // Sidebar panel
            VStack(alignment: .leading, spacing: 24) {

                // App logo
                HStack {
                    Text("mookti")
                        .font(.title2).bold()
                    Spacer()
                }

                Divider()

                // Navigation buttons
                Button { fire(onHome) } label: {
                    Label("Home", systemImage: "house")
                }

                Button { fire(onSettings) } label: {
                    Label("Settings", systemImage: "gear")
                }

                Button { fire(onHistory) } label: {
                    Label("History", systemImage: "book")
                }

                Spacer()

                Button(role: .destructive) {
                    fire(onLogout)
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
            .font(.headline)
            .padding(24)
            .frame(maxWidth: 280, maxHeight: .infinity, alignment: .topLeading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 12)
            .offset(x: isVisible ? 0 : -320)
            .ignoresSafeArea(edges: .vertical)
        }
        .animation(.easeOut(duration: 0.25), value: isVisible)
    }

    /// Helper that hides menu before firing callback
    private func fire(_ action: @escaping () -> Void) {
        withAnimation { isVisible = false }
        action()
    }
}

#if DEBUG
struct MenuOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        MenuOverlayView(isVisible: .constant(true))
            .previewDevice("iPhone 15")
    }
}
#endif
