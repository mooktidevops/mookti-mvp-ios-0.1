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
    /// Attempt to decode `content` as `CardCarouselPayload`.
    /// The CSV stores carousel data in a loose JavaScript-style object notation
    /// without quotes around keys or string values. This parser walks the string
    /// and extracts the pieces we care about without needing valid JSON.
    func asCarouselPayload() -> CardCarouselPayload? {
        guard type == .cardCarousel else { return nil }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{"), trimmed.hasSuffix("}") else {
            print("⚠️ Carousel content not wrapped in braces: \(content)")
            return nil
        }

        var heading: String?
        var cards: [CardCarouselPayload.Card] = []

        let inner = String(trimmed.dropFirst().dropLast())
        let scanner = Scanner(string: inner)
        scanner.charactersToBeSkipped = .whitespacesAndNewlines

        while !scanner.isAtEnd {
            if scanner.scanString("heading:") != nil {
                let value = scanner.scanUpToString(",")
                heading = value?.trimmingCharacters(in: .whitespacesAndNewlines)
                _ = scanner.scanString(",")
            } else if scanner.scanString("cards:") != nil {
                _ = scanner.scanString("[")
                while scanner.scanString("]") == nil {
                    _ = scanner.scanString("{")
                    _ = scanner.scanString("title:")
                    let titleValue = scanner.scanUpToString(", content:") ?? ""
                    _ = scanner.scanString(", content:")
                    let contentValue = scanner.scanUpToString("}") ?? ""
                    _ = scanner.scanString("}")
                    cards.append(
                        .init(
                            title: titleValue.trimmingCharacters(in: .whitespacesAndNewlines),
                            content: contentValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    )
                    _ = scanner.scanString(",")
                }
            } else {
                scanner.currentIndex = scanner.string.index(after: scanner.currentIndex)
            }
        }

        if cards.isEmpty {
            print("⚠️ Failed to parse carousel content for node \(id), showing raw content")
        } else {
            print("✅ Parsed carousel with \(cards.count) cards for node \(id)")
        }

        return CardCarouselPayload(heading: heading, cards: cards)
    }
}

