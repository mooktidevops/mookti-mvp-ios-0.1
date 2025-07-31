//
//  AIInteractionLogger.swift
//  Mookti MVP
//
//  Comprehensive AI interaction logging using OSLog
//

import Foundation
import OSLog

@MainActor
final class AIInteractionLogger {
    static let shared = AIInteractionLogger()
    
    private let logger = Logger(subsystem: "com.mookti.mvp", category: "AIInteraction")
    private var currentSessionId: String
    
    private init() {
        self.currentSessionId = UUID().uuidString
    }
    
    func startNewSession() {
        currentSessionId = UUID().uuidString
        logger.info("🆕 Started new AI session: \(self.currentSessionId)")
    }
    
    func logEllenInteraction(
        prompt: String,
        response: String,
        isOnDevice: Bool,
        ragNodes: [(id: String, content: String)]? = nil,
        ragDuration: TimeInterval? = nil,
        generationDuration: TimeInterval? = nil,
        streamingDuration: TimeInterval? = nil,
        chunkCount: Int? = nil,
        temperature: Double? = nil,
        modelAvailability: String? = nil,
        error: String? = nil,
        requestId: String? = nil
    ) {
        let interactionId = UUID().uuidString
        let timestamp = Date()
        
        // Firebase logging integration
        let totalDuration = (ragDuration ?? 0) + (generationDuration ?? 0)
        FirebaseLogger.shared.logAIInteraction(
            service: "EllenAI",
            type: isOnDevice ? "on_device" : "cloud",
            model: modelAvailability ?? "unknown",
            query: prompt,
            response: error == nil ? response : nil,
            duration: totalDuration,
            tokenCount: response.count / 4,
            success: error == nil,
            error: error != nil ? NSError(domain: "AIInteraction", code: -1, userInfo: [NSLocalizedDescriptionKey: error!]) : nil,
            requestId: requestId ?? interactionId,
            additionalParams: [
                "session_id": currentSessionId,
                "interaction_id": interactionId,
                "rag_node_count": ragNodes?.count ?? 0,
                "has_error": error != nil
            ]
        )
        
        // Log main interaction info
        logger.info("""
        🤖 AI Interaction [\(interactionId)]
        ├─ Session: \(self.currentSessionId)
        ├─ Timestamp: \(timestamp.ISO8601Format())
        ├─ Type: \(isOnDevice ? "On-Device" : "Cloud")
        ├─ Model: \(modelAvailability ?? "unknown")
        └─ Status: \(error == nil ? "✅ Success" : "❌ Error")
        """)
        
        // Log prompt details
        logger.debug("""
        📝 Prompt [\(interactionId)]:
        \(prompt)
        Length: \(prompt.count) characters
        """)
        
        // Log RAG context if available
        if let nodes = ragNodes, let duration = ragDuration {
            logger.info("""
            🔍 RAG Context [\(interactionId)]:
            ├─ Retrieved \(nodes.count) nodes in \(String(format: "%.3f", duration))s
            └─ Node IDs: \(nodes.map { $0.id }.joined(separator: ", "))
            """)
            
            // Log node content at debug level
            for (index, node) in nodes.enumerated() {
                logger.debug("""
                📄 Node \(index + 1) [\(node.id)]:
                \(String(node.content.prefix(200)))...
                """)
            }
        }
        
        // Log response details
        if error == nil {
            logger.debug("""
            💬 Response [\(interactionId)]:
            \(response)
            Length: \(response.count) characters
            """)
        } else {
            logger.error("""
            ❌ Error [\(interactionId)]:
            \(error ?? "Unknown error")
            Response: \(response)
            """)
        }
        
        // Log performance metrics
        var performanceMetrics: [String] = []
        if let ragDuration = ragDuration {
            performanceMetrics.append("RAG: \(String(format: "%.3f", ragDuration))s")
        }
        if let generationDuration = generationDuration {
            performanceMetrics.append("Generation: \(String(format: "%.3f", generationDuration))s")
        }
        if let streamingDuration = streamingDuration {
            performanceMetrics.append("Streaming: \(String(format: "%.3f", streamingDuration))s")
        }
        if let chunkCount = chunkCount {
            performanceMetrics.append("Chunks: \(chunkCount)")
        }
        if let temperature = temperature {
            performanceMetrics.append("Temperature: \(temperature)")
        }
        
        if !performanceMetrics.isEmpty {
            logger.info("""
            ⚡ Performance [\(interactionId)]:
            \(performanceMetrics.joined(separator: " | "))
            """)
        }
        
        // Log summary for easy filtering
        logger.notice("""
        📊 AI Summary [\(interactionId)]: \
        \(isOnDevice ? "On-Device" : "Cloud") | \
        \(error == nil ? "Success" : "Failed") | \
        Prompt: \(prompt.count) chars | \
        Response: \(response.count) chars | \
        Total time: \(String(format: "%.2f", (generationDuration ?? 0) + (ragDuration ?? 0)))s
        """)
    }
}