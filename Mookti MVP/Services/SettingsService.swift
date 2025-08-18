//
//  SettingsService.swift
//  Mookti
//

import Foundation
import Combine
import SwiftUI

/// Persists user‑facing toggles via @AppStorage.
@MainActor
final class SettingsService: ObservableObject {

    @AppStorage("useOnDeviceOnly")   var useOnDeviceOnly  = false
    @AppStorage("streamReplies")     var streamReplies    = true
    @AppStorage("telemetryOptIn")    var telemetryOptIn   = false
    @AppStorage("enableAIDisclaimer") var enableAIDisclaimer = true
    @AppStorage("messageDeliverySpeed") var messageDeliverySpeed = 1.0  // 1.0 = normal speed
    @AppStorage("learningPath") var learningPath: String? = nil  // nil = no pre-written content, "workplace_success" = Workplace Success learning path


    /// Erase all persisted settings (used by "Reset" button).
    func reset() {
        useOnDeviceOnly  = false
        streamReplies    = true
        telemetryOptIn   = false
        messageDeliverySpeed = 1.0
        learningPath = nil
    }
}
