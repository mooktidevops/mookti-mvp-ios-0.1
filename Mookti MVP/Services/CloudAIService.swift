//
//  CloudAIService.swift
//  Mookti
//
// Cloud-only implementation that routes all requests through Vercel Edge Functions
//

import Foundation
import OSLog

struct CloudAIService {
    private static let logger = Logger(subsystem: "com.mookti.mvp", category: "CloudAI")
    
    // API Configuration - Always use Vercel endpoint
    private static let vercelEndpoint = "https://mookti-edge-api.vercel.app/api/chat"
    private static let model = "claude-3-5-haiku-20241022"
    
    /// Makes a request to Claude API via Vercel and returns the response
    /// - Parameters:
    ///   - prompt: The user prompt to send
    ///   - systemPrompt: Optional system prompt (Ellen's personality)
    ///   - currentNodeId: Current learning path node ID
    ///   - moduleProgress: Progress information for the current module
    static func answer(for prompt: String, systemPrompt: String? = nil, currentNodeId: String? = nil, moduleProgress: ModuleProgress? = nil) async throws -> String {
        let startTime = Date()
        let requestId = UUID().uuidString
        
        logger.info("☁️ CloudAIService: Starting request [\(requestId)]")
        logger.info("📊 Request details - Prompt length: \(prompt.count), System prompt: \(systemPrompt != nil ? "Yes (\(systemPrompt!.count) chars)" : "None")")
        logger.info("🌐 CloudAIService: Using Vercel endpoint")
        
        // Log request details to Firebase
        FirebaseLogger.shared.logAIRequest(
            requestId: requestId,
            service: "CloudAI",
            endpoint: vercelEndpoint,
            model: model,
            promptLength: prompt.count,
            systemPromptLength: systemPrompt?.count,
            temperature: 0.6,
            maxTokens: 2048
        )
        
        return try await callVercelEndpoint(
            prompt: prompt,
            systemPrompt: systemPrompt,
            currentNodeId: currentNodeId,
            moduleProgress: moduleProgress,
            requestId: requestId,
            startTime: startTime
        )
    }
    
