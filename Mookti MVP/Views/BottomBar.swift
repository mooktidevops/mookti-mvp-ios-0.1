import SwiftUI

struct BottomBar: View {
    var onEllen: () -> Void = {}
    var onHome: () -> Void = {}
    var onTeams: () -> Void = {}
    @State private var showAlert = false
    @State private var glowAnimation = false

    var body: some View {
        HStack {
            Button(action: onEllen) {
                ZStack {
                    // Glow effect for demo
                    Circle()
                        .fill(Color.theme.accent.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .blur(radius: glowAnimation ? 8 : 4)
                        .scaleEffect(glowAnimation ? 1.3 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: glowAnimation
                        )
                    
                    Image(systemName: "bubble.left.fill")
                        .foregroundColor(Color.theme.accent)
                        .font(.system(size: 24))
                }
            }
            .onAppear {
                glowAnimation = true
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