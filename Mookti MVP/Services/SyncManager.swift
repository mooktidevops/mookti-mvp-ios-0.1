//
//  SyncManager.swift
//  Mookti MVP
//
//  Coordinates synchronization between client and server
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SyncManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncTime: Date?
    @Published private(set) var syncStatus: SyncStatus = .idle
    @Published private(set) var pendingChanges = 0
    
    // MARK: - Dependencies
    
    private let cacheManager: CacheManager
    private let offlineQueue: OfflineQueue
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    
    // MARK: - Types
    
    enum SyncStatus {
        case idle
        case syncing(progress: Double)
        case success
        case failure(error: String)
        case offline
        
        var description: String {
            switch self {
            case .idle: return "Ready"
            case .syncing(let progress): return "Syncing... \(Int(progress * 100))%"
            case .success: return "Synced"
            case .failure(let error): return "Sync failed: \(error)"
            case .offline: return "Offline"
            }
        }
        
        var color: Color {
            switch self {
            case .idle: return .gray
            case .syncing: return .blue
            case .success: return .green
            case .failure: return .red
            case .offline: return .orange
            }
        }
    }
    
    struct SyncResult {
        let messagesProcessed: Int
        let progressSynced: Bool
        let contentUpdated: Bool
        let errors: [String]
        
        var isSuccess: Bool {
            errors.isEmpty
        }
    }
    
    // MARK: - Local Progress Tracking
    
    private struct LocalProgress: Codable {
        var pathId: String?
        var currentNode: String?
        var completedNodes: Set<String>
        var lastModified: Date
        var sessionId: String
        
        init() {
            self.completedNodes = []
            self.lastModified = Date()
            self.sessionId = UUID().uuidString
        }
    }
    
    private var localProgress = LocalProgress()
    
    // MARK: - Initialization
    
    init(cacheManager: CacheManager, offlineQueue: OfflineQueue, networkMonitor: NetworkMonitor) {
        self.cacheManager = cacheManager
        self.offlineQueue = offlineQueue
        self.networkMonitor = networkMonitor
        
        setupObservers()
        loadLocalProgress()
        setupAutoSync()
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Perform a full sync
    func sync() async -> SyncResult {
        guard !isSyncing else {
            return SyncResult(
                messagesProcessed: 0,
                progressSynced: false,
                contentUpdated: false,
                errors: ["Sync already in progress"]
            )
        }
        
        guard networkMonitor.isConnected else {
            syncStatus = .offline
            return SyncResult(
                messagesProcessed: 0,
                progressSynced: false,
                contentUpdated: false,
                errors: ["No network connection"]
            )
        }
        
        print("🔄 SyncManager: Starting sync")
        isSyncing = true
        syncStatus = .syncing(progress: 0.0)
        
        var errors: [String] = []
        var messagesProcessed = 0
        var progressSynced = false
        var contentUpdated = false
        
        // Step 1: Process offline message queue (33%)
        syncStatus = .syncing(progress: 0.1)
        let queueResult = await offlineQueue.processQueue()
        
        switch queueResult {
        case .success:
            messagesProcessed = offlineQueue.getQueueStats().queued
        case .partialSuccess(let processed, let failed):
            messagesProcessed = processed
            errors.append("\(failed) messages failed to send")
        case .failure(let error):
            errors.append("Queue processing failed: \(error)")
        }
        
        // Step 2: Sync progress (66%)
        syncStatus = .syncing(progress: 0.4)
        if let pathId = localProgress.pathId {
            do {
                progressSynced = try await syncProgress(pathId: pathId)
            } catch {
                errors.append("Progress sync failed: \(error.localizedDescription)")
            }
        }
        
        // Step 3: Update cached content (100%)
        syncStatus = .syncing(progress: 0.7)
        if let currentNode = localProgress.currentNode,
           let pathId = localProgress.pathId {
            await cacheManager.prefetchContext(
                around: currentNode,
                radius: 3,
                pathId: pathId
            )
            contentUpdated = true
        }
        
        // Complete
        isSyncing = false
        lastSyncTime = Date()
        pendingChanges = 0
        
        if errors.isEmpty {
            syncStatus = .success
        } else {
            syncStatus = .failure(error: errors.first ?? "Unknown error")
        }
        
        return SyncResult(
            messagesProcessed: messagesProcessed,
            progressSynced: progressSynced,
            contentUpdated: contentUpdated,
            errors: errors
        )
    }
    
    /// Update local progress
    func updateProgress(pathId: String?, currentNode: String?, completedNode: String? = nil) {
        localProgress.pathId = pathId
        localProgress.currentNode = currentNode
        
        if let completedNode = completedNode {
            localProgress.completedNodes.insert(completedNode)
        }
        
        localProgress.lastModified = Date()
        pendingChanges += 1
        
        saveLocalProgress()
        
        // Trigger sync if online and auto-sync is enabled
        if networkMonitor.isConnected {
            Task {
                await syncProgressDebounced()
            }
        }
    }
    
    /// Get sync statistics
    func getSyncStats() -> (pending: Int, lastSync: Date?, status: SyncStatus) {
        return (pendingChanges, lastSyncTime, syncStatus)
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Monitor network changes
        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                guard let self = self else { return }
                
                if isConnected && self.pendingChanges > 0 {
                    // Network restored, sync pending changes
                    Task {
                        _ = await self.sync()
                    }
                } else if !isConnected {
                    self.syncStatus = .offline
                }
            }
            .store(in: &cancellables)
        
        // Monitor offline queue
        offlineQueue.$queuedMessages
            .map { $0.count }
            .sink { [weak self] count in
                self?.pendingChanges = max(count, self?.pendingChanges ?? 0)
            }
            .store(in: &cancellables)
    }
    
    private func setupAutoSync() {
        // Setup periodic sync based on network quality
        syncTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task { @MainActor in
                let settings = self.networkMonitor.getRecommendedSettings()
                
                switch settings.syncFrequency {
                case .frequent:
                    _ = await self.sync()
                case .occasional:
                    if self.pendingChanges > 5 {
                        _ = await self.sync()
                    }
                case .manual, .never:
                    break // Don't auto-sync
                }
            }
        }
    }
    
    private func syncProgress(pathId: String) async throws -> Bool {
        guard let currentNode = localProgress.currentNode else { return false }
        
        // Prepare sync request
        let syncData = [
            "path_id": pathId,
            "current_node": currentNode,
            "completed_nodes": Array(localProgress.completedNodes),
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "session_id": localProgress.sessionId
        ] as [String: Any]
        
        // In production, call the actual progress API
        // For now, simulate the call
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        print("✅ SyncManager: Progress synced for path \(pathId)")
        return true
    }
    
    private var syncDebouncer: Task<Void, Never>?
    
    private func syncProgressDebounced() async {
        syncDebouncer?.cancel()
        
        syncDebouncer = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
            
            if !Task.isCancelled {
                _ = await sync()
            }
        }
    }
    
    private func loadLocalProgress() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask).first!
        let progressFile = documentsPath.appendingPathComponent("local_progress.json")
        
        if let data = try? Data(contentsOf: progressFile),
           let progress = try? JSONDecoder().decode(LocalProgress.self, from: data) {
            localProgress = progress
            print("📊 SyncManager: Loaded local progress")
        }
    }
    
    private func saveLocalProgress() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask).first!
        let progressFile = documentsPath.appendingPathComponent("local_progress.json")
        
        if let data = try? JSONEncoder().encode(localProgress) {
            try? data.write(to: progressFile)
        }
    }
}