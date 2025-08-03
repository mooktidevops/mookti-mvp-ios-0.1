//
//  ContentGraphService.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑06‑30.
//

import Foundation
import Combine

/// Parses all learning path CSV modules into an in‑memory graph the app can traverse.
///
/// The service is `ObservableObject` so you can @Environment it if needed, but
/// most callers will read the `nodes` dictionary synchronously after init.
@MainActor
final class ContentGraphService: ObservableObject {

    // MARK: - Public

    /// All nodes keyed by `sequence_id`.
    @Published private(set) var nodes: [String: LearningNode] = [:]
    
    /// Track which modules are loaded
    @Published private(set) var loadedModules: [String] = []
    
    /// Module metadata for navigation
    struct ModuleInfo {
        let name: String
        let displayName: String
        let prefix: String
        let startNodeId: String
        let endNodeId: String?
        let nextModulePrefix: String?
    }
    
    /// Module configuration
    @Published private(set) var modules: [ModuleInfo] = []

    /// Convenience accessor for a node by ID.
    func node(for id: String) -> LearningNode? { nodes[id] }
    
    /// Get the module info for a given node ID
    func moduleForNode(_ nodeId: String) -> ModuleInfo? {
        // Extract prefix from node ID
        if nodeId.contains("_") {
            let prefix = String(nodeId.split(separator: "_").first ?? "")
            return modules.first { $0.prefix == prefix }
        } else {
            // Unprefixed IDs belong to intro module
            return modules.first { $0.prefix == "intro" }
        }
    }

    // MARK: - Life‑cycle
    
    @Published private(set) var isLoaded = false

    init(bundle: Bundle = .main) {
        Task { 
            await loadAllModules(from: bundle)
            isLoaded = true
        }
    }

    // MARK: - Private CSV logic
    
    /// Load all learning path modules
    private func loadAllModules(from bundle: Bundle) async {
        // Define module configuration with proper transitions
        let moduleConfigs = [
            ModuleInfo(
                name: "workplace_success_lp_intro_module",
                displayName: "Workplace Success Introduction",
                prefix: "intro",
                startNodeId: "1",
                endNodeId: "67",
                nextModulePrefix: "cq1"
            ),
            ModuleInfo(
                name: "cq_intro_module",
                displayName: "Cultural Intelligence Introduction",
                prefix: "cq1",
                startNodeId: "cq1_1",
                endNodeId: "cq1_23",
                nextModulePrefix: "cq2"
            ),
            ModuleInfo(
                name: "cq_power_hierarchy_relationships",
                displayName: "Power, Hierarchy, and Relationships",
                prefix: "cq2",
                startNodeId: "cq2_1",
                endNodeId: "cq2_27",
                nextModulePrefix: "cq3"
            ),
            ModuleInfo(
                name: "cq_dealing_with_unknowns",
                displayName: "Dealing with Unknowns",
                prefix: "cq3",
                startNodeId: "cq3_1",
                endNodeId: "cq3_32",
                nextModulePrefix: "cq4"
            ),
            ModuleInfo(
                name: "cq_consensus_building",
                displayName: "Consensus Building",
                prefix: "cq4",
                startNodeId: "cq4_1",
                endNodeId: "cq4_33",
                nextModulePrefix: "cq5"
            ),
            ModuleInfo(
                name: "cq_being_in_sync",
                displayName: "Being In-Sync: Communication and Time",
                prefix: "cq5",
                startNodeId: "cq5_1",
                endNodeId: "cq5_35",
                nextModulePrefix: nil
            )
        ]
        
        self.modules = moduleConfigs
        var allNodes: [String: LearningNode] = [:]
        
        for (index, moduleInfo) in moduleConfigs.enumerated() {
            print("📚 Loading module: \(moduleInfo.name) with prefix: \(moduleInfo.prefix)")
            let moduleNodes = await loadCSV(named: moduleInfo.name, from: bundle)
            
            // Process nodes with proper prefixing
            for (originalId, var node) in moduleNodes {
                // For intro module, keep original IDs; for others, add prefix
                let prefixedId = (moduleInfo.prefix == "intro") ? originalId : "\(moduleInfo.prefix)_\(originalId)"
                
                // Update the node's ID
                node.id = prefixedId
                
                // Update nextChunkIDs to use prefixed versions
                if moduleInfo.prefix != "intro" && !node.nextChunkIDs.isEmpty {
                    node.nextChunkIDs = node.nextChunkIDs.map { nextId in
                        // Don't prefix if it's already prefixed
                        if nextId.contains("_") {
                            return nextId
                        } else {
                            return "\(moduleInfo.prefix)_\(nextId)"
                        }
                    }
                }
                
                allNodes[prefixedId] = node
            }
            
            // Create transition node at the end of each module (except last)
            if let nextModule = moduleInfo.nextModulePrefix,
               let endNodeId = moduleInfo.endNodeId {
                
                // Find the actual end node ID (prefixed)
                let actualEndId = (moduleInfo.prefix == "intro") ? endNodeId : "\(moduleInfo.prefix)_\(endNodeId.split(separator: "_").last ?? Substring(endNodeId))"
                
                // Update the end node to point to transition
                if var endNode = allNodes[actualEndId] {
                    let transitionId = "\(moduleInfo.prefix)_transition"
                    endNode.nextChunkIDs = [transitionId]
                    endNode.nextAction = "getNextChunk"
                    allNodes[actualEndId] = endNode
                    
                    // Create transition node
                    let nextModuleInfo = moduleConfigs.first { $0.prefix == nextModule }
                    let transitionNode = LearningNode(
                        id: transitionId,
                        type: .system,
                        content: "🎉 Excellent work completing \(moduleInfo.displayName)! Ready to continue to \(nextModuleInfo?.displayName ?? "the next module")?",
                        nextAction: "getNextChunk",
                        nextChunkIDs: [nextModuleInfo?.startNodeId ?? "\(nextModule)_1"]
                    )
                    allNodes[transitionId] = transitionNode
                    print("🌉 Created transition from \(moduleInfo.prefix) to \(nextModule)")
                }
            }
            
            if !moduleNodes.isEmpty {
                loadedModules.append(moduleInfo.name)
                print("✅ Loaded \(moduleNodes.count) nodes from \(moduleInfo.name)")
            }
        }
        
        nodes = allNodes
        print("📊 Total nodes loaded: \(allNodes.count) from \(loadedModules.count) modules")
    }

