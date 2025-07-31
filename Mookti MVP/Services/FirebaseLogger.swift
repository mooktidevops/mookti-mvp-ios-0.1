//
//  FirebaseLogger.swift
//  Mookti MVP
//

import Foundation
import FirebaseAnalytics
import FirebaseCrashlytics
import FirebasePerformance

/// Centralized logging service using Firebase Analytics and Crashlytics
class FirebaseLogger {
    static let shared = FirebaseLogger()
    
    private init() {}
    
    // MARK: - AI Interaction Logging
    
    /// Log AI interaction events with detailed parameters
    func logAIInteraction(
        service: String,
        type: String,
        model: String? = nil,
        query: String? = nil,
        response: String? = nil,
        duration: TimeInterval? = nil,
        tokenCount: Int? = nil,
        success: Bool = true,
        error: Error? = nil,
        requestId: String? = nil,
        additionalParams: [String: Any]? = nil
    ) {
        // Log to Analytics
        var parameters: [String: Any] = [
            "ai_service": service,
            "interaction_type": type,
            "success": success
        ]
        
        if let model = model {
            parameters["model"] = model
        }
        
        if let duration = duration {
            parameters["duration_ms"] = Int(duration * 1000)
        }
        
        if let tokenCount = tokenCount {
            parameters["token_count"] = tokenCount
        }
        
        if let error = error {
            parameters["error_type"] = String(describing: Swift.type(of: error))
            parameters["error_message"] = error.localizedDescription
        }
        
        if let requestId = requestId {
            parameters["request_id"] = requestId
        }
        
        // Merge additional parameters
        if let additionalParams = additionalParams {
            parameters.merge(additionalParams) { (_, new) in new }
        }
        
        Analytics.logEvent("ai_interaction", parameters: parameters)
        
        // Log to Crashlytics for debugging
        let logMessage = "AI Interaction: \(service) - \(type)"
        Crashlytics.crashlytics().log(logMessage)
        
        if let query = query {
            Crashlytics.crashlytics().setCustomValue(String(query.prefix(100)), forKey: "last_ai_query")
        }
        
        if let response = response {
            Crashlytics.crashlytics().setCustomValue(String(response.prefix(100)), forKey: "last_ai_response")
        }
        
        if let error = error {
            Crashlytics.crashlytics().record(error: error)
        }
    }
    
    // MARK: - Performance Tracking
    
    /// Start a performance trace for AI operations
    func startTrace(name: String) -> Trace? {
        let trace = Performance.sharedInstance().trace(name: name)
        trace?.start()
        return trace
    }
    
    /// Log custom metrics to a trace
    func addMetric(to trace: Trace?, name: String, value: Int64) {
        trace?.setValue(value, forMetric: name)
    }
    
    // MARK: - User Properties
    
    /// Set user properties for better segmentation
    func setUserProperty(name: String, value: String?) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    // MARK: - Screen Tracking
    
    /// Log screen views for navigation tracking
    func logScreenView(screenName: String, screenClass: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass
        ])
    }
    
    // MARK: - Custom Events
    
    /// Log custom app events
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
    
    // MARK: - Conversation Logging
    
    /// Log conversation-related events
    func logConversation(action: String, conversationId: String? = nil, messageCount: Int? = nil) {
        var parameters: [String: Any] = ["action": action]
        
        if let conversationId = conversationId {
            parameters["conversation_id"] = conversationId
        }
        
        if let messageCount = messageCount {
            parameters["message_count"] = messageCount
        }
        
        Analytics.logEvent("conversation_event", parameters: parameters)
    }
    
    // MARK: - Error Logging
    
    /// Log non-fatal errors with context
    func logError(_ error: Error, context: String? = nil) {
        if let context = context {
            Crashlytics.crashlytics().log("Error Context: \(context)")
        }
        Crashlytics.crashlytics().record(error: error)
    }
    
    // MARK: - Debug Logging
    
    /// Log debug information (only in debug builds)
    func debug(_ message: String) {
        #if DEBUG
        Crashlytics.crashlytics().log("[DEBUG] \(message)")
        #endif
    }
    
    // MARK: - AI Request/Response Logging
    
    /// Log detailed AI request information
    func logAIRequest(
        requestId: String,
        service: String,
        endpoint: String,
        model: String,
        promptLength: Int,
        systemPromptLength: Int? = nil,
        temperature: Double? = nil,
        maxTokens: Int? = nil
    ) {
        var parameters: [String: Any] = [
            "request_id": requestId,
            "service": service,
            "endpoint": endpoint,
            "model": model,
            "prompt_length": promptLength
        ]
        
        if let systemPromptLength = systemPromptLength {
            parameters["system_prompt_length"] = systemPromptLength
        }
        
        if let temperature = temperature {
            parameters["temperature"] = temperature
        }
        
        if let maxTokens = maxTokens {
            parameters["max_tokens"] = maxTokens
        }
        
        Analytics.logEvent("ai_request", parameters: parameters)
        
        // Log to Crashlytics
        let logMessage = "[AI_REQUEST] ID: \(requestId) | Service: \(service) | Model: \(model) | Prompt: \(promptLength) chars"
        Crashlytics.crashlytics().log(logMessage)
        
        // Set custom keys for crash context
        Crashlytics.crashlytics().setCustomValue(requestId, forKey: "last_ai_request_id")
        Crashlytics.crashlytics().setCustomValue(model, forKey: "last_ai_model")
    }
    
    /// Log AI response details
    func logAIResponse(
        requestId: String,
        statusCode: Int,
        responseLength: Int,
        tokenCount: Int? = nil,
        duration: TimeInterval,
        error: Error? = nil
    ) {
        var parameters: [String: Any] = [
            "request_id": requestId,
            "status_code": statusCode,
            "response_length": responseLength,
            "duration_ms": Int(duration * 1000)
        ]
        
        if let tokenCount = tokenCount {
            parameters["token_count"] = tokenCount
        }
        
        if let error = error {
            parameters["error"] = error.localizedDescription
        }
        
        Analytics.logEvent("ai_response", parameters: parameters)
        
        // Performance metric
        let trace = Performance.sharedInstance().trace(name: "ai_request_\(requestId)")
        trace?.start()
        if let trace = trace {
            trace.setValue(Int64(responseLength), forMetric: "response_length")
            if let tokenCount = tokenCount {
                trace.setValue(Int64(tokenCount), forMetric: "token_count")
            }
            trace.stop()
        }
    }
    
    /// Log RAG (Retrieval Augmented Generation) performance
    func logRAGPerformance(
        requestId: String,
        nodeCount: Int,
        retrievalDuration: TimeInterval,
        contextLength: Int
    ) {
        let parameters: [String: Any] = [
            "request_id": requestId,
            "node_count": nodeCount,
            "retrieval_duration_ms": Int(retrievalDuration * 1000),
            "context_length": contextLength
        ]
        
        Analytics.logEvent("rag_performance", parameters: parameters)
    }
    
    /// Log network performance metrics
    func logNetworkPerformance(
        requestId: String,
        endpoint: String,
        method: String = "POST",
        requestSize: Int,
        responseSize: Int,
        latency: TimeInterval,
        success: Bool
    ) {
        let parameters: [String: Any] = [
            "request_id": requestId,
            "endpoint": endpoint,
            "method": method,
            "request_size": requestSize,
            "response_size": responseSize,
            "latency_ms": Int(latency * 1000),
            "success": success
        ]
        
        Analytics.logEvent("network_performance", parameters: parameters)
    }
}