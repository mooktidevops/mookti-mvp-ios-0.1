//
//  OfflineQueue.swift
//  Mookti MVP
//
//  Manages messages sent while offline for later synchronization
//

import Foundation
import SwiftUI

@MainActor
final class OfflineQueue: ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var queuedMessages: [QueuedMessage] = []
    @Published private(set) var isProcessing = false
    @Published private(set) var lastSyncAttempt: Date?
    @Published private(set) var failedMessages: [QueuedMessage] = []
    
    private let queueFile: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var retryTimer: Timer?
    
    // MARK: - Types
    
    struct QueuedMessage: Codable, Identifiable {
        let id: String
        let content: String
        let timestamp: Date
        let nodeContext: String?
        let localOrder: Int
        var retryCount: Int = 0
        var lastError: String?
        
        init(content: String, nodeContext: String?) {
            self.id = UUID().uuidString
            self.content = content
            self.timestamp = Date()
            self.nodeContext = nodeContext
            self.localOrder = Int(Date().timeIntervalSince1970 * 1000)
            self.retryCount = 0
            self.lastError = nil
        }
    }
    
    enum ProcessingResult {
        case success
        case partialSuccess(processed: Int, failed: Int)
        case failure(error: String)
    }
    
    // MARK: - Initialization
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                     in: .userDomainMask).first!
        self.queueFile = documentsPath.appendingPathComponent("offline_queue.json")
        
        loadQueue()
        setupRetryTimer()
    }
    
    deinit {
        retryTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Add a message to the offline queue
    func enqueue(_ message: String, nodeContext: String? = nil) {
        let queuedMessage = QueuedMessage(content: message, nodeContext: nodeContext)
        queuedMessages.append(queuedMessage)
        saveQueue()
        
        print("📥 OfflineQueue: Enqueued message. Queue size: \(queuedMessages.count)")
    }
    
    /// Process all queued messages
    func processQueue() async -> ProcessingResult {
        guard !queuedMessages.isEmpty else {
            return .success
        }
        
        guard !isProcessing else {
            print("⚠️ OfflineQueue: Already processing")
            return .failure(error: "Queue is already being processed")
        }
        
        print("🔄 OfflineQueue: Processing \(queuedMessages.count) queued messages")
        isProcessing = true
        lastSyncAttempt = Date()
        
        var processed = 0
        var failed = 0
        var messagesToRetry: [QueuedMessage] = []
        
        for var message in queuedMessages {
            do {
                // Attempt to send the message
                let success = await sendMessage(message)
                
                if success {
                    processed += 1
                    print("✅ OfflineQueue: Processed message \(message.id)")
                } else {
                    message.retryCount += 1
                    
                    if message.retryCount < 3 {
                        messagesToRetry.append(message)
                        print("🔄 OfflineQueue: Will retry message \(message.id) (attempt \(message.retryCount))")
                    } else {
                        message.lastError = "Max retries exceeded"
                        failedMessages.append(message)
                        failed += 1
                        print("❌ OfflineQueue: Message \(message.id) failed after max retries")
                    }
                }
            } catch {
                message.retryCount += 1
                message.lastError = error.localizedDescription
                
                if message.retryCount < 3 {
                    messagesToRetry.append(message)
                } else {
                    failedMessages.append(message)
                    failed += 1
                }
            }
        }
        
        // Update queue with messages that need retry
        queuedMessages = messagesToRetry
        saveQueue()
        
        isProcessing = false
        
        if failed > 0 {
            return .partialSuccess(processed: processed, failed: failed)
        } else if messagesToRetry.isEmpty {
            return .success
        } else {
            return .failure(error: "\(messagesToRetry.count) messages pending retry")
        }
    }
    
    /// Clear successfully processed messages
    func clearProcessed() {
        // Already handled in processQueue by updating the queue
        saveQueue()
    }
    
    /// Clear failed messages
    func clearFailed() {
        failedMessages.removeAll()
        print("🗑️ OfflineQueue: Cleared failed messages")
    }
    
    /// Retry failed messages
    func retryFailed() async {
        let messagesToRetry = failedMessages
        failedMessages.removeAll()
        
        for var message in messagesToRetry {
            message.retryCount = 0  // Reset retry count
            message.lastError = nil
            queuedMessages.append(message)
        }
        
        if !messagesToRetry.isEmpty {
            saveQueue()
            _ = await processQueue()
        }
    }
    
    /// Get queue statistics
    func getQueueStats() -> (queued: Int, failed: Int, lastSync: Date?) {
        return (queuedMessages.count, failedMessages.count, lastSyncAttempt)
    }
    
    // MARK: - Private Methods
    
    private func loadQueue() {
        guard FileManager.default.fileExists(atPath: queueFile.path) else {
            print("📥 OfflineQueue: No existing queue found")
            return
        }
        
        do {
            let data = try Data(contentsOf: queueFile)
            queuedMessages = try decoder.decode([QueuedMessage].self, from: data)
            print("📥 OfflineQueue: Loaded \(queuedMessages.count) queued messages")
        } catch {
            print("❌ OfflineQueue: Failed to load queue: \(error)")
            queuedMessages = []
        }
    }
    
    private func saveQueue() {
        do {
            let data = try encoder.encode(queuedMessages)
            try data.write(to: queueFile)
            print("💾 OfflineQueue: Saved queue with \(queuedMessages.count) messages")
        } catch {
            print("❌ OfflineQueue: Failed to save queue: \(error)")
        }
    }
    
    private func sendMessage(_ message: QueuedMessage) async -> Bool {
        // In production, this would call the actual API
        // For now, simulate with CloudAIService
        
        do {
            // Check if we have network connectivity
            // This would use NetworkMonitor in production
            
            // Simulate API call
            let response = try await CloudAIService.answer(
                for: message.content,
                systemPrompt: nil,
                currentNodeId: message.nodeContext,
                moduleProgress: nil
            )
            
            return true
        } catch {
            print("❌ OfflineQueue: Failed to send message: \(error)")
            return false
        }
    }
    
    private func setupRetryTimer() {
        // Retry failed messages every 30 seconds when online
        retryTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                // Only retry if we have network and queued messages
                if !self.queuedMessages.isEmpty && !self.isProcessing {
                    print("⏰ OfflineQueue: Timer-triggered retry")
                    _ = await self.processQueue()
                }
            }
        }
    }
}