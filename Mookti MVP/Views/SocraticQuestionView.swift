import SwiftUI

struct SocraticQuestionView: View {
    let response: SocraticResponse
    @State private var showHint = false
    @State private var selectedQuestion: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Answer section (if provided)
            if let answer = response.answer {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Ellen's Response", systemImage: "text.bubble")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(answer)
                        .font(.body)
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(12)
                }
            }
            
            // Focus Question (Required)
            QuestionCard(
                type: .focus,
                question: response.focusQuestion,
                icon: "target",
                color: .blue,
                isSelected: selectedQuestion == "focus"
            ) {
                selectedQuestion = "focus"
            }
            
            // Extension Question (Optional)
            if let extensionQ = response.extensionQuestion {
                QuestionCard(
                    type: .extension,
                    question: extensionQ,
                    icon: "arrow.up.right.circle",
                    color: .purple,
                    isSelected: selectedQuestion == "extension"
                ) {
                    selectedQuestion = "extension"
                }
            }
            
            // Assumption Probe (Optional)
            if let probe = response.assumptionProbe {
                QuestionCard(
                    type: .probe,
                    question: probe,
                    icon: "questionmark.bubble",
                    color: .orange,
                    isSelected: selectedQuestion == "probe"
                ) {
                    selectedQuestion = "probe"
                }
            }
            
            // Hint Cascade
            if let hints = response.hintCascade {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { showHint.toggle() }) {
                        Label(showHint ? "Hide Hint" : "Need a Hint?", 
                              systemImage: "lightbulb")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    
                    if showHint {
                        VStack(alignment: .leading, spacing: 6) {
                            if let nudge = hints.nudge {
                                HintLevel(level: "Nudge", content: nudge, icon: "hand.point.right")
                            }
                            if let structure = hints.structure {
                                HintLevel(level: "Structure", content: structure, icon: "square.stack.3d.up")
                            }
                            if let partial = hints.partialStep {
                                HintLevel(level: "Partial Step", content: partial, icon: "stairs")
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            
            // Empathy message
            if let empathy = response.empathy {
                HStack(spacing: 8) {
                    Image(systemName: "heart.circle")
                        .foregroundColor(.pink)
                    Text(empathy)
                        .font(.caption)
                        .italic()
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.pink.opacity(0.05))
                .cornerRadius(8)
            }
            
            // Citations
            if let citations = response.citations, !citations.isEmpty {
                CitationsView(citations: citations)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct QuestionCard: View {
    enum QuestionType {
        case focus, extension, probe
        
        var label: String {
            switch self {
            case .focus: return "Focus Question"
            case .extension: return "Extension"
            case .probe: return "Assumption Check"
            }
        }
    }
    
    let type: QuestionType
    let question: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(type.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(question)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? color.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HintLevel: View {
    let level: String
    let content: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(level)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text(content)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .padding(8)
        .background(Color.yellow.opacity(0.05))
        .cornerRadius(6)
    }
}

struct CitationsView: View {
    let citations: [Citation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Sources", systemImage: "book.closed")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(citations, id: \.title) { citation in
                HStack(spacing: 6) {
                    if citation.isUserSource {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption2)
                    }
                    
                    Text("[\(citation.source)]")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(citation.title)
                        .font(.caption)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(citation.isUserSource ? Color.blue.opacity(0.05) : Color(.systemGray6))
                .cornerRadius(6)
            }
        }
    }
}

// Data Models
struct SocraticResponse {
    let answer: String?
    let focusQuestion: String
    let extensionQuestion: String?
    let assumptionProbe: String?
    let hintCascade: HintCascade?
    let feedback: FormativeFeedback?
    let evidenceTags: [String]?
    let citations: [Citation]?
    let empathy: String?
}

struct HintCascade {
    let nudge: String?
    let structure: String?
    let partialStep: String?
}

struct Citation {
    let title: String
    let source: String
    let loc: String?
    let isUserSource: Bool
}