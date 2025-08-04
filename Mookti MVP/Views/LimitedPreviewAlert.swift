import SwiftUI

struct LimitedPreviewAlert: ViewModifier {
    @Binding var isPresented: Bool
    let feature: String
    
    typealias Body = some View
    
    func body(content: Self.Content) -> some View {
        content
            .alert("Limited Investor Preview", isPresented: $isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("You're using Mookti's limited investor preview. \(feature) isn't ready yet! 😊")
            }
    }
}

extension View {
    func limitedPreviewAlert(isPresented: Binding<Bool>, feature: String = "This feature") -> some View {
        self.modifier(LimitedPreviewAlert(isPresented: isPresented, feature: feature))
    }
}
