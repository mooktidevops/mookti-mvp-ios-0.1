//
//  EllenViewModel.swift
//  Mookti
//

import Foundation
import Combine

@MainActor
final class EllenViewModel: ObservableObject {

    @Published private(set) var messages:  [Message] = []
    @Published private(set) var isThinking = false
    @Published private(set) var isTyping = false
    
    @Published private(set) var branchOptions: [LearningNode] = []
    
    @Published private(set) var moduleTitle: String = "Chat with Ellen"
    
    // Scroll management
    @Published var isAtBottomRequired = false
    @Published private(set) var isPaused = false
    @Published private(set) var hasMoreContent = false
    private var pendingNodeID: String?
    private var currentViewportHeight: CGFloat = 0
    private var isUserAtBottom = true
    
    // Track chosen branches to prevent loops
    // Key: parent aporia-system node ID, Value: Set of chosen option node IDs
    private var chosenBranches: [String: Set<String>] = [:]

    private var aiService: EllenAIService?
    private var cancellables = Set<AnyCancellable>()
    private var graph: ContentGraphService?
    private var currentNodeID: String?
    private var history: ConversationStore?
    private var settings: SettingsService?

    /// Flag so the view knows whether to inject the RAG provider
    var isUnconfigured: Bool { aiService == nil }

    /// Injects the vector store and content graph exactly once.
    func configure(graph: ContentGraphService,
                   history: ConversationStore,
                   settings: SettingsService) {
        print("🔧 EllenViewModel: Starting configuration...")
        guard aiService == nil else { 
            print("⚠️ EllenViewModel: Already configured, skipping")
            return 
        }
        
        print("📊 EllenViewModel: Setting up conversation history")
        self.history = history
        history.startNew(title: "Ellen Chat")
        self.graph = graph
        self.settings = settings
        
        print("🤖 EllenViewModel: Initializing AI service")
        let ai = EllenAIService()
        aiService = ai
        
        print("📊 EllenViewModel: Content graph has \(graph.nodes.count) nodes")
        
        // Load module title from chunk 0
        if let titleNode = graph.node(for: "0"), titleNode.type == .moduleTitle {
            moduleTitle = titleNode.content
            print("📝 EllenViewModel: Loaded module title: \(moduleTitle)")
        }
        
        // Since EllenAIService is now @Observable, we need to manually sync state
        // For now, we'll handle this through direct property access
        // In a production app, you might want to use proper observation
        
        // Start lesson at sequence_id = "1" and deliver initial content
        print("🎯 EllenViewModel: Loading initial content...")
        loadInitialContent()
        print("✅ EllenViewModel: Configuration complete")
    }
    
    /// Load initial content for new users
    private func loadInitialContent() {
        advance(to: "1")
    }

    // MARK: - Persistence
    private func persist(_ msg: Message) {
        history?.append(msg)
    }

    // MARK: - Branch choice
    func chooseBranch(_ node: LearningNode) {
        // Track this choice if we have a current node (the aporia-system that offered the choices)
        if let currentNode = currentNodeID {
            var choices = chosenBranches[currentNode] ?? Set<String>()
            choices.insert(node.id)
            chosenBranches[currentNode] = choices
        }
        
        // Add learner choice bubble
        let userMessage = Message(role: .user, content: node.content, source: .csv)
        messages.append(userMessage)
        persist(userMessage)
        
        branchOptions = []                       // hide buttons
        advance(to: node.nextChunkIDs.first)     // follow graph
    }
    
