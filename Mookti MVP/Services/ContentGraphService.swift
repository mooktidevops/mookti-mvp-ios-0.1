//
//  ContentGraphService.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑06‑30.
//

import Foundation
import Combine

/// Parses `workplace_success_lp_intro_module.csv` into an in‑memory graph the app can traverse.
///
/// The service is `ObservableObject` so you can @Environment it if needed, but
/// most callers will read the `nodes` dictionary synchronously after init.
@MainActor
final class ContentGraphService: ObservableObject {

    // MARK: - Public

    /// All nodes keyed by `sequence_id`.
    @Published private(set) var nodes: [String: LearningNode] = [:]

    /// Convenience accessor for a node by ID.
    func node(for id: String) -> LearningNode? { nodes[id] }

    // MARK: - Life‑cycle
    
    @Published private(set) var isLoaded = false

    init(bundle: Bundle = .main) {
        Task { 
            await loadCSV(from: bundle)
            isLoaded = true
        }
    }

    // MARK: - Private CSV logic

    /// Asynchronously reads & parses the file.
    private func loadCSV(from bundle: Bundle) async {
        guard
            let url = bundle.url(forResource: "workplace_success_lp_intro_module", withExtension: "csv"),
            let raw = try? String(contentsOf: url, encoding: .utf8)
        else {
            print("🚨 CRITICAL: workplace_success_lp_intro_module.csv missing from bundle")
            // Create minimal fallback content so app doesn't break
            nodes = [
                "1": LearningNode(
                    id: "1", 
                    type: .system, 
                    content: "Content loading failed. Please contact support.", 
                    nextAction: "getNextChunk", 
                    nextChunkIDs: []
                )
            ]
            return
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

        nodes = result          // publish to observers
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