    /// Call Vercel Edge Function endpoint with RAG (Retrieval Augmented Generation)
    /// The endpoint searches Pinecone for relevant educational content before calling Claude
    private static func callVercelEndpoint(prompt: String, systemPrompt: String?, currentNodeId: String?, moduleProgress: ModuleProgress?, requestId: String, startTime: Date) async throws -> String {
        logger.info("☁️ CloudAIService: Using Vercel endpoint with RAG for request [\(requestId)]")
        print("🔵 Vercel Endpoint Called:")
        print("🔵 URL: \(vercelEndpoint)")
        print("🔵 Request ID: \(requestId)")
        
        // Get Firebase Auth token
        guard let token = try? await FirebaseAuthService.shared.getIDToken() else {
            logger.error("❌ CloudAIService: Failed to get Firebase Auth token")
            print("🔴 Firebase Auth Failed - No token available")
            throw CloudAIError.authenticationRequired
        }
        
        print("🟢 Firebase Auth Token obtained successfully")
        
        // Parse the prompt to extract chat history if available
        var chatHistory: [ChatHistoryItem] = []
        var userMessage = prompt
        
        if prompt.contains("Chat Context:") && prompt.contains("\n\nUser:") {
            // Extract chat context section
            if let chatStart = prompt.range(of: "Chat Context:\n"),
               let userStart = prompt.range(of: "\n\nUser:") {
                let chatSection = prompt[chatStart.upperBound..<userStart.lowerBound]
                
                // Parse chat messages
                let lines = chatSection.split(separator: "\n\n")
                for line in lines {
                    if let colonRange = line.range(of: ": ") {
                        let role = String(line[..<colonRange.lowerBound]).lowercased()
                        let content = String(line[colonRange.upperBound...])
                        if role == "user" || role == "ellen" {
                            chatHistory.append(ChatHistoryItem(
                                role: role == "ellen" ? "assistant" : role,
                                content: content
                            ))
                        }
                    }
                }
                
                // Extract actual user message
                userMessage = String(prompt[userStart.upperBound...].trimmingCharacters(in: .whitespaces))
            }
        }
        
        // Prepare request body for Vercel endpoint with RAG enabled
        let requestBody = VercelClaudeRequest(
            message: userMessage,
            chatHistory: chatHistory.isEmpty ? nil : chatHistory,
            useRAG: true,  // Always enable RAG for educational content
            topK: 3,       // Get top 3 relevant content pieces
            currentNodeId: currentNodeId,
            moduleProgress: moduleProgress
        )
        
        guard let url = URL(string: vercelEndpoint) else {
            throw CloudAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)
            
            logger.info("🌐 CloudAIService: Sending request to Vercel endpoint")
            
            let performanceTrace = FirebaseLogger.shared.startTrace(name: "vercel_claude_\(requestId)")
            FirebaseLogger.shared.addMetric(to: performanceTrace, name: "request_size", value: Int64(request.httpBody?.count ?? 0))
            
            let networkStartTime = Date()
            let (data, response) = try await URLSession.shared.data(for: request)
            let networkDuration = Date().timeIntervalSince(networkStartTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CloudAIError.invalidResponse
            }
            
            let responseSize = data.count
            logger.info("📥 CloudAIService: Received Vercel response - Status: \(httpResponse.statusCode), Size: \(responseSize) bytes")
            
            // Log network performance
            FirebaseLogger.shared.logNetworkPerformance(
                requestId: requestId,
                endpoint: vercelEndpoint,
                requestSize: request.httpBody?.count ?? 0,
                responseSize: responseSize,
                latency: networkDuration,
                success: httpResponse.statusCode == 200
            )
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                logger.error("❌ CloudAIService: Vercel API error - Status: \(httpResponse.statusCode), Message: \(errorMessage)")
                
                print("🔴 Vercel API Error Response:")
                print("🔴 Status Code: \(httpResponse.statusCode)")
                print("🔴 Response Body: \(errorMessage)")
                
                performanceTrace?.stop()
                
                // Parse Vercel error response
                if let errorData = try? JSONDecoder().decode(VercelErrorResponse.self, from: data) {
                    print("🔴 Parsed Error Code: \(errorData.code)")
                    print("🔴 Parsed Error Message: \(errorData.error)")
                    
                    if errorData.code == "AUTH_INVALID" || errorData.code == "AUTH_TOKEN_EXPIRED" {
                        throw CloudAIError.authenticationRequired
                    }
                    throw CloudAIError.apiError(statusCode: httpResponse.statusCode, message: errorData.error)
                }
                
                throw CloudAIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            
            // Decode Vercel response
            print("🟢 Vercel Success Response:")
            print("🟢 Status Code: \(httpResponse.statusCode)")
            print("🟢 Response Size: \(data.count) bytes")
            
            let vercelResponse = try JSONDecoder().decode(VercelClaudeResponse.self, from: data)
            
            let duration = Date().timeIntervalSince(startTime)
            
            // Log response details
            FirebaseLogger.shared.logAIResponse(
                requestId: requestId,
                statusCode: 200,
                responseLength: vercelResponse.content.count,
                tokenCount: vercelResponse.usage.outputTokens,
                duration: duration
            )
            
            // Log comprehensive interaction
            await AIInteractionLogger.shared.logEllenInteraction(
                prompt: prompt,
                response: vercelResponse.content,
                isOnDevice: false,
                generationDuration: duration,
                modelAvailability: vercelResponse.model
            )
            
            // Stop performance trace
            FirebaseLogger.shared.addMetric(to: performanceTrace, name: "response_size", value: Int64(data.count))
            FirebaseLogger.shared.addMetric(to: performanceTrace, name: "output_tokens", value: Int64(vercelResponse.usage.outputTokens))
            performanceTrace?.stop()
            
            // Handle tool calls if present
            if let toolCalls = vercelResponse.toolCalls, !toolCalls.isEmpty {
                logger.info("🔧 CloudAIService: Processing \(toolCalls.count) tool calls")
                
                // Process tool calls and append instructions to response
                var responseWithTools = vercelResponse.content
                
                for toolCall in toolCalls {
                    switch toolCall.tool {
                    case "return_to_path":
                        if let transitionMsg = toolCall.input.transitionMessage {
                            // Append transition message to guide back to path
                            responseWithTools += "\n\n\(transitionMsg)"
                            
                            // Log the transition type for client handling
                            logger.info("🔄 Return to path: \(toolCall.input.transitionType ?? "unknown")")
                        }
                        
                    case "suggest_comprehension_check":
                        if let preface = toolCall.input.preface,
                           let question = toolCall.input.question {
                            responseWithTools += "\n\n\(preface)\n\n\(question)"
                        }
                        
                    case "explain_differently":
                        if let explanation = toolCall.input.explanation {
                            responseWithTools += "\n\n\(explanation)"
                        }
                        
                    case "search_deeper":
                        // This would trigger additional search - log for now
                        logger.info("🔍 Additional search requested: \(toolCall.input.query ?? "")")
                        
                    default:
                        logger.warning("⚠️ Unknown tool called: \(toolCall.tool)")
                    }
                }
                
                logger.info("✅ CloudAIService: Successfully returned response with tools, length: \(responseWithTools.count), duration: \(String(format: "%.3f", duration))s")
                return responseWithTools
            }
            
            logger.info("✅ CloudAIService: Successfully returned Vercel response, length: \(vercelResponse.content.count), duration: \(String(format: "%.3f", duration))s")
            return vercelResponse.content
            
        } catch let error as CloudAIError {
            print("🔴 CloudAI Specific Error: \(error)")
            print("🔴 Error Details: \(error.localizedDescription)")
            throw error
        } catch {
            print("🔴 CloudAI Vercel Error: \(error)")
            print("🔴 Error Type: \(type(of: error))")
            print("🔴 Error Details: \(error.localizedDescription)")
            
            logger.error("❌ CloudAIService: Vercel endpoint error - \(error.localizedDescription)")
            throw CloudAIError.networkError(error.localizedDescription)
        }
    }
}

