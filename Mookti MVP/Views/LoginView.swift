//
//  LoginView.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑07‑02.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {

    // MARK: - State
    @State private var isProcessing = false
    @State private var signInError: Error?
    @EnvironmentObject private var firebaseAuth: FirebaseAuthService

    var body: some View {
        VStack(spacing: 32) {

            // Branding
            VStack(spacing: 12) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                Text("education for the future")
                    .font(.custom("Lora-Regular", size: 16))
                    .foregroundColor(Color.theme.textPrimary)
                Text("yc preview")
                    .font(.custom("Lora-Regular", size: 16))
                    .foregroundColor(Color.theme.textPrimary)
            }
            .padding(.top, 40)

            Spacer()

            // Sign-in options
            VStack(spacing: 16) {
                // DEMO VERSION - Apple auth hidden, guest access only
                /*
                // Sign in with Apple
                SignInWithAppleButton(.signIn, onRequest: configureRequest, onCompletion: handleResult)
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .padding(.horizontal, 40)
                    .disabled(isProcessing)
                
                // OR divider
                HStack {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                    Text("OR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 40)
                */
                
                // Demo notice
                Text("DEMO PREVIEW")
                    .font(.custom("Inter-Regular", size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(Color.theme.accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.theme.accent, lineWidth: 2)
                    )
                
                // Continue as Guest button (primary for demo)
                Button(action: continueAsGuest) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Tap to Start Demo")
                            .font(.custom("Inter-Regular", size: 18))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.theme.accent)
                    .foregroundColor(Color.theme.background)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .disabled(isProcessing)
                .shadow(color: Color.theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
            }

            if isProcessing { 
                ProgressView()
                    .padding(.top, 8)
            }

            Spacer()
        }
        .background(Color.theme.background)
        .alert("Sign‑in failed", isPresented: .constant(signInError != nil)) {
            Button("OK", role: .cancel) { signInError = nil }
        } message: {
            Text(signInError?.localizedDescription ?? "Unknown error.")
        }
    }

    // MARK: - Guest Sign In
    
    private func continueAsGuest() {
        isProcessing = true
        Task {
            do {
                // Sign in anonymously with Firebase
                try await firebaseAuth.signInAnonymously()
                
                // Wait a moment for Firebase auth to complete
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Also mark as signed in for the app's auth service
                await MainActor.run {
                    AuthService.shared.adminLogin() // Using admin login as guest for now
                }
                
            } catch {
                await MainActor.run {
                    signInError = error
                    print("🔴 Guest Sign-In Error: \(error)")
                    print("🔴 Error Type: \(type(of: error))")
                    print("🔴 Error Details: \(error.localizedDescription)")
                }
            }
            await MainActor.run {
                isProcessing = false
            }
        }
    }

    // MARK: - ASAuthorization helpers

    private func configureRequest(_ req: ASAuthorizationAppleIDRequest) {
        req.requestedScopes = [.fullName, .email]
    }

    private func handleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            isProcessing = true
            Task {
                do {
                    try await AuthService.shared.handleAuthorization(auth)
                } catch {
                    signInError = error
                }
                isProcessing = false
            }

        case .failure(let error):
            signInError = error
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View { LoginView() }
}
#endif