    // MARK: - Message Timing
    /// Calculate delay based on previous message length for natural reading flow
    /// Average reading speed: ~200-250 words per minute
    /// Returns delay in seconds
    private func calculateMessageDelay() -> Double {
        // Get the previous message if it exists
        guard messages.count >= 2 else { return 1.0 }
        
        let previousMessage = messages[messages.count - 2]
        let messageLength = previousMessage.content.count
        
        // Base delay of 1 second for zero-length messages
        let baseDelay = 1.0
        
        // Calculate words (rough estimate: 5 characters per word)
        let estimatedWords = Double(messageLength) / 5.0
        
        // Reading speed: 225 words per minute (middle of average range)
        let wordsPerSecond = 225.0 / 60.0
        
        // Calculate time needed to read
        let readingTime = estimatedWords / wordsPerSecond
        
        // Add base delay to reading time, with a max cap of 5 seconds
        let calculatedDelay = min(baseDelay + readingTime, 5.0)
        
        // Apply user's speed preference (inverse relationship: lower value = slower)
        let speedMultiplier = settings?.messageDeliverySpeed ?? 1.0
        return calculatedDelay / speedMultiplier
    }

    // MARK: - Graph traversal
    private func advance(to id: String?) {
        guard let id,
              let node = graph?.node(for: id) else { return }

        currentNodeID = id
        
        // Check if we should pause before delivering this message
        // For carousel and media types, use estimated heights
        let contentToCheck: String
        switch node.type {
        case .cardCarousel:
            contentToCheck = "CAROUSEL_PLACEHOLDER" // Will be handled specially in height estimation
        case .media:
            contentToCheck = "MEDIA_PLACEHOLDER" // Will be handled specially in height estimation
        default:
            contentToCheck = node.content
        }
        
        if shouldPauseForScroll(nextContent: contentToCheck, nodeType: node.type) {
            isPaused = true
            hasMoreContent = true
            pendingNodeID = id
            isTyping = false // Hide typing indicator while paused
            return
        }

        // Handle different node types
        // Don't show aporia-user, card-carousel, or media nodes as system messages
        if node.type != .aporiaUser && node.type != .cardCarousel && node.type != .media {
            let systemMessage = Message(role: .system, content: node.content, source: .csv)
            messages.append(systemMessage)
            persist(systemMessage)
        }

        switch node.type {
        case .cardCarousel:
            // Add carousel as a message in the chat
            if let carouselPayload = node.asCarouselPayload() {
                let carouselMessage = Message(
                    role: .system, 
                    content: "Card Carousel", // Placeholder content
                    source: .csv,
                    carouselPayload: carouselPayload
                )
                messages.append(carouselMessage)
                persist(carouselMessage)
            } else {
                // If parsing fails, show the raw content as a fallback
                print("⚠️ Failed to parse carousel content for node \(id), showing raw content")
                let fallbackMessage = Message(
                    role: .system,
                    content: "Card Carousel: \(node.content)",
                    source: .csv
                )
                messages.append(fallbackMessage)
                persist(fallbackMessage)
            }
            // Don't auto-advance - wait for user interaction or add delay
            Task {
                let delay = calculateMessageDelay()
                isTyping = true
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                isTyping = false
                advance(to: node.nextChunkIDs.first)
            }

        case .aporiaSystem:
            // Check first if we should pause before showing typing indicator
            if shouldPauseForScroll(nextContent: "BRANCH_OPTIONS", nodeType: .aporiaSystem) {
                isPaused = true
                hasMoreContent = true
                pendingNodeID = id
                isTyping = false
            } else {
                // Show typing indicator and delay before showing options
                Task {
                    let delay = calculateMessageDelay()
                    isTyping = true
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    isTyping = false
                    
                    // Double-check scroll position after delay
                    if shouldPauseForScroll(nextContent: "BRANCH_OPTIONS", nodeType: .aporiaSystem) {
                        isPaused = true
                        hasMoreContent = true
                        pendingNodeID = id
                    } else {
                        // Filter out already chosen options
                        let allOptions = node.nextChunkIDs.compactMap { graph?.node(for: $0) }
                        let chosenIds = chosenBranches[id] ?? Set<String>()
                        let availableOptions = allOptions.filter { !chosenIds.contains($0.id) }
                        
                        if availableOptions.isEmpty && !allOptions.isEmpty {
                            // All options have been explored
                            handleAllOptionsExplored(at: id, with: allOptions)
                        } else {
                            branchOptions = availableOptions
                        }
                    }
                }
            }
            // Don't auto-advance for aporia-system nodes - wait for user input

        case .aporiaUser:
            // Aporia-user should be shown as a branch option, not a system message
            // Create a single-option branch for standalone aporia-user nodes
            // Check first if we should pause before showing typing indicator
            if shouldPauseForScroll(nextContent: "BRANCH_OPTIONS", nodeType: .aporiaUser) {
                isPaused = true
                hasMoreContent = true
                pendingNodeID = id
                isTyping = false
            } else {
                // Show typing indicator and delay before showing options
                Task {
                    let delay = calculateMessageDelay()
                    isTyping = true
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    isTyping = false
                    
                    // Double-check scroll position after delay
                    if shouldPauseForScroll(nextContent: "BRANCH_OPTIONS", nodeType: .aporiaUser) {
                        isPaused = true
                        hasMoreContent = true
                        pendingNodeID = id
                    } else {
                        // For standalone aporia-user nodes, check if already chosen
                        // The parent would be the node that led to this one
                        if let parentId = findParentNode(for: id) {
                            let chosenIds = chosenBranches[parentId] ?? Set<String>()
                            if !chosenIds.contains(id) {
                                branchOptions = [node]
                            } else {
                                // This option was already chosen, advance to next
                                advance(to: node.nextChunkIDs.first)
                            }
                        } else {
                            branchOptions = [node]
                        }
                    }
                }
            }
            // Don't auto-advance - wait for user selection

        case .media:
            // Show media content as a system message
            let mediaMessage = Message(role: .system, content: node.content, source: .csv)
            messages.append(mediaMessage)
            persist(mediaMessage)
            branchOptions = []
            // Auto-advance after showing media
            Task {
                let delay = calculateMessageDelay()
                // Show typing indicator during the delay
                isTyping = true
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                isTyping = false
                advance(to: node.nextChunkIDs.first)
            }

        case .system:
            branchOptions = []
            // Auto-advance system messages after a delay based on previous message length
            Task {
                let delay = calculateMessageDelay()
                // Show typing indicator during the delay
                isTyping = true
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                isTyping = false
                
                // Check again if we need to advance to next content
                if let nextId = node.nextChunkIDs.first {
                    advance(to: nextId)
                }
            }

        default:
            branchOptions = []
            advance(to: node.nextChunkIDs.first)
        }
    }