// MARK: - Request/Response Models

private struct ChatHistoryItem: Codable {
    let role: String
    let content: String
}

private struct VercelClaudeRequest: Codable {
    let message: String
    let chatHistory: [ChatHistoryItem]?
    let useRAG: Bool
    let topK: Int?
    let currentNodeId: String?
    let moduleProgress: ModuleProgress?
}

private struct ModuleProgress: Codable {
    let currentModule: String
    let nodesCompleted: Int
    let totalNodes: Int
}

private struct VercelClaudeResponse: Codable {
    let content: String
    let model: String
    let usage: VercelUsage
    let ragUsed: Bool?
    let toolCalls: [ToolCall]?
}

private struct ToolCall: Codable {
    let id: String
    let tool: String
    let input: ToolInput
}

private struct ToolInput: Codable {
    // Return to path fields
    let transitionType: String?
    let transitionMessage: String?
    let conceptualBridge: String?
    
    // Search fields
    let query: String?
    let searchScope: String?
    let reason: String?
    
    // Comprehension check fields (user-requested only)
    let concept: String?
    let checkType: String?
    let question: String?
    let preface: String?
    
    // Alternative explanation fields
    let approach: String?
    let explanation: String?
    
    enum CodingKeys: String, CodingKey {
        case transitionType = "transition_type"
        case transitionMessage = "transition_message"
        case conceptualBridge = "conceptual_bridge"
        case query
        case searchScope = "search_scope"
        case reason
        case concept
        case checkType = "check_type"
        case question
        case preface
        case approach
        case explanation
    }
}

private struct VercelUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

private struct VercelErrorResponse: Codable {
    let error: String
    let code: String
    let details: String?
}

// MARK: - Errors

enum CloudAIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case encodingError(String)
    case apiError(statusCode: Int, message: String)
    case networkError(String)
    case rateLimited
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Cloud service configuration error. Please contact support."
        case .invalidURL:
            return "Invalid service URL"
        case .invalidResponse:
            return "Invalid response from service"
        case .encodingError(let message):
            return "Failed to encode request: \(message)"
        case .apiError(let code, let message):
            return "Service Error (\(code)): \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .rateLimited:
            return "API rate limit exceeded. Please try again later."
        case .authenticationRequired:
            return "Authentication required. Please sign in to continue."
        }
    }
}