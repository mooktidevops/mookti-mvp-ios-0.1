import SwiftUI

struct DiagnosticProbeView: View {
    let diagnostic: DiagnosticProbe
    @State private var currentProbeIndex = 0
    @State private var userAnswers: [String] = []
    @State private var showCoverageMap = false
    @State private var probeStatus: [ProbeStatus] = []
    
    init(diagnostic: DiagnosticProbe) {
        self.diagnostic = diagnostic
        self._userAnswers = State(initialValue: Array(repeating: "", count: diagnostic.probes.count))
        self._probeStatus = State(initialValue: Array(repeating: .unanswered, count: diagnostic.probes.count))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Diagnostic Assessment", systemImage: "stethoscope")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Progress indicator
                    Text("\(currentProbeIndex + 1) of \(diagnostic.probes.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(
                                width: geometry.size.width * CGFloat(currentProbeIndex + 1) / CGFloat(diagnostic.probes.count),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
                
                // Probe indicators
                HStack(spacing: 4) {
                    ForEach(0..<diagnostic.probes.count, id: \.self) { index in
                        ProbeIndicator(
                            status: probeStatus[index],
                            isActive: index == currentProbeIndex
                        )
                        .onTapGesture {
                            withAnimation {
                                currentProbeIndex = index
                            }
                        }
                    }
                }
            }
            
            // Current Probe
            ProbeCard(
                probe: diagnostic.probes[currentProbeIndex],
                answer: $userAnswers[currentProbeIndex],
                onSubmit: {
                    markProbeAnswered(at: currentProbeIndex)
                }
            )
            
            // Navigation
            HStack {
                Button(action: {
                    withAnimation {
                        currentProbeIndex = max(0, currentProbeIndex - 1)
                    }
                }) {
                    Label("Previous", systemImage: "chevron.left")
                        .font(.caption)
                }
                .disabled(currentProbeIndex == 0)
                
                Spacer()
                
                if currentProbeIndex < diagnostic.probes.count - 1 {
                    Button(action: {
                        withAnimation {
                            currentProbeIndex += 1
                        }
                    }) {
                        Label("Next", systemImage: "chevron.right")
                            .font(.caption)
                    }
                } else {
                    Button(action: {
                        showCoverageMap = true
                    }) {
                        Label("View Results", systemImage: "chart.bar")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // Coverage Map
            if showCoverageMap {
                CoverageMapView(
                    coverageMap: diagnostic.coverageMap,
                    recommendedPath: diagnostic.recommendedPath
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func markProbeAnswered(at index: Int) {
        if !userAnswers[index].isEmpty {
            probeStatus[index] = .answered
        }
    }
}

struct ProbeCard: View {
    let probe: DiagnosticProbeItem
    @Binding var answer: String
    let onSubmit: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Probe type and difficulty
            HStack {
                ProbeTypeLabel(type: probe.type)
                Spacer()
                DifficultyIndicator(difficulty: probe.difficulty)
            }
            
            // Question
            Text(probe.question)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
            
            // Answer input
            VStack(alignment: .leading, spacing: 6) {
                Label("Your Response", systemImage: "pencil")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $answer)
                    .focused($isFocused)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
                    )
            }
            
            // Submit button
            Button(action: {
                onSubmit()
                isFocused = false
            }) {
                Text("Save Response")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(answer.isEmpty)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProbeIndicator: View {
    let status: ProbeStatus
    let isActive: Bool
    
    var body: some View {
        Circle()
            .fill(fillColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(isActive ? Color.blue : Color.clear, lineWidth: 2)
            )
    }
    
    private var fillColor: Color {
        switch status {
        case .unanswered:
            return Color(.systemGray4)
        case .answered:
            return Color.green
        case .skipped:
            return Color.orange
        }
    }
}

struct ProbeTypeLabel: View {
    let type: ProbeType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(6)
    }
    
    private var icon: String {
        switch type {
        case .conceptual:
            return "brain"
        case .procedural:
            return "list.number"
        case .boundaryCase:
            return "exclamationmark.triangle"
        }
    }
    
    private var label: String {
        switch type {
        case .conceptual:
            return "Conceptual"
        case .procedural:
            return "Procedural"
        case .boundaryCase:
            return "Edge Case"
        }
    }
    
    private var color: Color {
        switch type {
        case .conceptual:
            return .blue
        case .procedural:
            return .green
        case .boundaryCase:
            return .orange
        }
    }
}

struct DifficultyIndicator: View {
    let difficulty: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { level in
                Image(systemName: level <= difficulty ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundColor(level <= difficulty ? .yellow : .gray)
            }
            Text(difficultyLabel)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var difficultyLabel: String {
        switch difficulty {
        case 1:
            return "Basic"
        case 2:
            return "Intermediate"
        case 3:
            return "Advanced"
        default:
            return "Unknown"
        }
    }
}

struct CoverageMapView: View {
    let coverageMap: [String: Bool]
    let recommendedPath: [String]?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Coverage Analysis", systemImage: "chart.bar.doc.horizontal")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Coverage indicators
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(coverageMap.keys.sorted()), id: \.self) { key in
                    HStack {
                        Image(systemName: coverageMap[key] ?? false ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(coverageMap[key] ?? false ? .green : .gray)
                            .font(.caption)
                        
                        Text(formatCoverageKey(key))
                            .font(.caption)
                        
                        Spacer()
                        
                        Text(coverageMap[key] ?? false ? "Assessed" : "Not Assessed")
                            .font(.caption2)
                            .foregroundColor(coverageMap[key] ?? false ? .green : .secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Recommended path
            if let path = recommendedPath, !path.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Recommended Learning Path", systemImage: "arrow.right.circle")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(path, id: \.self) { step in
                                Text(step)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.02))
        .cornerRadius(12)
    }
    
    private func formatCoverageKey(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

// Data Models
struct DiagnosticProbe {
    let probes: [DiagnosticProbeItem]
    let coverageMap: [String: Bool]
    let recommendedPath: [String]?
}

struct DiagnosticProbeItem {
    let question: String
    let type: ProbeType
    let difficulty: Int
}

enum ProbeType {
    case conceptual
    case procedural
    case boundaryCase
}

enum ProbeStatus {
    case unanswered
    case answered
    case skipped
}