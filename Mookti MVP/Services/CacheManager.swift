//
//  CacheManager.swift
//  Mookti MVP
//
//  Manages local caching of learning path content for offline access
//

import Foundation
import SwiftUI

@MainActor
final class CacheManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var cachedNodes: [String: LearningNode] = [:]
    @Published private(set) var cacheSize: Int = 0
    @Published private(set) var lastCacheUpdate: Date?
    
    private let maxCacheSize = 50 * 1024 * 1024 // 50MB
    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Cache metadata
    private struct CacheMetadata: Codable {
        let version: String
        let lastUpdated: Date
        let nodeCount: Int
        let pathId: String?
    }
    
    // MARK: - Initialization
    
    init() {
        // Setup cache directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                     in: .userDomainMask).first!
        self.cacheDirectory = documentsPath.appendingPathComponent("LearningPathCache")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: cacheDirectory, 
                                                withIntermediateDirectories: true, 
                                                attributes: nil)
        
        // Load existing cache
        loadCache()
    }
    
    // MARK: - Public Methods
    
    /// Cache multiple nodes at once
    func cacheNodes(_ nodes: [String: LearningNode], for pathId: String) {
        print("📦 CacheManager: Caching \(nodes.count) nodes for path: \(pathId)")
        
        // Merge with existing cache
        for (id, node) in nodes {
            cachedNodes[id] = node
        }
        
        // Save to disk
        saveCache(pathId: pathId)
        
        // Update cache size
        updateCacheSize()
        
        // Evict if necessary
        if cacheSize > maxCacheSize {
            evictLRUNodes()
        }
    }
    
    /// Get a cached node by ID
    func getCachedNode(_ id: String) -> LearningNode? {
        return cachedNodes[id]
    }
    
    /// Check if a node is cached
    func isNodeCached(_ id: String) -> Bool {
        return cachedNodes[id] != nil
    }
    
    /// Get all cached nodes within a radius of a given node
    func getNodesInRadius(center: String, radius: Int) -> [String: LearningNode] {
        guard let centerNode = cachedNodes[center] else { return [:] }
        
        var result: [String: LearningNode] = [center: centerNode]
        var visited = Set<String>([center])
        var queue: [(id: String, depth: Int)] = [(center, 0)]
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            
            if current.depth >= radius {
                continue
            }
            
            if let node = cachedNodes[current.id] {
                for nextId in node.nextChunkIDs {
                    if !visited.contains(nextId) {
                        visited.insert(nextId)
                        if let nextNode = cachedNodes[nextId] {
                            result[nextId] = nextNode
                            queue.append((nextId, current.depth + 1))
                        }
                    }
                }
            }
        }
        
        return result
    }
    
    /// Prefetch nodes around a given node ID
    func prefetchContext(around nodeId: String, radius: Int = 3, pathId: String) async {
        // Check if we already have the nodes cached
        let cachedContext = getNodesInRadius(center: nodeId, radius: radius)
        if cachedContext.count > radius * 2 {
            print("✅ CacheManager: Context already cached for node \(nodeId)")
            return
        }
        
        // Fetch from server
        print("🌐 CacheManager: Fetching context for node \(nodeId) with radius \(radius)")
        
        // This would call the learning-paths API
        // For now, we'll simulate it
        await fetchAndCacheContext(nodeId: nodeId, radius: radius, pathId: pathId)
    }
    
    /// Clear all cached content
    func clearCache() {
        cachedNodes.removeAll()
        
        // Remove files
        if let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, 
                                                                    includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }
        
        cacheSize = 0
        lastCacheUpdate = nil
        
        print("🗑️ CacheManager: Cache cleared")
    }
    
    /// Get cache statistics
    func getCacheStats() -> (nodeCount: Int, sizeInBytes: Int, lastUpdated: Date?) {
        return (cachedNodes.count, cacheSize, lastCacheUpdate)
    }
    
    // MARK: - Private Methods
    
    private func loadCache() {
        let metadataURL = cacheDirectory.appendingPathComponent("metadata.json")
        let nodesURL = cacheDirectory.appendingPathComponent("nodes.json")
        
        guard FileManager.default.fileExists(atPath: metadataURL.path),
              FileManager.default.fileExists(atPath: nodesURL.path) else {
            print("📦 CacheManager: No existing cache found")
            return
        }
        
        do {
            let metadataData = try Data(contentsOf: metadataURL)
            let metadata = try decoder.decode(CacheMetadata.self, from: metadataData)
            
            let nodesData = try Data(contentsOf: nodesURL)
            cachedNodes = try decoder.decode([String: LearningNode].self, from: nodesData)
            
            lastCacheUpdate = metadata.lastUpdated
            updateCacheSize()
            
            print("📦 CacheManager: Loaded \(cachedNodes.count) cached nodes")
        } catch {
            print("❌ CacheManager: Failed to load cache: \(error)")
            clearCache()
        }
    }
    
    private func saveCache(pathId: String) {
        let metadataURL = cacheDirectory.appendingPathComponent("metadata.json")
        let nodesURL = cacheDirectory.appendingPathComponent("nodes.json")
        
        do {
            let metadata = CacheMetadata(
                version: "1.0.0",
                lastUpdated: Date(),
                nodeCount: cachedNodes.count,
                pathId: pathId
            )
            
            let metadataData = try encoder.encode(metadata)
            try metadataData.write(to: metadataURL)
            
            let nodesData = try encoder.encode(cachedNodes)
            try nodesData.write(to: nodesURL)
            
            lastCacheUpdate = Date()
            
            print("💾 CacheManager: Saved \(cachedNodes.count) nodes to cache")
        } catch {
            print("❌ CacheManager: Failed to save cache: \(error)")
        }
    }
    
    private func updateCacheSize() {
        let metadataURL = cacheDirectory.appendingPathComponent("metadata.json")
        let nodesURL = cacheDirectory.appendingPathComponent("nodes.json")
        
        var totalSize = 0
        
        if let metadataAttrs = try? FileManager.default.attributesOfItem(atPath: metadataURL.path),
           let metadataSize = metadataAttrs[.size] as? Int {
            totalSize += metadataSize
        }
        
        if let nodesAttrs = try? FileManager.default.attributesOfItem(atPath: nodesURL.path),
           let nodesSize = nodesAttrs[.size] as? Int {
            totalSize += nodesSize
        }
        
        cacheSize = totalSize
    }
    
    private func evictLRUNodes() {
        // Simple eviction: remove half of the cached nodes
        // In production, would track access times for true LRU
        let nodesToKeep = cachedNodes.count / 2
        let sortedKeys = Array(cachedNodes.keys).sorted()
        let keysToKeep = Set(sortedKeys.prefix(nodesToKeep))
        
        cachedNodes = cachedNodes.filter { keysToKeep.contains($0.key) }
        
        print("🗑️ CacheManager: Evicted nodes to stay under size limit. Remaining: \(cachedNodes.count)")
        
        // Save updated cache
        if let pathId = cachedNodes.first?.value.id.components(separatedBy: "_").first {
            saveCache(pathId: pathId)
        }
        updateCacheSize()
    }
    
    private func fetchAndCacheContext(nodeId: String, radius: Int, pathId: String) async {
        // In production, this would call the actual API
        // For now, we'll simulate by creating placeholder nodes
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Create sample nodes around the requested node
        var newNodes: [String: LearningNode] = [:]
        
        // This is where you'd make the actual API call:
        // let response = await LearningPathAPI.fetchContext(nodeId: nodeId, radius: radius)
        // cacheNodes(response.nodes, for: pathId)
        
        print("✅ CacheManager: Fetched and cached context for node \(nodeId)")
    }
}