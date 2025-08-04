//
//  LimitedPreviewAlert.swift
//  Mookti MVP
//
//  Created on 2025-08-06.
//

import SwiftUI

/// A view modifier that presents an alert for features not yet
/// available in the limited investor preview build.
struct LimitedPreviewAlert: ViewModifier {
    @Binding var isPresented: Bool
    let feature: String

    func body(content: Content) -> some View {
        content
            .alert("Limited Investor Preview", isPresented: $isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("You're using Mookti's limited investor preview. \(feature) isn't ready yet! 😊")
            }
    }
}

// MARK: - View Extension
extension View {
    /// Presents a standardized alert indicating that the
    /// specified feature is not yet available.
    func limitedPreviewAlert(isPresented: Binding<Bool>, feature: String = "This feature") -> some View {
        modifier(LimitedPreviewAlert(isPresented: isPresented, feature: feature))
    }
}
