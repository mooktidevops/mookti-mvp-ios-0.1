import SwiftUI

// Main view that determines which formative tool view to display
struct FormativeToolMessageView: View {
    let message: Message
    let toolResponse: FormativeToolResponse
    
    var body: some View {
        Group {
            switch toolResponse.toolType {
            case .socraticElenchus:
                if let data = toolResponse.socraticData {
                    SocraticQuestionView(response: data)
                }
                
            case .formativeFeedback:
                if let data = toolResponse.feedbackData {
                    FormativeFeedbackView(feedback: data)
                }
                
            case .workedExample:
                if let data = toolResponse.workedExampleData {
                    WorkedExampleView(example: data)
                }
                
            case .conceptMap:
                if let data = toolResponse.conceptMapData {
                    ConceptMapView(conceptMap: data)
                }
                
            case .diagnosticProbe:
                if let data = toolResponse.diagnosticData {
                    DiagnosticProbeView(diagnostic: data)
                }
                
            case .revisionSchedule:
                if let data = toolResponse.scheduleData {
                    RevisionScheduleView(schedule: data)
                }
                
            case .documentUpload:
                DocumentUploadView()
                
            default:
                // Fallback to regular text message
                Text(message.content)
                    .font(.body)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// Extension to detect formative tool responses in messages
extension Message {
    var formativeToolResponse: FormativeToolResponse? {
        // Parse message metadata to determine if it contains a formative tool response
        guard let metadata = self.metadata,
              let toolType = metadata["tool_type"] as? String else {
            return nil
        }
        
        return FormativeToolResponse(
            toolType: FormativeToolType(rawValue: toolType) ?? .unknown,
            rawData: metadata
        )
    }
    
    var isFormativeToolMessage: Bool {
        formativeToolResponse != nil
    }
}

// Formative tool response wrapper
struct FormativeToolResponse {
    let toolType: FormativeToolType
    let rawData: [String: Any]
    
    var socraticData: SocraticResponse? {
        guard toolType == .socraticElenchus else { return nil }
        // Parse raw data into SocraticResponse
        return parseSocraticResponse(from: rawData)
    }
    
    var feedbackData: FormativeFeedback? {
        guard toolType == .formativeFeedback else { return nil }
        return parseFormativeFeedback(from: rawData)
    }
    
    var workedExampleData: WorkedExample? {
        guard toolType == .workedExample else { return nil }
        return parseWorkedExample(from: rawData)
    }
    
    var conceptMapData: ConceptMap? {
        guard toolType == .conceptMap else { return nil }
        return parseConceptMap(from: rawData)
    }
    
    var diagnosticData: DiagnosticProbe? {
        guard toolType == .diagnosticProbe else { return nil }
        return parseDiagnosticProbe(from: rawData)
    }
    
    var scheduleData: RevisionSchedule? {
        guard toolType == .revisionSchedule else { return nil }
        return parseRevisionSchedule(from: rawData)
    }
    
    // Parsing functions
    private func parseSocraticResponse(from data: [String: Any]) -> SocraticResponse {
        SocraticResponse(
            answer: data["answer"] as? String,
            focusQuestion: data["focus_question"] as? String ?? "Can you elaborate on that?",
            extensionQuestion: data["extension_question"] as? String,
            assumptionProbe: data["assumption_probe"] as? String,
            hintCascade: parseHintCascade(from: data["hint_cascade"] as? [String: Any]),
            feedback: nil,
            evidenceTags: data["evidence_tags"] as? [String],
            citations: parseCitations(from: data["citations"] as? [[String: Any]]),
            empathy: data["empathy"] as? String
        )
    }
    
    private func parseHintCascade(from data: [String: Any]?) -> HintCascade? {
        guard let data = data else { return nil }
        return HintCascade(
            nudge: data["nudge"] as? String,
            structure: data["structure"] as? String,
            partialStep: data["partial_step"] as? String
        )
    }
    
    private func parseCitations(from data: [[String: Any]]?) -> [Citation]? {
        guard let data = data else { return nil }
        return data.compactMap { dict in
            guard let title = dict["title"] as? String,
                  let source = dict["source"] as? String else { return nil }
            return Citation(
                title: title,
                source: source,
                loc: dict["loc"] as? String,
                isUserSource: dict["is_user_source"] as? Bool ?? false
            )
        }
    }
    
    private func parseFormativeFeedback(from data: [String: Any]) -> FormativeFeedback {
        FormativeFeedback(
            evidenceTags: data["evidence_tags"] as? [String] ?? [],
            feedUp: data["feed_up"] as? String ?? "",
            feedBack: data["feed_back"] as? String ?? "",
            feedForward: data["feed_forward"] as? String ?? "",
            misconceptions: parseMisconceptions(from: data["misconceptions"] as? [[String: Any]])
        )
    }
    
    private func parseMisconceptions(from data: [[String: Any]]?) -> [Misconception]? {
        guard let data = data else { return nil }
        return data.compactMap { dict in
            guard let identified = dict["identified"] as? String,
                  let correction = dict["correction"] as? String else { return nil }
            return Misconception(identified: identified, correction: correction)
        }
    }
    
    private func parseWorkedExample(from data: [String: Any]) -> WorkedExample {
        WorkedExample(
            problemStatement: data["problem_statement"] as? String ?? "",
            steps: parseSteps(from: data["steps"] as? [[String: Any]]),
            strategyHighlight: data["strategy_highlight"] as? String,
            commonErrors: data["common_errors"] as? [String],
            practiceVariations: data["practice_variations"] as? [String]
        )
    }
    
    private func parseSteps(from data: [[String: Any]]?) -> [WorkedExampleStep] {
        guard let data = data else { return [] }
        return data.compactMap { dict in
            guard let step = dict["step"] as? String,
                  let why = dict["why"] as? String else { return nil }
            return WorkedExampleStep(
                step: step,
                why: why,
                visual: dict["visual"] as? String
            )
        }
    }
    
    private func parseConceptMap(from data: [String: Any]) -> ConceptMap {
        ConceptMap(
            nodes: parseNodes(from: data["nodes"] as? [[String: Any]]),
            edges: parseEdges(from: data["edges"] as? [[String: Any]]),
            prerequisites: data["prerequisites"] as? [String],
            applications: data["applications"] as? [String]
        )
    }
    
    private func parseNodes(from data: [[String: Any]]?) -> [ConceptNode] {
        guard let data = data else { return [] }
        return data.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let label = dict["label"] as? String,
                  let typeStr = dict["type"] as? String else { return nil }
            
            let type: ConceptNodeType = {
                switch typeStr {
                case "example": return .example
                case "application": return .application
                default: return .concept
                }
            }()
            
            return ConceptNode(id: id, label: label, type: type)
        }
    }
    
    private func parseEdges(from data: [[String: Any]]?) -> [ConceptEdge] {
        guard let data = data else { return [] }
        return data.compactMap { dict in
            guard let from = dict["from"] as? String,
                  let to = dict["to"] as? String,
                  let relationship = dict["relationship"] as? String else { return nil }
            return ConceptEdge(from: from, to: to, relationship: relationship)
        }
    }
    
    private func parseDiagnosticProbe(from data: [String: Any]) -> DiagnosticProbe {
        DiagnosticProbe(
            probes: parseProbes(from: data["probes"] as? [[String: Any]]),
            coverageMap: data["coverage_map"] as? [String: Bool] ?? [:],
            recommendedPath: data["recommended_path"] as? [String]
        )
    }
    
    private func parseProbes(from data: [[String: Any]]?) -> [DiagnosticProbeItem] {
        guard let data = data else { return [] }
        return data.compactMap { dict in
            guard let question = dict["question"] as? String,
                  let typeStr = dict["type"] as? String,
                  let difficulty = dict["difficulty"] as? Int else { return nil }
            
            let type: ProbeType = {
                switch typeStr {
                case "procedural": return .procedural
                case "boundary_case": return .boundaryCase
                default: return .conceptual
                }
            }()
            
            return DiagnosticProbeItem(
                question: question,
                type: type,
                difficulty: difficulty
            )
        }
    }
    
    private func parseRevisionSchedule(from data: [String: Any]) -> RevisionSchedule {
        RevisionSchedule(
            sessions: parseSessions(from: data["sessions"] as? [[String: Any]]),
            spacedIntervals: data["spaced_intervals"] as? [String: [Int]] ?? [:],
            interleavingPattern: data["interleaving_pattern"] as? [String],
            examDate: parseDate(from: data["exam_date"] as? String)
        )
    }
    
    private func parseSessions(from data: [[String: Any]]?) -> [RevisionSession] {
        guard let data = data else { return [] }
        return data.compactMap { dict in
            guard let dateStr = dict["date"] as? String,
                  let topics = dict["topics"] as? [String],
                  let duration = dict["duration_minutes"] as? Int,
                  let type = dict["type"] as? String else { return nil }
            
            guard let date = parseDate(from: dateStr) else { return nil }
            
            return RevisionSession(
                date: date,
                topics: topics,
                durationMinutes: duration,
                type: type
            )
        }
    }
    
    private func parseDate(from string: String?) -> Date? {
        guard let string = string else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }
}

enum FormativeToolType: String {
    case socraticElenchus = "socratic_elenchus"
    case formativeFeedback = "formative_feedback"
    case workedExample = "worked_example"
    case conceptMap = "concept_map"
    case diagnosticProbe = "diagnostic_probe"
    case revisionSchedule = "revision_schedule"
    case documentUpload = "document_upload"
    case unknown = "unknown"
}