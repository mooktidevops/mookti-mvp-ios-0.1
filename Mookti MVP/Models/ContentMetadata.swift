//
//  ContentMetadata.swift
//  Mookti MVP
//
//  Content metadata structures for organizing learning paths and modules
//

import Foundation

// MARK: - Module Manifest
/// Defines a complete learning module with metadata and structure
struct ModuleManifest: Codable {
    let id: String
    let title: String
    let description: String
    let version: String
    let authors: [Author]
    let prerequisites: [String]? // IDs of prerequisite modules
    let estimatedDuration: Int // in minutes
    let difficulty: Difficulty
    let tags: [String]
    let learningObjectives: [String]
    let assessmentStrategy: AssessmentStrategy
    let contentPaths: ContentPaths
    let metadata: ModuleMetadata
}

struct Author: Codable {
    let name: String
    let credentials: String?
    let affiliation: String?
}

enum Difficulty: String, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
}

struct ContentPaths: Codable {
    let mainPath: String // Primary CSV file
    let supplementaryContent: [String]? // Additional CSVs
    let assessments: String? // Assessment CSV
    let practiceQuestions: String? // Practice questions CSV
    let resources: [String]? // PDFs, videos, etc.
}

struct ModuleMetadata: Codable {
    let subject: String // e.g., "Cultural Intelligence", "Emotional Intelligence"
    let domain: String // e.g., "Workplace Success", "Academic Success"
    let lastUpdated: Date
    let language: String
    let accessibility: AccessibilityFeatures?
}

struct AccessibilityFeatures: Codable {
    let audioDescriptions: Bool
    let closedCaptions: Bool
    let transcripts: Bool
    let simplifiedLanguage: Bool
}

// MARK: - Assessment Strategy
struct AssessmentStrategy: Codable {
    let formativeAssessments: [AssessmentPoint]
    let summativeAssessment: SummativeAssessment?
    let masteryThreshold: Double // 0.0 to 1.0
}

struct AssessmentPoint: Codable {
    let nodeId: String // Where in the path this assessment occurs
    let type: AssessmentType
    let weight: Double // Contribution to overall score
}

enum AssessmentType: String, Codable {
    case comprehensionCheck = "comprehension_check"
    case applicationScenario = "application_scenario"
    case reflection = "reflection"
    case project = "project"
}

struct SummativeAssessment: Codable {
    let nodeId: String
    let passingScore: Double
    let retakePolicy: RetakePolicy
}

struct RetakePolicy: Codable {
    let maxAttempts: Int
    let cooldownPeriod: Int // in hours
    let showCorrectAnswers: Bool
}

// MARK: - Enhanced Node Types
/// Extended node types for richer content
enum ExtendedDisplayType: String, Codable {
    // Existing types
    case system = "system"
    case aporiaSystem = "aporia-system"
    case aporiaUser = "aporia-user"
    case cardCarousel = "card-carousel"
    case media = "media"
    case moduleTitle = "module_title"
    case moduleDescription = "module_description"
    
    // New content types
    case interactiveSimulation = "interactive-simulation"
    case caseStudy = "case-study"
    case infographic = "infographic"
    case worksheet = "worksheet"
    case quiz = "quiz"
    case reflection = "reflection-prompt"
    case externalResource = "external-resource"
    case codePlayground = "code-playground"
    case conceptMap = "concept-map"
}

// MARK: - Enhanced Learning Node
/// Extended node structure with metadata
struct EnhancedLearningNode: Codable {
    let id: String
    let type: ExtendedDisplayType
    let content: NodeContent
    let metadata: NodeMetadata
    let navigation: NodeNavigation
    let interactions: NodeInteractions?
    let assessment: NodeAssessment?
}

struct NodeContent: Codable {
    let primary: String // Main content
    let secondary: String? // Supporting content
    let media: [MediaItem]?
    let citations: [Citation]?
    let glossaryTerms: [GlossaryTerm]?
}

struct MediaItem: Codable {
    let type: MediaType
    let url: String
    let caption: String?
    let transcript: String?
    let duration: Int? // in seconds for video/audio
}

