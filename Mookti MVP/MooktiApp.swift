//
//  MooktiApp.swift
//  Mookti
//
//  ⚠️ PRODUCTION TODO: Enable Firebase In-App Messaging
//  Currently disabled to prevent 403 errors during development
//  See AppDelegate.application(...) method for details
//

import SwiftUI
import SwiftData
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        print("✅ Firebase configured successfully")
        
        // TODO: PRODUCTION - Enable Firebase In-App Messaging
        // 1. Enable API at: https://console.developers.google.com/apis/api/firebaseinappmessaging.googleapis.com/overview?project=823142362360
        // 2. Remove the messageDisplaySuppressed line below
        // 3. Configure campaigns in Firebase Console for:
        //    - Welcome messages for new users
        //    - Module completion celebrations
        //    - Learning streak reminders
        //    - Feature announcements
        // TEMPORARY: Disable to prevent 403 errors during development
        if let inAppMessaging = NSClassFromString("FIRInAppMessaging") {
            let selector = NSSelectorFromString("inAppMessaging")
            if let instance = (inAppMessaging as AnyObject).perform(selector)?.takeUnretainedValue() {
                instance.setValue(true, forKey: "messageDisplaySuppressed")
                print("📵 Firebase In-App Messaging temporarily disabled - Enable for production!")
            }
        }
        
        return true
    }
}

@main
struct MooktiApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // ──────────────────────────────────────────────────────────────
    // Global state objects
    // ──────────────────────────────────────────────────────────────
    @StateObject private var contentGraph      = ContentGraphService()
    // @StateObject private var modelAvailability = ModelAvailabilityManager() // DEPRECATED: Using cloud-only AI
    @StateObject private var userProgress      = UserProgressService()
    @StateObject private var settingsService   = SettingsService()
    @StateObject private var conversationStore: ConversationStore  // ← NEW
    // @StateObject private var ragPipeline = RAGPipeline.shared // DEPRECATED: Using cloud-only RAG
    @StateObject private var firebaseAuth = FirebaseAuthService.shared

    // SwiftData container
    private let modelContainer: ModelContainer

    init() {
        do {
            // Create container with both models
            let container = try ModelContainer(for: StoredMessage.self,
                                             Conversation.self)  // ← NEW
            
            // Initialize conversation store with the main context
            _conversationStore = StateObject(
                wrappedValue: ConversationStore(modelContext: container.mainContext)
            )
            
            modelContainer = container
        } catch {
            fatalError("💥 Failed to create SwiftData container: \(error)")
        }
    }

    // ──────────────────────────────────────────────────────────────
    // Scene graph
    // ──────────────────────────────────────────────────────────────
    var body: some Scene {
        WindowGroup {
            Group {
                if contentGraph.nodes.count > 0 {
                    RootNavigationView()
                        .environmentObject(contentGraph)
                        // .environmentObject(modelAvailability) // DEPRECATED: Using cloud-only AI
                        .environmentObject(userProgress)
                        .environmentObject(settingsService)
                        .environmentObject(conversationStore)      // ← NEW
                        // .environmentObject(ragPipeline) // DEPRECATED: Using cloud-only RAG
                        .environmentObject(firebaseAuth)
                } else {
                    ProgressView("Preparing content…")
                        .task {
                            print("🔧 MooktiApp: Starting content preparation...")
                            
                            // Wait until nodes are loaded with timeout
                            let maxWaitTime = 10.0 // 10 seconds timeout
                            let startTime = Date()
                            
                            while contentGraph.nodes.isEmpty && Date().timeIntervalSince(startTime) < maxWaitTime {
                                let elapsed = Date().timeIntervalSince(startTime)
                                if Int(elapsed) % 2 == 0 && elapsed > 1 {
                                    print("⏳ MooktiApp: Still waiting for content graph... (\(String(format: "%.1f", elapsed))s)")
                                }
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                            }
                            
                            let loadDuration = Date().timeIntervalSince(startTime)
                            
                            if contentGraph.nodes.isEmpty {
                                print("⚠️ MooktiApp: Timeout waiting for content graph after \(String(format: "%.1f", loadDuration))s. Creating with fallback content.")
                            } else {
                                print("✅ MooktiApp: Content graph loaded in \(String(format: "%.2f", loadDuration))s with \(contentGraph.nodes.count) nodes")
                            }
                            
                            print("🔧 MooktiApp: Cloud AI system ready")
                            // DEPRECATED: Local vector store loading removed - all RAG handled by Vercel/Pinecone
                            
                            print("✅ MooktiApp: App initialization complete")
                            
                            // Sign in anonymously if not already authenticated
                            if !firebaseAuth.isSignedIn {
                                do {
                                    print("🔐 MooktiApp: Signing in anonymously...")
                                    try await firebaseAuth.signInAnonymously()
                                    print("✅ MooktiApp: Anonymous sign-in successful")
                                } catch {
                                    print("⚠️ MooktiApp: Anonymous sign-in failed: \(error)")
                                    // App continues without auth - will use API key if available
                                }
                            }
                        }
                }
            }
            .modelContainer(modelContainer)
        }
    }
}