    func send(_ text: String) async {
        print("💬 EllenViewModel: Received user input: '\(String(text.prefix(50)))...'")
        
        // Check for admin commands
        if text.hasPrefix("//") {
            print("🔧 EllenViewModel: Processing admin command")
            await handleAdminCommand(text)
            return
        }
        
        guard let aiService else { 
            print("⚠️ EllenViewModel: aiService is nil, cannot send message")
            let errorMessage = Message(role: .system, content: "⚠️ AI service not available. Please restart the app.", source: .csv)
            messages.append(errorMessage)
            persist(errorMessage)
            return 
        }
        
        print("📝 EllenViewModel: Adding user message to transcript")
        let userMessage = Message(role: .user, content: text, source: .csv)
        messages.append(userMessage)
        persist(userMessage)
        
        let messageCountBefore = messages.count
        
        // Update our local isThinking state
        print("🤔 EllenViewModel: Setting thinking state to true")
        isThinking = true
        
        let startTime = Date()
        print("🚀 EllenViewModel: Sending to AI service...")
        await aiService.processUserInput(text)
        let totalDuration = Date().timeIntervalSince(startTime)
        
        print("📊 EllenViewModel: AI service completed in \(String(format: "%.2f", totalDuration))s")
        
        
        // Sync Ellen's response from AI service
        let ellenMessages = aiService.transcript.filter { $0.role == .ellen }
        if let lastEllenMessage = ellenMessages.last {
            print("✅ EllenViewModel: Received AI response: '\(String(lastEllenMessage.content.prefix(100)))...'")
            // Create a new message with AI-generated or AI-retrieved source
            // For now, assuming all Ellen responses are AI-generated
            // TODO: Update this when we implement RAG retrieval to use .aiRetrieved
            let aiMessage = Message(
                role: lastEllenMessage.role,
                content: lastEllenMessage.content,
                source: .aiGenerated
            )
            messages.append(aiMessage)
            persist(aiMessage)
        } else {
            print("⚠️ EllenViewModel: No AI response received")
            let fallbackMessage = Message(role: .ellen, content: "I'm having trouble responding right now. Could you try rephrasing your question?", source: .aiGenerated)
            messages.append(fallbackMessage)
            persist(fallbackMessage)
        }
        
        let messageCountAfter = messages.count
        print("📊 EllenViewModel: Message count changed from \(messageCountBefore) to \(messageCountAfter)")
        
        isThinking = false
        print("💭 EllenViewModel: Thinking state set to false")
    }
    
