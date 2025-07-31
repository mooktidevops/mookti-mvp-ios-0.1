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
    /// Handles single‑quoted JSON from CSV by converting to double quotes.
    func asCarouselPayload() -> CardCarouselPayload? {
        guard type == .cardCarousel else { return nil }

        // More robust JSON fixing to handle various formatting issues
        // First, handle markdown formatting before quote replacement
        let markdownProcessed = content
            // Handle bold markdown **text**
            .replacingOccurrences(of: #"\*\*([^*]+)\*\*"#,
                                  with: "<b>$1</b>",
                                  options: .regularExpression)
            // Handle italic markdown *text*
            .replacingOccurrences(of: #"(?<!\*)\*([^*]+)\*(?!\*)"#,
                                  with: "<i>$1</i>",
                                  options: .regularExpression)
        
        // Then fix JSON formatting
        let fixedJSON = markdownProcessed
            // Replace single quotes with double quotes, but not within already quoted strings
            .replacingOccurrences(of: #"(?<![\\'])'(?![\\'])"#,
                                  with: "\"",
                                  options: .regularExpression)
            // Replace unquoted keys with quoted keys (handles 'heading:', 'cards:', etc.)
            .replacingOccurrences(of: #"(\{|,)\s*(\w+):"#,
                                  with: "$1\"$2\":",
                                  options: .regularExpression)
            // Handle null values
            .replacingOccurrences(of: ": null", with: ": null")

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
