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
    /// Now expects proper JSON format from the CSV.
    func asCarouselPayload() -> CardCarouselPayload? {
        guard type == .cardCarousel else { return nil }

        do {
            let decoder = JSONDecoder()
            let payload = try decoder.decode(CardCarouselPayload.self,
                                           from: Data(content.utf8))
            print("✅ Successfully parsed carousel with \(payload.cards.count) cards")
            return payload
        } catch {
            print("❌ Failed to decode CardCarouselPayload: \(error)")
            print("Content: \(content)")
            
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
