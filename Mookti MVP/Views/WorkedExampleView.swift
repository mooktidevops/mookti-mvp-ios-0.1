import SwiftUI

struct WorkedExampleView: View {
    let example: WorkedExample
    @State private var currentStep = 0
    @State private var showAllSteps = false
    @State private var showCommonErrors = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Problem Statement
            VStack(alignment: .leading, spacing: 8) {
                Label("Problem", systemImage: "doc.text")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(example.problemStatement)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
            }
            
            // Strategy Highlight (if present)
            if let strategy = example.strategyHighlight {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("Strategy: \(strategy)")
                        .font(.caption)
                        .italic()
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Step Controls
            HStack {
                Text("Solution Steps")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showAllSteps.toggle() }) {
                    Label(showAllSteps ? "Step by Step" : "Show All", 
                          systemImage: showAllSteps ? "list.number" : "list.bullet")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Steps Display
            if showAllSteps {
                // Show all steps at once
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(example.steps.enumerated()), id: \.offset) { index, step in
                        StepView(
                            stepNumber: index + 1,
                            step: step,
                            isActive: true,
                            showWhy: true
                        )
                    }
                }
            } else {
                // Step-by-step navigation
                VStack(alignment: .leading, spacing: 12) {
                    StepView(
                        stepNumber: currentStep + 1,
                        step: example.steps[currentStep],
                        isActive: true,
                        showWhy: true
                    )
                    
                    // Navigation
                    HStack {
                        Button(action: { 
                            withAnimation {
                                currentStep = max(0, currentStep - 1)
                            }
                        }) {
                            Label("Previous", systemImage: "chevron.left")
                                .font(.caption)
                        }
                        .disabled(currentStep == 0)
                        
                        Spacer()
                        
                        Text("\(currentStep + 1) of \(example.steps.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: { 
                            withAnimation {
                                currentStep = min(example.steps.count - 1, currentStep + 1)
                            }
                        }) {
                            Label("Next", systemImage: "chevron.right")
                                .font(.caption)
                        }
                        .disabled(currentStep == example.steps.count - 1)
                    }
                    .padding(.top, 8)
                }
            }
            
            // Common Errors Section
            if let errors = example.commonErrors, !errors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { showCommonErrors.toggle() }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Common Errors")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: showCommonErrors ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                        }
                    }
                    
                    if showCommonErrors {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(errors, id: \.self) { error in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                                .padding(8)
                                .background(Color.red.opacity(0.05))
                                .cornerRadius(6)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            
            // Practice Variations
            if let variations = example.practiceVariations, !variations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Try These Variations", systemImage: "arrow.triangle.branch")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    
                    ForEach(variations, id: \.self) { variation in
                        HStack(spacing: 8) {
                            Image(systemName: "circle")
                                .font(.caption2)
                                .foregroundColor(.purple)
                            Text(variation)
                                .font(.caption)
                        }
                        .padding(6)
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct StepView: View {
    let stepNumber: Int
    let step: WorkedExampleStep
    let isActive: Bool
    let showWhy: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Step number circle
                ZStack {
                    Circle()
                        .fill(isActive ? Color.blue : Color(.systemGray4))
                        .frame(width: 28, height: 28)
                    Text("\(stepNumber)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Step content
                    Text(step.step)
                        .font(.body)
                        .foregroundColor(isActive ? .primary : .secondary)
                    
                    // Visual (if present)
                    if let visual = step.visual {
                        Text(visual)
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                    
                    // Why explanation
                    if showWhy && !step.why.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Why: \(step.why)")
                                .font(.caption)
                                .foregroundColor(.green)
                                .italic()
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .opacity(isActive ? 1 : 0.6)
    }
}

// Data Models
struct WorkedExample {
    let problemStatement: String
    let steps: [WorkedExampleStep]
    let strategyHighlight: String?
    let commonErrors: [String]?
    let practiceVariations: [String]?
}

struct WorkedExampleStep {
    let step: String
    let why: String
    let visual: String?
}