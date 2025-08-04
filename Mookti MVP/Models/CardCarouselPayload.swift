import Foundation

struct CardCarouselPayload: Codable, Hashable, Equatable {
    var heading: String?
    var cards: [Card]

    struct Card: Codable, Identifiable, Hashable, Equatable {
        var id: UUID
        var title: String
        var content: String
        
        init(title: String, content: String) {
            self.id = UUID()
            self.title = title
            self.content = content
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.title = try container.decode(String.self, forKey: .title)
            self.content = try container.decode(String.self, forKey: .content)
            self.id = UUID() // Generate ID during decoding
        }
        
        enum CodingKeys: String, CodingKey {
            case title
            case content
        }
    }
}

extension LearningNode {
    /// Attempt to decode `content` as CardCarouselPayload.
    /// Handles JavaScript-style object notation from CSV by converting to proper JSON.
    func asCarouselPayload() -> CardCarouselPayload? {
        guard type == .cardCarousel else { return nil }

        // The content comes in JavaScript object notation like:
        // {heading: 'text', cards: [{title: 'text', content: 'text with apostrophes'}]}
        
        var fixedJSON = content
        
        // Step 1: Fix object keys - add quotes around them
        fixedJSON = fixedJSON
            .replacingOccurrences(of: "heading:", with: "\"heading\":")
            .replacingOccurrences(of: "cards:", with: "\"cards\":")
            .replacingOccurrences(of: "title:", with: "\"title\":")
            .replacingOccurrences(of: "content:", with: "\"content\":")
        
        // Step 2: Replace single-quoted strings with double-quoted strings
        // This is complex because we need to handle apostrophes inside the strings
        // We'll use a more manual approach
        
        var result = ""
        var inString = false
        var stringDelimiter: Character? = nil
        var i = fixedJSON.startIndex
        
        while i < fixedJSON.endIndex {
            let char = fixedJSON[i]
            
            if !inString {
                if char == "'" || char == "\"" {
                    inString = true
                    stringDelimiter = char
                    result.append("\"") // Always use double quotes in output
                } else {
                    result.append(char)
                }
            } else {
                // We're inside a string
                if char == stringDelimiter && (i == fixedJSON.startIndex || fixedJSON[fixedJSON.index(before: i)] != "\\") {
                    // End of string
                    inString = false
                    stringDelimiter = nil
                    result.append("\"") // Always use double quotes in output
                } else if char == "\"" {
                    // Escape double quotes inside strings
                    result.append("\\\"")
                } else if char == "\\" && i < fixedJSON.index(before: fixedJSON.endIndex) && fixedJSON[fixedJSON.index(after: i)] == "'" {
                    // Skip escaped single quotes
                    result.append("'")
                    i = fixedJSON.index(after: i)
                } else {
                    // Keep everything else as-is (including apostrophes)
                    result.append(char)
                }
            }
            
            i = fixedJSON.index(after: i)
        }
        
        fixedJSON = result

        do {
            let decoder = JSONDecoder()
            let payload = try decoder.decode(CardCarouselPayload.self,
                                           from: Data(fixedJSON.utf8))
            print("✅ Successfully parsed carousel with \(payload.cards.count) cards")
            return payload
        } catch {
            print("❌ Failed to decode CardCarouselPayload: \(error)")
            print("Original content: \(content)")
            print("Fixed JSON: \(fixedJSON)")
            
            // Try to provide more specific error information
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    print("Data corrupted at: \(context.codingPath)")
                    print("Debug description: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    print("Key '\(key)' not found at: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch for type \(type) at: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("Value not found for type \(type) at: \(context.codingPath)")
                @unknown default:
                    print("Unknown decoding error")
                }
            }
            
            return nil
        }
    }
}