enum MediaType: String, Codable {
    case image = "image"
    case video = "video"
    case audio = "audio"
    case pdf = "pdf"
    case interactive = "interactive"
}

struct Citation: Codable {
    let id: String
    let authors: String
    let title: String
    let year: Int
    let source: String
    let doi: String?
    let url: String?
}

struct GlossaryTerm: Codable {
    let term: String
    let definition: String
    let relatedTerms: [String]?
}

struct NodeMetadata: Codable {
    let estimatedTime: Int? // in seconds
    let difficulty: Difficulty?
    let prerequisiteNodes: [String]?
    let learningObjectives: [String]?
    let cognitiveLevel: CognitiveLevel? // Bloom's Taxonomy
}

enum CognitiveLevel: String, Codable {
    case remember = "remember"
    case understand = "understand"
    case apply = "apply"
    case analyze = "analyze"
    case evaluate = "evaluate"
    case create = "create"
}

struct NodeNavigation: Codable {
    let nextAction: String
    let nextNodes: [String]
    let conditionalNavigation: [ConditionalNav]?
    let allowBacktrack: Bool
    let savePoint: Bool // Whether this is a resumption point
}

struct ConditionalNav: Codable {
    let condition: NavCondition
    let targetNode: String
}

struct NavCondition: Codable {
    let type: ConditionType
    let value: String
}

enum ConditionType: String, Codable {
    case scoreAbove = "score_above"
    case scoreBelow = "score_below"
    case timeSpent = "time_spent"
    case attemptsExceeded = "attempts_exceeded"
    case conceptMastered = "concept_mastered"
}

struct NodeInteractions: Codable {
    let allowNotes: Bool
    let allowBookmark: Bool
    let requireConfirmation: Bool // Must confirm understanding before proceeding
    let trackEngagement: Bool
}

struct NodeAssessment: Codable {
    let questions: [AssessmentQuestion]
    let passingScore: Double?
    let feedback: FeedbackStrategy
    let analytics: AssessmentAnalytics
}

struct AssessmentQuestion: Codable {
    let id: String
    let type: QuestionType
    let prompt: String
    let options: [AnswerOption]?
    let correctAnswer: String?
    let explanation: String?
    let points: Int
    let cognitiveLevel: CognitiveLevel
    let hints: [String]?
}

enum QuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case multipleSelect = "multiple_select"
    case trueFalse = "true_false"
    case shortAnswer = "short_answer"
    case essay = "essay"
    case matching = "matching"
    case ordering = "ordering"
    case fillInBlank = "fill_in_blank"
    case codeCompletion = "code_completion"
}

struct AnswerOption: Codable {
    let id: String
    let text: String
    let feedback: String? // Specific feedback for this option
}

struct FeedbackStrategy: Codable {
    let immediate: Bool
    let detailed: Bool
    let adaptive: Bool // Adjusts based on performance
    let encouraging: Bool // Positive reinforcement focus
}

struct AssessmentAnalytics: Codable {
    let trackTime: Bool
    let trackAttempts: Bool
    let identifyMisconceptions: Bool
    let recommendRemediation: Bool
}

// MARK: - Progress Tracking
struct LearnerProgress: Codable {
    let userId: String
    let moduleId: String
    let currentNodeId: String
    let nodesCompleted: Set<String>
    let assessmentScores: [String: Double] // nodeId: score
    let timeSpent: [String: Int] // nodeId: seconds
    let bookmarks: [String]
    let notes: [NodeNote]
    let startedAt: Date
    let lastAccessedAt: Date
    let completedAt: Date?
    let masteryLevel: MasteryLevel?
}

struct NodeNote: Codable {
    let nodeId: String
    let content: String
    let createdAt: Date
    let tags: [String]?
}

enum MasteryLevel: String, Codable {
    case novice = "novice"
    case developing = "developing"
    case proficient = "proficient"
    case advanced = "advanced"
    case expert = "expert"
}

// MARK: - Content Package
/// Complete content package that can be loaded and validated
struct ContentPackage: Codable {
    let manifest: ModuleManifest
    let nodes: [String: EnhancedLearningNode]
    let assessments: [String: NodeAssessment]?
    let resources: [String: URL]?
    let version: String
    let checksum: String // For integrity verification
}
