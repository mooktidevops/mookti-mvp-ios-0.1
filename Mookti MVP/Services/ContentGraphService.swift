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

    /// Convenience accessor for a node by ID.
    func node(for id: String) -> LearningNode? { nodes[id] }

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
        // Define all modules to load in order
        let modules = [
            "workplace_success_lp_intro_module",
            "cq_intro_module",
            "cq_power_hierarchy_relationships",
            "cq_dealing_with_unknowns",
            "cq_consensus_building",
            "cq_being_in_sync"
        ]
        
        var allNodes: [String: LearningNode] = [:]
        
        for moduleName in modules {
            print("📚 Loading module: \(moduleName)")
            let moduleNodes = await loadCSV(named: moduleName, from: bundle)
            
            // Merge nodes, checking for ID conflicts
            for (id, node) in moduleNodes {
                if allNodes[id] != nil {
                    print("⚠️ Warning: Duplicate node ID \(id) found in \(moduleName)")
                }
                allNodes[id] = node
            }
            
            if !moduleNodes.isEmpty {
                loadedModules.append(moduleName)
                print("✅ Loaded \(moduleNodes.count) nodes from \(moduleName)")
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
