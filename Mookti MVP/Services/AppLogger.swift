import Foundation
import OSLog

// DEPRECATED: This class is maintained for backward compatibility only.
// All new logging should use FirebaseLogger directly.
// This implementation redirects all calls to Firebase for unified logging.
class AppLogger {
    static let shared = AppLogger()
    private let logger = Logger(subsystem: "com.mookti.mvp", category: "AppLogger")
    
    private init() {
        logger.warning("⚠️ AppLogger is deprecated. Please use FirebaseLogger directly.")
    }
    
    // MARK: - General Logging (Redirected to Firebase)
    
    func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.debug("🔍 \(message)")
        FirebaseLogger.shared.debug(message)
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.debug("🐛 \(message)")
        FirebaseLogger.shared.debug(message)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.info("ℹ️ \(message)")
        FirebaseLogger.shared.logEvent("app_log_info", parameters: ["message": message])
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.warning("⚠️ \(message)")
        FirebaseLogger.shared.logEvent("app_log_warning", parameters: ["message": message])
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.error("❌ \(message)")
        let error = NSError(domain: "AppLogger", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        FirebaseLogger.shared.logError(error, context: "AppLogger")
    }
    
    // MARK: - AI-Specific Logging (Redirected to Firebase)
    
    func logAIInteraction(type: String, model: String? = nil, input: String? = nil, output: String? = nil, duration: TimeInterval? = nil, error: Error? = nil) {
        // Redirect to FirebaseLogger
        FirebaseLogger.shared.logAIInteraction(
            service: "AppLogger",
            type: type,
            model: model,
            query: input,
            response: output,
            duration: duration,
            success: error == nil,
            error: error
        )
    }
    
    func logAIRequest(endpoint: String, parameters: [String: Any]? = nil) {
        // Log to Firebase
        if let requestId = parameters?["request_id"] as? String {
            FirebaseLogger.shared.logAIRequest(
                requestId: requestId,
                service: "AppLogger",
                endpoint: endpoint,
                model: parameters?["model"] as? String ?? "unknown",
                promptLength: parameters?["prompt_length"] as? Int ?? 0
            )
        } else {
            // Fallback for requests without ID
            FirebaseLogger.shared.logEvent("ai_request_legacy", parameters: [
                "endpoint": endpoint,
                "parameters": parameters?.description ?? "none"
            ])
        }
    }
    
    func logAIResponse(endpoint: String, statusCode: Int? = nil, responseTime: TimeInterval? = nil) {
        // Log to Firebase
        FirebaseLogger.shared.logEvent("ai_response_legacy", parameters: [
            "endpoint": endpoint,
            "status_code": statusCode ?? -1,
            "response_time_ms": Int((responseTime ?? 0) * 1000)
        ])
    }
    
    // MARK: - Export Functions (Deprecated)
    
    func exportLogs(completion: @escaping (URL?) -> Void) {
        // Logs are now in Firebase - return nil
        logger.warning("exportLogs is deprecated. Logs are now stored in Firebase.")
        completion(nil)
    }
    
    func exportAILogs(completion: @escaping (URL?) -> Void) {
        // Logs are now in Firebase - return nil
        logger.warning("exportAILogs is deprecated. Logs are now stored in Firebase.")
        completion(nil)
    }
    
    func clearLogs() {
        // No-op - logs are managed by Firebase
        logger.warning("clearLogs is deprecated. Logs are now managed by Firebase.")
    }
}