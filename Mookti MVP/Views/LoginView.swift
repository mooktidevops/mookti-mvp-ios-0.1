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
            VStack(alignment: .leading, spacing: 4) {
                Text("mookti")
                    .font(.largeTitle).bold()
                Text("education for the future")
                    .font(.headline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            Spacer()

            // Sign-in options
            VStack(spacing: 16) {
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
                
                // Continue as Guest button
                Button(action: continueAsGuest) {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Continue as Guest")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 40)
                .disabled(isProcessing)
            }

            if isProcessing { 
                ProgressView()
                    .padding(.top, 8)
            }

            Spacer()
        }
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
