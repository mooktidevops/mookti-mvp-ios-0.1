import Foundation

// MARK: - SequenceID

/// Represents a hierarchical sequence identifier that can handle values like "1", "1.2", "1.2.4", etc.
struct SequenceID: Equatable, Hashable {
    let components: [Int]
    
    /// Initialize from an array of integers
    init(components: [Int]) {
        self.components = components
    }
    
    /// Initialize from a single integer
    init(_ value: Int) {
        self.components = [value]
    }
    
    /// Initialize from a dotted string like "1.2.4"
    init?(from string: String) {
        let parts = string.split(separator: ".")
        let numbers = parts.compactMap { Int($0) }
        
        // Make sure all parts were valid integers
        guard numbers.count == parts.count && !numbers.isEmpty else {
            return nil
        }
        
        self.components = numbers
    }
    
    /// Convert to string representation
    var stringValue: String {
        components.map(String.init).joined(separator: ".")
    }
    
    /// Get the depth of this sequence (e.g., "1.2.4" has depth 3)
    var depth: Int {
        components.count
    }
    
    /// Check if this sequence is a parent of another
    func isParent(of other: SequenceID) -> Bool {
        guard components.count < other.components.count else { return false }
        return components == Array(other.components.prefix(components.count))
    }
    
    /// Check if this sequence is a child of another
    func isChild(of other: SequenceID) -> Bool {
        other.isParent(of: self)
    }
    
    /// Get the immediate parent (e.g., "1.2.4" -> "1.2")
    var parent: SequenceID? {
        guard components.count > 1 else { return nil }
        return SequenceID(components: Array(components.dropLast()))
    }
}

// MARK: - SequenceID Codable

extension SequenceID: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        guard let sequenceID = SequenceID(from: string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid SequenceID format: \(string)"
            )
        }
        
        self = sequenceID
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}

// MARK: - DisplayType

enum DisplayType: Equatable {
    enum Title: String, CaseIterable {
        case learningPath = "learning_path"
        case sequence
        case module
    }
    
    enum AporiaUser: String, CaseIterable {
        case mc
        case openEnded = "open"
        case hybrid
    }
    
    enum NA: String, CaseIterable {
        case aporiaRubric = "aporia_rubric"
        // Room for future non-display types like:
        // case scoringCriteria = "scoring_criteria"
        // case instructorNotes = "instructor_notes"
        // case llmContext = "llm_context"
    }
    
    case title(Title)
    case system
    case user
    case aporiaSystem
    case aporiaUser(AporiaUser)
    case na(NA)  // Non-displayed content for system use
}

// MARK: - DisplayType String Conversion

extension DisplayType {
    /// Convert DisplayType to its string representation
    var stringValue: String {
        switch self {
        case .title(let subtype):
            return "title.\(subtype.rawValue)"
        case .system:
            return "system"
        case .user:
            return "user"
        case .aporiaSystem:
            return "aporia-system"
        case .aporiaUser(let subtype):
            return "aporia-user.\(subtype.rawValue)"
        case .na(let subtype):
            return "na.\(subtype.rawValue)"
        }
    }
    
    /// Initialize DisplayType from a string representation
    init?(from string: String) {
        // Handle simple cases first
        switch string {
        case "system":
            self = .system
        case "user":
            self = .user
        case "aporia-system":
            self = .aporiaSystem
        default:
            // Handle compound cases
            let components = string.split(separator: ".", maxSplits: 1)
            guard components.count == 2 else { return nil }
            
            let prefix = String(components[0])
            let suffix = String(components[1])
            
            switch prefix {
            case "title":
                guard let titleType = Title(rawValue: suffix) else { return nil }
                self = .title(titleType)
            case "aporia-user":
                guard let aporiaType = AporiaUser(rawValue: suffix) else { return nil }
                self = .aporiaUser(aporiaType)
            case "na":
                guard let naType = NA(rawValue: suffix) else { return nil }
                self = .na(naType)
            default:
                return nil
            }
        }
    }
}

