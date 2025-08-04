//
//  RootNavigationView.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑07‑03.
//

import SwiftUI

struct RootNavigationView: View {

    // MARK: - Environment objects
    @EnvironmentObject private var contentGraph     : ContentGraphService
    @EnvironmentObject private var userProgress     : UserProgressService

    // MARK: - Global auth
    @StateObject private var auth = AuthService.shared

    // MARK: - Local UI state
    @State private var showMenu   = false
    @State private var navPath    = NavigationPath()

    // Routing enum
    private enum Route: Hashable {
        case chat, settings, history, teams
    }

    var body: some View {
        ZStack(alignment: .leading) {

            // ─── Main flow (blurred when menu open) ────────────────────
            Group {
                if auth.isSignedIn {
                    signedInStack
                } else {
                    LoginView()
                }
            }
            .disabled(showMenu)
            .blur(radius: showMenu ? 3 : 0)

            // ─── Menu overlay ─────────────────────────────────────────
            if showMenu {
                MenuOverlayView(
                    isVisible: $showMenu,
                    onHome:     { navPath = NavigationPath() },
                    onSettings: { navPath.append(Route.settings) },
                    onHistory:  { navPath.append(Route.history) },
                    onLogout:   { Task { await auth.logout() } }
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.25), value: showMenu)
    }

    // MARK: - Signed‑in navigation stack
    private var signedInStack: some View {
        NavigationStack(path: $navPath) {
            HomeView(onContinue: { navPath.append(Route.chat) },
                     onEllen: { navPath.append(Route.chat) },
                     onTeams: { navPath.append(Route.teams) },
                     onHistory: { navPath.append(Route.history) })
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .chat:
                        EllenChatView(
                            onHome: { navPath = NavigationPath() },
                            onEllen: { /* Already on Ellen chat */ },
                            onTeams: { 
                                navPath = NavigationPath()
                                navPath.append(Route.teams)
                            }
                        )
                    case .settings: SettingsView()
                    case .history : ConversationHistoryView()
                    case .teams: TeamsView(
                        onHome: { navPath = NavigationPath() },
                        onEllen: { navPath.append(Route.chat) }
                    )
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { withAnimation { showMenu.toggle() } }) {
                            Image(systemName: "line.3.horizontal")
                                .imageScale(.large)
                                .accessibilityLabel("Menu")
                        }
                    }
                }
        }
    }
}

#if DEBUG
struct RootNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        RootNavigationView()
            .environmentObject(ContentGraphService())
            .environmentObject(UserProgressService())
            .environmentObject(AuthService.shared)
    }
}
#endif
