import SwiftUI

/// HIG‑required disclosure that answers come from an LLM and may be imperfect.
struct AIDisclaimerView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
            Text("Generated with on‑device AI. Verify important facts.")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