    /// Asynchronously reads & parses a single CSV file.
    private func loadCSV(named resourceName: String, from bundle: Bundle) async -> [String: LearningNode] {
        guard
            let url = bundle.url(forResource: resourceName, withExtension: "csv"),
            let raw = try? String(contentsOf: url, encoding: .utf8)
        else {
            print("⚠️ Module \(resourceName).csv not found in bundle")
            return [:]
        }

        var result: [String: LearningNode] = [:]

        // Split on newlines, skip header row
        for (index, line) in raw.split(whereSeparator: \.isNewline).enumerated() {
            if index == 0 { continue }              // header

            // Parse respecting quoted commas
            let cols = parseCSVLine(String(line))
            guard cols.count >= 5 else { continue }

            let seqID      = cols[0]
            let typeRaw    = cols[1].trimmingCharacters(in: .whitespaces)
            let content    = cols[2].unquoted
            let nextAction = cols[3].trimmingCharacters(in: .whitespaces)
            let nextIDs    = cols[4]
                .split(separator: "|")
                .map { $0.trimmingCharacters(in: .whitespaces) }

            guard let dtype = LearningNode.DisplayType(rawValue: typeRaw) else { 
                print("⚠️ Unknown display type: '\(typeRaw)' for sequence_id: '\(seqID)'")
                continue 
            }

            result[seqID] = LearningNode(
                id: seqID,
                type: dtype,
                content: content,
                nextAction: nextAction,
                nextChunkIDs: nextIDs
            )
        }

        return result
    }

    /// Minimal, dependency‑free CSV parser for one line.
    ///
    /// Handles commas inside double‑quoted fields per RFC 4180.
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var insideQuotes = false

        for char in line {
            switch char {
            case "\"":
                insideQuotes.toggle()
            case "," where !insideQuotes:
                fields.append(current)
                current = ""
            default:
                current.append(char)
            }
        }
        fields.append(current)   // last field
        return fields
    }
}

// MARK: - Small helpers

private extension String {
    /// Strips optional leading & trailing double quotes.
    var unquoted: String {
        trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
}
