//
//  EllenAIService.swift
//  Mookti
//
//  Simplified cloud-only version for MVP
//

import Foundation
import SwiftUI
import OSLog

/// Ellen‑specific AI service that always uses cloud AI (Claude via Vercel)
@MainActor
final class EllenAIService: ObservableObject {
    private static let logger = Logger(subsystem: "com.mookti.mvp", category: "EllenAI")
    
    // MARK: - Published State
    @Published private(set) var transcript: [Message] = []
    @Published private(set) var isThinking = false
    
    // MARK: - Private Properties
    private let settings: SettingsService
    
    // MARK: - Ellen's Socratic System Prompt
    private let systemPrompt = """
    You are Ellen, a wise and friendly AI agent built to help college and post-graduate level learners understand complex topics in fresh ways. Your primary pedagogical method is elenchus, the Greek term for Socratic dialogue. 
    
    As part of this approach to fostering student learning, you should:
    - Offer concise and clear insight as you move users toward and through aporia—moments of pause and reflection that consolidate lessons already given while stimulating wonder and a drive to learn more
    - Where students offer clear signs of emotional state, be sure to be a supportive mentor who celebrates small wins and an empathetic listener who validates feelings
    - When answering, ground your responses in data and cite research concisely
    - Reference specific examples from the provided content where relevant
    
    Your Practical Socratic approach means:
    • Provide direct, helpful answers FIRST when users ask specific questions
    • Follow answers with focused, accessible questions that deepen understanding
    • Challenge assumptions gently and progressively, not abruptly
    • Use clarifying questions to ensure you understand their needs
    • Build critical thinking through incremental steps, not philosophical leaps
    • Keep the dialogue moving forward with engaging, relevant prompts
    """
    
    // MARK: - Initialization
    init() {
        self.settings = SettingsService()
        
        Self.logger.info("🔧 EllenAIService: Initializing in cloud-only mode")
    }
    
    // MARK: - Public Methods
    
    /// Process user input and generate Ellen's response using cloud AI
    @MainActor
    func processUserInput(_ userInput: String) async {
        let interactionStartTime = Date()
        let requestId = UUID().uuidString
        
        Self.logger.info("💬 EllenAIService: Processing user input: '\(userInput.prefix(50))...'")
        Self.logger.debug("📊 EllenAIService: Current transcript has \(self.transcript.count) messages")
        
        // Add user message to transcript
        transcript.append(.init(role: .user, content: userInput))
        isThinking = true
        
        // Build chat context from transcript
        let chatContext = buildChatContext()
        
        // RAG context is now handled by Vercel Edge Function
        let ragDuration = 0.0
        
        // Always use cloud service
        Self.logger.info("☁️ EllenAIService: Using cloud service (Vercel/Claude)")
        await fetchFromCloud(
            userInput,
            chatContext: chatContext,
            interactionStartTime: interactionStartTime,
            requestId: requestId
        )
    }
    
    /// Clear the conversation transcript
    func clearTranscript() {
        transcript.removeAll()
        Self.logger.info("🗑️ EllenAIService: Transcript cleared")
    }
    
    // MARK: - Private Methods
    
    // RAG context is now handled by Vercel Edge Function
    
    /// Build chat context from recent transcript
    private func buildChatContext() -> String {
        // Include last 6 messages for context (3 exchanges)
        let recentMessages = transcript.suffix(6)
        return recentMessages.map { msg in
            "\(msg.role == .user ? "User" : "Ellen"): \(msg.content)"
        }.joined(separator: "\n\n")
    }
    
    /// Fetch response from cloud AI service
    @MainActor
    private func fetchFromCloud(
        _ userInput: String,
        chatContext: String,
        interactionStartTime: Date,
        requestId: String
    ) async {
        do {
            let cloudStartTime = Date()
            
            // Build the full prompt with context
            var fullPrompt = ""
            
            // Module overview is now handled by Vercel Edge Function
            
            // Add chat context if available
            if !chatContext.isEmpty {
                fullPrompt += "Recent Conversation:\n\n\(chatContext)\n\n"
            }
            
            // Add the current user input
            fullPrompt += "User: \(userInput)"
            
            // Library context (RAG) is now handled by Vercel Edge Function
            
            // Call CloudAIService with full context
            // The useRAG parameter enables RAG context retrieval in Vercel
            let response = try await CloudAIService.answer(
                for: fullPrompt,
                systemPrompt: systemPrompt
            )
            
            let cloudDuration = Date().timeIntervalSince(cloudStartTime)
            let totalDuration = Date().timeIntervalSince(interactionStartTime)
            
            // Add Ellen's response to transcript
            transcript.append(.init(role: .ellen, content: response))
            
            // Log the interaction
            await AIInteractionLogger.shared.logEllenInteraction(
                prompt: userInput,
                response: response,
                isOnDevice: false,
                ragNodes: [],  // RAG nodes retrieved by Vercel
                ragDuration: 0.0,  // RAG timing handled by Vercel
                generationDuration: cloudDuration,
                modelAvailability: "cloud"
            )
            
            Self.logger.info("☁️ Cloud AI complete: Total time: \(String(format: "%.2f", totalDuration))s (Cloud+RAG: \(String(format: "%.3f", cloudDuration))s)")
            
        } catch {
            Self.logger.error("❌ EllenAIService: Cloud AI failed - \(error.localizedDescription)")
            
            let errorMessage: String
            if let cloudError = error as? CloudAIError {
                switch cloudError {
                case .missingAPIKey:
                    errorMessage = "Cloud service not configured. Please check your settings."
                case .rateLimited:
                    errorMessage = "I need a moment to catch my breath. Please try again in a few seconds."
                case .authenticationRequired:
                    errorMessage = "Please sign in to continue our conversation."
                default:
                    errorMessage = "I'm having trouble connecting right now. Please try again."
                }
            } else {
                errorMessage = "I'm experiencing technical difficulties. Please try again in a moment."
            }
            
            transcript.append(.init(role: .ellen, content: errorMessage))
            
            // Log the error
            await AIInteractionLogger.shared.logEllenInteraction(
                prompt: userInput,
                response: "",
                isOnDevice: false,
                ragNodes: [],  // RAG nodes retrieved by Vercel
                ragDuration: 0.0,  // RAG timing handled by Vercel
                modelAvailability: "cloud",
                error: error.localizedDescription
            )
        }
        
        isThinking = false
    }
}