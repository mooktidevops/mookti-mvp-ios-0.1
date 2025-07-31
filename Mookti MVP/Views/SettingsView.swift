//
//  SettingsView.swift
//  Mookti
//
//  Cloud-only version without API key management
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settingsStore: SettingsService
    @EnvironmentObject private var userProgress: UserProgressService
    @EnvironmentObject private var historyStore: ConversationStore
    
    @StateObject private var vm: SettingsViewModel
    
    @State private var showResetAlert = false
    @State private var showClearAlert = false
    
    private var speedDescription: String {
        switch vm.messageDeliverySpeed {
        case 0.5..<0.8:
            return "Slower delivery for careful reading"
        case 0.8..<1.2:
            return "Normal reading speed"
        case 1.2..<1.6:
            return "Faster delivery for quick readers"
        case 1.6...2.0:
            return "Rapid delivery for speed readers"
        default:
            return "Normal reading speed"
        }
    }

    init() {
        do {
            let container = try ModelContainer(for: StoredMessage.self, Conversation.self)
            _vm = StateObject(wrappedValue: SettingsViewModel(
                settings: SettingsService(),
                history: ConversationStore(modelContext: container.mainContext)
            ))
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("AI Preferences")) {
                Toggle("Stream replies token‑by‑token", isOn: $vm.streamReplies)
                Toggle("Show AI disclaimer banner", isOn: $settingsStore.enableAIDisclaimer)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Message Delivery Speed")
                    Slider(value: $vm.messageDeliverySpeed, in: 0.5...2.0, step: 0.1) {
                        Text("Speed")
                    } minimumValueLabel: {
                        Text("Slow")
                            .font(.caption2)
                    } maximumValueLabel: {
                        Text("Fast")
                            .font(.caption2)
                    }
                    Text(speedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text("All AI processing is handled securely through cloud services")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Section(header: Text("Privacy")) {
                Toggle("Share anonymous usage data", isOn: $vm.telemetryOptIn)
            }
            
            Section(header: Text("Analytics & Logging")) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("AI Interaction Logs", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline)
                    
                    Text("Your AI interactions are automatically logged to Firebase Analytics for monitoring and improvement.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Logs include:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• AI service type (Ellen/Cloud)")
                        Text("• Response times and duration")
                        Text("• Success/error status")
                        Text("• Token counts (estimated)")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 12)
                    
                    Text("Note: Logs are viewable in Firebase Console by the development team.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }
            
            Section {
                Button("Clear Conversation History", role: .destructive) {
                    showClearAlert = true
                }
                
                Button("Reset All Settings", role: .destructive) {
                    showResetAlert = true
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Reset All Settings?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                vm.resetAll()
            }
        } message: {
            Text("This will restore default preferences.")
        }
        .alert("Delete all chat history?", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                vm.clearHistory()
            }
        } message: {
            Text("This cannot be undone.")
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(SettingsService())
                .environmentObject(UserProgressService())
                .environmentObject(ConversationStore(modelContext: try! ModelContainer(for: StoredMessage.self, Conversation.self).mainContext))
        }
    }
}
#endif