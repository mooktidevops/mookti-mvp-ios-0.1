import SwiftUI

struct BottomBar: View {
    var onEllen: () -> Void = {}
    var onHome: () -> Void = {}
    var onTeams: () -> Void = {}
    @State private var showAlert = false

    var body: some View {
        HStack {
            Button(action: onEllen) {
                Image(systemName: "bubble.left.fill")
            }
            Spacer()
            Button(action: onHome) {
                Image(systemName: "house.fill")
            }
            Spacer()
            Button(action: onTeams) {
                Image(systemName: "person.3.fill")
            }
            Spacer()
            Button(action: { showAlert = true }) {
                Image(systemName: "person.crop.circle.fill")
            }
        }
        .font(.system(size: 24))
        .padding()
        .foregroundStyle(Color.theme.textPrimary)
        .background(Color.theme.softPink)
        .limitedPreviewAlert(isPresented: $showAlert, feature: "This element")
    }
}