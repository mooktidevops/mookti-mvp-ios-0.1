//
//  LimitedPreviewAlert.swift
//  Mookti MVP
//
//  Created on 2025-08-06.
//

import SwiftUI

// MARK: - View Extension
extension View {
    /// Presents a standardized alert indicating that the
    /// specified feature is not yet available in the limited investor preview.
    /// - Parameters:
    ///   - isPresented: A binding to control when the alert is shown
    ///   - feature: The name of the feature that isn't available yet
    func limitedPreviewAlert(
        isPresented: Binding<Bool>,
        feature: String = "This feature"
    ) -> some View {
        self.alert("Limited Investor Preview", isPresented: isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You're using Mookti's limited investor preview. \(feature) isn't ready yet! 😊")
        }
    }
}
