import SwiftUI

struct FormativeFeedbackView: View {
    let feedback: FormativeFeedback
    @State private var expandedSection: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Evidence Tags
            if !feedback.evidenceTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(feedback.evidenceTags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Feedback Sections
            VStack(alignment: .leading, spacing: 8) {
                // Feed-Up (Goal)
                FeedbackSection(
                    icon: "target",
                    title: "Goal",
                    content: feedback.feedUp,
                    color: .blue,
                    isExpanded: expandedSection == "up"
                ) {
                    withAnimation {
                        expandedSection = expandedSection == "up" ? nil : "up"
                    }
                }
                
                // Feed-Back (Progress)
                FeedbackSection(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress",
                    content: feedback.feedBack,
                    color: .green,
                    isExpanded: expandedSection == "back"
                ) {
                    withAnimation {
                        expandedSection = expandedSection == "back" ? nil : "back"
                    }
                }
                
                // Feed-Forward (Next Steps)
                FeedbackSection(
                    icon: "arrow.right.circle",
                    title: "Next Steps",
                    content: feedback.feedForward,
                    color: .purple,
                    isExpanded: expandedSection == "forward"
                ) {
                    withAnimation {
                        expandedSection = expandedSection == "forward" ? nil : "forward"
                    }
                }
            }
            
            // Misconceptions if present
            if let misconceptions = feedback.misconceptions, !misconceptions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Common Misconceptions", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    ForEach(misconceptions, id: \.identified) { misconception in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red.opacity(0.6))
                                .font(.caption)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(misconception.identified)
                                    .font(.caption)
                                    .strikethrough()
                                Text(misconception.correction)
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FeedbackSection: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isExpanded {
                    Text(content)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
            }
            .padding(10)
            .background(color.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Data Models
struct FormativeFeedback {
    let evidenceTags: [String]
    let feedUp: String
    let feedBack: String
    let feedForward: String
    let misconceptions: [Misconception]?
}

struct Misconception {
    let identified: String
    let correction: String
}