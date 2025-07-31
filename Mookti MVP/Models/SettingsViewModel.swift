//
//  SettingsViewModel.swift
//  Mookti
//

import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {

    // Two‑way bound properties
    @Published var useOnDeviceOnly: Bool {
        didSet { settings.useOnDeviceOnly = useOnDeviceOnly }
    }
    @Published var streamReplies: Bool {
        didSet { settings.streamReplies = streamReplies }
    }
    @Published var telemetryOptIn: Bool {
        didSet { settings.telemetryOptIn = telemetryOptIn }
    }
    @Published var messageDeliverySpeed: Double {
        didSet { settings.messageDeliverySpeed = messageDeliverySpeed }
    }

    // Dependencies
    private let settings: SettingsService
    private let history: ConversationStore

    init(settings: SettingsService, history: ConversationStore) {
        self.settings = settings
        self.history  = history

        // seed initial values
        useOnDeviceOnly = settings.useOnDeviceOnly
        streamReplies   = settings.streamReplies
        telemetryOptIn  = settings.telemetryOptIn
        messageDeliverySpeed = settings.messageDeliverySpeed
    }

    // MARK: - Actions
    func clearHistory() {
        history.clearAll()
    }

    func resetAll() {
        settings.reset()
        useOnDeviceOnly = settings.useOnDeviceOnly
        streamReplies   = settings.streamReplies
        telemetryOptIn  = settings.telemetryOptIn
        messageDeliverySpeed = settings.messageDeliverySpeed
    }
}
