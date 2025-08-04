//
//  EllenChatView.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑07‑03.
//

import SwiftUI
import SwiftData

// Preference keys for tracking scroll metrics
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct EllenChatView: View {

    // ──────────────────────────────────────────────────────────────
    // Environment objects
    // ──────────────────────────────────────────────────────────────────
    // @EnvironmentObject private var ragPipeline: RAGPipeline // DEPRECATED: Using cloud-only RAG
    @EnvironmentObject private var contentGraph: ContentGraphService
    @EnvironmentObject private var settings: SettingsService
    @EnvironmentObject private var conversationStore: ConversationStore

    // The chat service lives inside a view‑model wrapper so we can attach
    // combine sinks (you'll extend EllenViewModel later as needed).
    @StateObject private var vm = EllenViewModel()
    @StateObject private var auth = AuthService.shared

    // Draft message
    @State private var draft = "" 

    // ScrollView proxy for auto‑scrolling
    @State private var scrollProxy: ScrollViewProxy?
    
    // Viewport tracking
    @State private var scrollViewHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isAtBottom: Bool = true
    @State private var isAtTop: Bool = true

    var body: some View {
        VStack(spacing: 0) {

            // ─── Transcript ────────────────────────────────────────────
            ScrollViewReader { proxy in
                GeometryReader { geometry in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.messages) { msg in
                            BubbleView(message: msg)
                                .id(msg.id)
                                .contextMenu {
                                    if msg.role == .ellen && msg.id == vm.messages.last?.id {
                                        Button("Undo AI Reply", role: .destructive) {
                                            vm.undoLastExchange()
                                        }
                                    }
                                }
                                .onChange(of: vm.messages.count) { oldValue, newValue in
                                    // Only auto-scroll if user is at bottom and new messages were added
                                    if isAtBottom && oldValue < newValue {
                                        scrollToBottom(proxy)
                                    }
                                }
                        }
                        
                        // Typing indicator / loading animation
                        if vm.isTyping || vm.isThinking {
                            TypingIndicatorBubble()
                                .id("typing-indicator")
                        }
                        
                        // Small spacer to prevent layout jump when paused
                        // Keeps consistent spacing whether paused or not
                        Color.clear
                            .frame(height: vm.hasMoreContent ? 20 : 0)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(GeometryReader { contentGeometry in
                        Color.clear
                            .preference(key: ContentHeightKey.self, value: contentGeometry.size.height)
                            .preference(key: ScrollOffsetPreferenceKey.self, value: contentGeometry.frame(in: .named("scroll")).minY)
                    })
                }
                // Allow a downward pull gesture at the bottom of the chat
                // to resume any paused content delivery without needing
                // to tap the Continue button.
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            // Negative translation.height means the user dragged
                            // upward (trying to scroll further down). Trigger
                            // continuation if we're paused at the bottom.
                            if value.translation.height < -20,
                               isAtBottom,
                               vm.hasMoreContent {
                                withAnimation(.easeOut) {
                                    vm.userScrolledDown()
                                }
                            }
                        }
                )
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ViewHeightKey.self) { value in
                    scrollViewHeight = value
                }
                .onPreferenceChange(ContentHeightKey.self) { value in
                    contentHeight = value
                    updateScrollState()
                }
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    updateScrollState()
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ViewHeightKey.self, value: geo.size.height)
                    }
                )
                .onAppear {
                    scrollProxy = proxy
                    scrollViewHeight = geometry.size.height
                    // Initially at bottom
                    isAtBottom = true
                    print("📱 EllenChatView: Initial viewport height=\(geometry.size.height)")
                    vm.updateScrollPosition(isAtBottom: true, viewportHeight: geometry.size.height)
                }
                .onChange(of: vm.isTyping) { _, isTyping in
                    if isTyping {
                        withAnimation {
                            proxy.scrollTo("typing-indicator", anchor: .bottom)
                        }
                    }
                }
                .onChange(of: vm.isThinking) { _, isThinking in
                    if isThinking {
                        withAnimation {
                            proxy.scrollTo("typing-indicator", anchor: .bottom)
                        }
                    }
                }
                }
            }

            // More content indicator when paused
            if vm.hasMoreContent {
                Button(action: {
                    // Directly trigger continuation
                    withAnimation(.easeOut) {
                        vm.userScrolledDown()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20))
                        Text("Continue")
                            .font(.footnote)
                    }
                    .foregroundColor(.accentColor)
                }
                .padding(.vertical, 8)
            }

            // Divider moved here
            Divider()
            
            // ─── Branch buttons ─────────────────────────────────────
            if !vm.branchOptions.isEmpty {
                BranchButtonsView(options: vm.branchOptions) { selected in
                    vm.chooseBranch(selected)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: vm.branchOptions.count)
            }

            // ─── Input bar ─────────────────────────────────────────────
            HStack(spacing: 12) {
                TextField(auth.isAdminMode ? "Ask Ellen… (Admin: //go to {id})" : "Ask Ellen…", 
                         text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .onSubmit {
                        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !vm.isThinking else { return }
                        let message = draft
                        draft = ""
                        Task { await vm.send(message) }
                    }

                Button {
                    let message = draft
                    draft = ""
                    Task { await vm.send(message) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isThinking)
            }
            .padding()
        }
        .navigationTitle(auth.isAdminMode ? "\(vm.moduleTitle) (Admin)" : vm.moduleTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!isAtTop)
        .toolbar {
            if !isAtTop {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            scrollProxy?.scrollTo(vm.messages.first?.id, anchor: .top)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        // Add invisible overlay at the top for tap-to-scroll-up functionality
        .overlay(alignment: .top) {
            if !isAtTop {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            scrollProxy?.scrollTo(vm.messages.first?.id, anchor: .top)
                        }
                    }
            }
        }
        .task {
            // Lazily inject the vector store and content graph once the view appears
            if vm.isUnconfigured {
                vm.configure(graph: contentGraph, history: conversationStore, settings: settings)
            }
        }
        .onReceive(vm.$isAtBottomRequired) { required in
            if required {
                vm.updateScrollPosition(isAtBottom: isAtBottom, viewportHeight: scrollViewHeight)
            }
        }
    }

    // Helper
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let lastID = vm.messages.last?.id {
            withAnimation {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        }
    }
    
    private func updateScrollState() {
        // Guard against invalid values that could cause NaN
        guard scrollViewHeight > 0 && contentHeight > 0 else {
            // Default state when dimensions aren't ready
            isAtBottom = true
            isAtTop = true
            return
        }
        
        // Calculate if we're at the bottom (with small tolerance)
        let tolerance: CGFloat = 20
        
        // In SwiftUI ScrollView, scrollOffset is the distance from the top
        // When at top: scrollOffset = 0
        // When scrolled down: scrollOffset becomes negative
        // At bottom: scrollOffset = -(contentHeight - scrollViewHeight)
        
        if contentHeight <= scrollViewHeight {
            // Content fits entirely in viewport
            isAtBottom = true
            isAtTop = true
        } else {
            // Calculate the position at the bottom
            let bottomOffset = -(contentHeight - scrollViewHeight)
            
            // Check if scrolled to bottom (within tolerance)
            isAtBottom = scrollOffset <= bottomOffset + tolerance
            
            // Check if at top (within tolerance)
            isAtTop = scrollOffset >= -tolerance
        }
        
        // Always update view model with current scroll state
        vm.updateScrollPosition(isAtBottom: isAtBottom, viewportHeight: scrollViewHeight)
    }
}

#if DEBUG
struct EllenChatView_Previews: PreviewProvider {
    static var previews: some View {
        // Simple UI-only preview
        VStack {
            Text("EllenChatView Preview")
                .font(.title)
            Text("Use device testing for full functionality")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Mock UI elements
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Mock user message
                    HStack {
                        Spacer()
                        Text("Hello Ellen!")
                            .padding(12)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .frame(maxWidth: 260, alignment: .trailing)
                    }
                    
                    // Mock Ellen response
                    HStack {
                        Text("Hi! I'm here to help with workplace success. What would you like to learn about?")
                            .padding(12)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .frame(maxWidth: 260, alignment: .leading)
                        Spacer()
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // Mock input
            HStack {
                TextField("Ask Ellen…", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                
                Button(action: {}) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                }
            }
            .padding()
        }
        .navigationTitle("Chat with Ellen")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
