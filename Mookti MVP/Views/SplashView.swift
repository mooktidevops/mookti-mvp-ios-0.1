import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showLoginView = false
    var onComplete: () -> Void = {}
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.theme.accent, Color.theme.accent.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 60) {
                Spacer()
                
                // Logo and brand name
                Text("mookti")
                    .font(.custom("Nunito-Bold", size: 64))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: {
                        showLoginView = true
                        onComplete()
                    }) {
                        Text("Login")
                            .font(.custom("Inter-Medium", size: 18))
                            .foregroundColor(Color.theme.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white)
                            .cornerRadius(27)
                    }
                    .padding(.horizontal, 40)
                    
                    Button(action: {
                        showLoginView = true
                        onComplete()
                    }) {
                        Text("Sign up")
                            .font(.custom("Inter-Medium", size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .overlay(
                                RoundedRectangle(cornerRadius: 27)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 40)
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .offset(y: isAnimating ? 0 : 20)
                
                Spacer()
                    .frame(height: 100)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}