// MARK: - DisplayType Codable Support

extension DisplayType: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        guard let displayType = DisplayType(from: string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid DisplayType string: \(string)"
            )
        }
        
        self = displayType
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}

// MARK: - Content

/// Simple type alias for content strings
typealias Content = String

// MARK: - NextAction

enum NextAction: String, CaseIterable, Codable {
    case getNextModule
    case getNextChunk
    case getNextAporiaSystem
    case getNextAporiaUser
}

// MARK: - NextChunk

/// Represents the next chunk reference, which points to a SequenceID
struct NextChunk: Equatable, Codable {
    let sequenceID: SequenceID
    
    init(sequenceID: SequenceID) {
        self.sequenceID = sequenceID
    }
    
    /// Convenience initializer from string
    init?(from string: String) {
        guard let id = SequenceID(from: string) else { return nil }
        self.sequenceID = id
    }
    
    /// Get string representation
    var stringValue: String {
        sequenceID.stringValue
    }
}

// MARK: - Complete Data Model

/// Represents the complete data structure with all six fields
struct DataChunk: Codable, Equatable {
    let sequenceID: SequenceID
    let displayType: DisplayType
    let content: Content
    let nextAction: NextAction
    let nextChunk: NextChunk?  // Optional in case it's the last chunk
    let id: UUID  // Unique identifier for cross-module/sequence references
    
    init(sequenceID: SequenceID,
         displayType: DisplayType,
         content: Content,
         nextAction: NextAction,
         nextChunk: NextChunk? = nil,
         id: UUID = UUID()) {  // Auto-generates UUID if not provided
        self.sequenceID = sequenceID
        self.displayType = displayType
        self.content = content
        self.nextAction = nextAction
        self.nextChunk = nextChunk
        self.id = id
    }
}

// MARK: - Usage Examples

/*
 // Creating SequenceIDs
 let id1 = SequenceID(1)                           // "1"
 let id2 = SequenceID(components: [1, 2, 4])       // "1.2.4"
 let id3 = SequenceID(from: "14.1.2.3")           // "14.1.2.3"
 
 // Working with hierarchies
 if let parent = id2?.parent {
     print(parent.stringValue)  // "1.2"
 }
 
 // Creating a rubric chunk (not displayed to users)
 let rubricChunk = DataChunk(
     sequenceID: SequenceID(components: [1, 2, 1]),
     displayType: .na(.aporiaRubric),
     content: """
     {
       "criteria": ["understanding", "clarity", "completeness"],
       "minLength": 50,
       "keyTopics": ["photosynthesis", "chlorophyll", "light reaction"]
     }
     """,
     nextAction: .getNextAporiaUser,
     nextChunk: NextChunk(sequenceID: SequenceID(components: [1, 2, 2]))
 )
 
 // Creating a complete data chunk
 let chunk = DataChunk(
     sequenceID: SequenceID(components: [1, 2]),
     displayType: .title(.learningPath),
     content: "Welcome to the learning path!",
     nextAction: .getNextChunk,
     nextChunk: NextChunk(sequenceID: SequenceID(components: [1, 2, 1]))
     // id is auto-generated
 )
 
 // Creating with specific UUID
 let specificChunk = DataChunk(
     sequenceID: SequenceID(components: [2, 1]),
     displayType: .system,
     content: "System message",
     nextAction: .getNextModule,
     nextChunk: nil,
     id: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!
 )
 
 // JSON encoding/decoding works automatically
 let encoder = JSONEncoder()
 encoder.outputFormatting = .prettyPrinted
 let jsonData = try encoder.encode(chunk)
 print(String(data: jsonData, encoding: .utf8)!)
 
 /* Output:
 {
   "sequenceID" : "1.2",
   "displayType" : "title.learning_path",
   "content" : "Welcome to the learning path!",
   "nextAction" : "getNextChunk",
   "nextChunk" : {
     "sequenceID" : "1.2.1"
   },
   "id" : "550E8400-E29B-41D4-A716-446655440000"
 }
 */
 */
