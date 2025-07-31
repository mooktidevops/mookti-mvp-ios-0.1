//
//  FirebaseAuthService.swift
//  Mookti MVP
//
//  Firebase Authentication Service for securing API calls
//

import Foundation
import FirebaseAuth
import OSLog

@MainActor
class FirebaseAuthService: ObservableObject {
    static let shared = FirebaseAuthService()
    
    private let logger = Logger(subsystem: "com.mookti.mvp", category: "FirebaseAuth")
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                
                if let user = user {
                    self?.logger.info("🔐 User authenticated: \(user.uid)")
                } else {
                    self?.logger.info("🔓 User signed out")
                }
            }
        }
    }
    
    /// Sign in anonymously for MVP
    func signInAnonymously() async throws {
        logger.info("🔐 Attempting anonymous sign in...")
        
        do {
            // Check if already signed in
            if let currentUser = Auth.auth().currentUser {
                logger.info("✅ Already signed in as: \(currentUser.uid)")
                return
            }
            
            let result = try await Auth.auth().signInAnonymously()
            logger.info("✅ Anonymous sign in successful: \(result.user.uid)")
            
            // Update published state
            await MainActor.run {
                self.currentUser = result.user
                self.isAuthenticated = true
            }
            
            // Log to Firebase Analytics
            FirebaseLogger.shared.logEvent("anonymous_sign_in", parameters: [
                "user_id": result.user.uid
            ])
        } catch {
            logger.error("❌ Anonymous sign in failed: \(error.localizedDescription)")
            
            // Check for specific error types
            let nsError = error as NSError
            print("🔴 Firebase Auth Error Domain: \(nsError.domain)")
            print("🔴 Firebase Auth Error Code: \(nsError.code)")
            print("🔴 Firebase Auth Error UserInfo: \(nsError.userInfo)")
            
            if nsError.domain == "FIRAuthErrorDomain" {
                logger.error("❌ Auth Error Code: \(nsError.code)")
                logger.error("❌ Auth Error Details: \(nsError.userInfo)")
                
                // Check for specific error codes
                switch nsError.code {
                case 17020:
                    print("🔴 Network error - check internet connection")
                case 17999:
                    print("🔴 Internal error - check Firebase configuration")
                default:
                    print("🔴 Unknown auth error code: \(nsError.code)")
                }
            }
            
            throw error
        }
    }
    
    /// Get current user's ID token for API calls
    func getIDToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            logger.error("❌ No authenticated user")
            throw AuthError.notAuthenticated
        }
        
        do {
            let token = try await user.getIDToken()
            logger.debug("🎫 Retrieved ID token for user: \(user.uid)")
            return token
        } catch {
            logger.error("❌ Failed to get ID token: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Sign out the current user
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            logger.info("👋 User signed out successfully")
        } catch {
            logger.error("❌ Sign out failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Check if user is signed in
    var isSignedIn: Bool {
        Auth.auth().currentUser != nil
    }
}

enum AuthError: LocalizedError {
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated. Please sign in."
        }
    }
}