    /// Handle admin commands starting with "//"
    private func handleAdminCommand(_ command: String) async {
        let cleanCommand = String(command.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        
        // Validate command length
        guard !cleanCommand.isEmpty else {
            let errorMessage = Message(role: .system, content: "⚠️ Empty admin command", source: .csv)
            messages.append(errorMessage)
            persist(errorMessage)
            return
        }
        
        // Parse "go to {sequence_id}" command
        if cleanCommand.lowercased().hasPrefix("go to ") {
            let sequenceID = String(cleanCommand.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            
            // Validate sequence ID format
            guard !sequenceID.isEmpty && sequenceID.count <= 20 else {
                let errorMessage = Message(role: .system, content: "⚠️ Invalid sequence ID format", source: .csv)
                messages.append(errorMessage)
                persist(errorMessage)
                return
            }
            
            // Add admin command to chat for visibility
            let adminMessage = Message(role: .user, content: "// \(cleanCommand)", source: .csv)
            messages.append(adminMessage)
            persist(adminMessage)
            
            // Navigate to the specified sequence
            navigateToSequence(sequenceID)
        } else {
            // Unknown admin command
            let errorMessage = Message(role: .system, content: "Unknown admin command: \(cleanCommand). Available: 'go to {id}'", source: .csv)
            messages.append(errorMessage)
            persist(errorMessage)
        }
    }
    
    /// Navigate directly to a sequence ID (admin function)
    private func navigateToSequence(_ sequenceID: String) {
        guard let graph = graph,
              graph.node(for: sequenceID) != nil else {
            let errorMessage = Message(role: .system, content: "⚠️ Sequence '\(sequenceID)' not found", source: .csv)
            messages.append(errorMessage)
            persist(errorMessage)
            return
        }
        
        // Clear current state
        branchOptions = []
        
        // Add confirmation message
        let confirmMessage = Message(role: .system, content: "📍 Navigated to sequence: \(sequenceID)", source: .csv)
        messages.append(confirmMessage)
        persist(confirmMessage)
        
        // Advance to the target sequence
        advance(to: sequenceID)
    }
    
    func undoLastExchange() {
        guard messages.count >= 2 else { return }
        // HIG Compliance: Remove last Ellen reply + the originating user question
        messages.removeLast(2)

    }
    
    // MARK: - Scroll Management
    func updateScrollPosition(isAtBottom: Bool, viewportHeight: CGFloat) {
        let wasAtBottom = isUserAtBottom
        isUserAtBottom = isAtBottom
        currentViewportHeight = viewportHeight
        isAtBottomRequired = false
        
        // Resume if user has scrolled down (not necessarily to bottom) and we have pending content
        // This prevents indefinite pause - any downward scroll triggers continuation
        if !wasAtBottom && isUserAtBottom && isPaused, let pendingID = pendingNodeID {
            // User scrolled down, resume delivery
            resumePendingContent(pendingID)
        } else if isPaused && pendingNodeID != nil {
            // Also resume if user is within reasonable distance of bottom
            // This handles cases where user might not reach exact bottom
            if isAtBottom || isNearBottom(threshold: 100) {
                if let pendingID = pendingNodeID {
                    resumePendingContent(pendingID)
                }
            }
        }
    }
    
    /// Called when user scrolls down - used to trigger content delivery
    func userScrolledDown() {
        // If we have paused content and user is scrolling down, resume delivery
        if isPaused, let pendingID = pendingNodeID {
            resumePendingContent(pendingID)
        }
    }
    
    private func isNearBottom(threshold: CGFloat) -> Bool {
        // This would need to be calculated based on scroll offset
        // For now, we'll rely on the isAtBottom flag
        // Could be enhanced with actual scroll offset tracking
        return false
    }
    
    private func resumePendingContent(_ pendingID: String) {
        isPaused = false
        hasMoreContent = false
        pendingNodeID = nil
        
        // Check if we need to show branch options
        if let node = graph?.node(for: pendingID) {
            switch node.type {
            case .aporiaSystem:
                // Filter out already chosen options
                let allOptions = node.nextChunkIDs.compactMap { graph?.node(for: $0) }
                let chosenIds = chosenBranches[pendingID] ?? Set<String>()
                let availableOptions = allOptions.filter { !chosenIds.contains($0.id) }
                
                if availableOptions.isEmpty && !allOptions.isEmpty {
                    // All options explored, advance
                    handleAllOptionsExplored(at: pendingID, with: allOptions)
                } else {
                    branchOptions = availableOptions
                }
            case .aporiaUser:
                // Check if this was already chosen
                if let parentId = findParentNode(for: pendingID) {
                    let chosenIds = chosenBranches[parentId] ?? Set<String>()
                    if !chosenIds.contains(pendingID) {
                        branchOptions = [node]
                    } else {
                        advance(to: node.nextChunkIDs.first)
                    }
                } else {
                    branchOptions = [node]
                }
            default:
                advance(to: pendingID)
            }
        }
    }
    
    /// Estimate if a message will fit in the current viewport
    private func estimateMessageHeight(for content: String, nodeType: LearningNode.DisplayType? = nil) -> CGFloat {
        // Handle special content types
        if content == "CAROUSEL_PLACEHOLDER" || nodeType == .cardCarousel {
            // Card carousel height: cards (160) + padding + spacing
            return 180
        }
        
        if content == "MEDIA_PLACEHOLDER" || nodeType == .media {
            // Media content varies but assume a reasonable default
            // Most media thumbnails are around 200-250 in height
            return 250
        }
        
        if content == "BRANCH_OPTIONS" || nodeType == .aporiaSystem || nodeType == .aporiaUser {
            // Branch buttons with new inline design
            // Each button: ~38 height (10+10 padding + 18 text) + 8 spacing
            // Container: 16 vertical padding (8+8)
            let buttonCount = (nodeType == .aporiaUser) ? 1 : 3 // Estimate 3 options for aporiaSystem
            return CGFloat(buttonCount * 46 + 16)
        }
        
        // More accurate estimation based on typical bubble dimensions
        // Assume max width of 260 points (from BubbleView)
        // Average character width ~8 points with system font
        let maxCharsPerLine = 32 // 260 / 8
        
        // Calculate number of lines
        let words = content.split(separator: " ")
        var lines = 1
        var currentLineLength = 0
        
        for word in words {
            let wordLength = word.count + 1 // +1 for space
            if currentLineLength + wordLength > maxCharsPerLine {
                lines += 1
                currentLineLength = wordLength
            } else {
                currentLineLength += wordLength
            }
        }
        
        // Height calculation:
        // - 24 points per line (line height)
        // - 24 points for padding (12 top + 12 bottom)
        // - 12 points for spacing between messages
        let textHeight = CGFloat(lines) * 24
        let paddingHeight: CGFloat = 24
        let spacingHeight: CGFloat = 12
        
        return textHeight + paddingHeight + spacingHeight
    }
    
    /// Check if delivering next message would require scrolling
    private func shouldPauseForScroll(nextContent: String, nodeType: LearningNode.DisplayType? = nil) -> Bool {
        // Don't pause if viewport height not yet known
        guard currentViewportHeight > 0 else { return false }
        
        // Always check current scroll position first
        guard isUserAtBottom else { return false }
        
        let estimatedHeight = estimateMessageHeight(for: nextContent, nodeType: nodeType)
        
        // Increase threshold - if message is longer than 60% of viewport, deliver anyway
        if estimatedHeight > currentViewportHeight * 0.6 {
            return false
        }
        
        // Calculate remaining space with more generous buffer
        // Account for input bar (~80), typing indicator (~40), and minimal padding (~20)
        let uiChromeHeight: CGFloat = 140
        let availableViewportHeight = currentViewportHeight - uiChromeHeight
        
        // Calculate currently visible content with smaller check window
        var currentlyVisibleHeight: CGFloat = 0
        let recentMessageCount = min(5, messages.count) // Check fewer messages
        
        for message in messages.suffix(recentMessageCount) {
            let msgHeight = estimateMessageHeight(for: message.content)
            currentlyVisibleHeight += msgHeight
            
            if currentlyVisibleHeight > availableViewportHeight * 0.7 {
                break
            }
        }
        
        // Add typing indicator height if shown
        if isTyping {
            currentlyVisibleHeight += 40
        }
        
        // More generous threshold - only pause if really needed
        let totalHeightAfterNewContent = currentlyVisibleHeight + estimatedHeight
        
        // Only pause if new content would significantly exceed viewport
        return totalHeightAfterNewContent > availableViewportHeight * 1.2
    }
    
    /// Find the parent node that leads to a given node ID
    private func findParentNode(for targetId: String) -> String? {
        guard let graph = graph else { return nil }
        
        // Search all nodes to find which one has targetId in its nextChunkIDs
        for (nodeId, node) in graph.nodes {
            if node.nextChunkIDs.contains(targetId) {
                return nodeId
            }
        }
        return nil
    }
    
    /// Handle when all branch options have been explored
    private func handleAllOptionsExplored(at nodeId: String, with allOptions: [LearningNode]) {
        guard let graph = graph else { return }
        
        // Special handling for known loop scenarios
        if nodeId == "15.2.1" || nodeId == "15.3.1" {
            // These are the main loop points in the US-China scenario
            let exitMessage = Message(
                role: .system,
                content: "Great exploration! You've considered all the different approaches to this diplomatic scenario. Let's continue to see how cultural intelligence helps resolve it.",
                source: .csv
            )
            messages.append(exitMessage)
            persist(exitMessage)
            
            // Exit to node 16 which continues the story
            advance(to: "16")
        } else if nodeId == "15.1.1.1.1.1.1" {
            // Another loop point that should exit to understanding motivations
            let exitMessage = Message(
                role: .system,
                content: "You've shown excellent cultural awareness by exploring these questions! Let's move forward to understand the deeper motivations at play.",
                source: .csv
            )
            messages.append(exitMessage)
            persist(exitMessage)
            
            // Exit to node 16
            advance(to: "16")
        } else {
            // Generic handling for other cases
            let summaryMessage = Message(
                role: .system,
                content: "You've explored all the available options here. Let's continue with the lesson.",
                source: .csv
            )
            messages.append(summaryMessage)
            persist(summaryMessage)
            
            // Try to find the next logical node by looking at where all options lead
            var commonNextNodes = Set<String>()
            var isFirst = true
            
            for option in allOptions {
                if let optionNode = graph.node(for: option.id) {
                    let nextSet = Set(optionNode.nextChunkIDs)
                    if isFirst {
                        commonNextNodes = nextSet
                        isFirst = false
                    } else {
                        commonNextNodes = commonNextNodes.intersection(nextSet)
                    }
                }
            }
            
            // If there's a common next node, go there
            if let nextId = commonNextNodes.first {
                advance(to: nextId)
            } else if let firstOption = allOptions.first,
                      let firstNode = graph.node(for: firstOption.id),
                      let nextId = firstNode.nextChunkIDs.first {
                // Otherwise, follow the first option's path
                advance(to: nextId)
            }
        }
    }

}
