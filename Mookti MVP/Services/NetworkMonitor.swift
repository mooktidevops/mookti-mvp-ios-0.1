//
//  NetworkMonitor.swift
//  Mookti MVP
//
//  Monitors network connectivity and quality for graceful degradation
//

import Foundation
import Network
import SwiftUI

@MainActor
final class NetworkMonitor: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isConnected = true
    @Published private(set) var connectionQuality: ConnectionQuality = .unknown
    @Published private(set) var connectionType: ConnectionType = .unknown
    @Published private(set) var isExpensive = false
    @Published private(set) var isConstrained = false
    
    // MARK: - Types
    
    enum ConnectionQuality: String, CaseIterable {
        case offline = "Offline"
        case poor = "Poor"         // High latency, low bandwidth
        case moderate = "Moderate" // Acceptable for basic features
        case good = "Good"         // Good for most features
        case excellent = "Excellent" // Full features enabled
        case unknown = "Unknown"
        
        var color: Color {
            switch self {
            case .offline: return .red
            case .poor: return .orange
            case .moderate: return .yellow
            case .good: return .green
            case .excellent: return .green
            case .unknown: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .offline: return "wifi.slash"
            case .poor: return "wifi.exclamationmark"
            case .moderate: return "wifi"
            case .good: return "wifi"
            case .excellent: return "wifi"
            case .unknown: return "questionmark.circle"
            }
        }
    }
    
    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case wired = "Wired"
        case loopback = "Loopback"
        case other = "Other"
        case unknown = "Unknown"
    }
    
    // MARK: - Private Properties
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.mookti.networkmonitor")
    private var pingTimer: Timer?
    private var recentLatencies: [TimeInterval] = []
    private let maxLatencySamples = 5
    
    // MARK: - Initialization
    
    init() {
        monitor = NWPathMonitor()
        startMonitoring()
        setupLatencyMonitoring()
    }
    
    deinit {
        monitor.cancel()
        pingTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Check if a feature should be enabled based on connection quality
    func shouldEnableFeature(_ feature: Feature) -> Bool {
        switch feature {
        case .aiChat:
            return isConnected
        case .mediaDownload:
            return connectionQuality >= .moderate && !isExpensive
        case .backgroundSync:
            return connectionQuality >= .good && !isConstrained
        case .prefetch:
            return connectionQuality >= .good && !isExpensive && !isConstrained
        case .streaming:
            return connectionQuality >= .moderate
        case .offlineMode:
            return true // Always available
        }
    }
    
    /// Get recommended settings based on connection
    func getRecommendedSettings() -> RecommendedSettings {
        switch connectionQuality {
        case .offline:
            return RecommendedSettings(
                enablePrefetch: false,
                enableMediaAutoDownload: false,
                syncFrequency: .never,
                messageQueueing: true,
                cacheSize: .maximum
            )
        case .poor:
            return RecommendedSettings(
                enablePrefetch: false,
                enableMediaAutoDownload: false,
                syncFrequency: .manual,
                messageQueueing: true,
                cacheSize: .large
            )
        case .moderate:
            return RecommendedSettings(
                enablePrefetch: !isExpensive,
                enableMediaAutoDownload: false,
                syncFrequency: .occasional,
                messageQueueing: false,
                cacheSize: .medium
            )
        case .good, .excellent:
            return RecommendedSettings(
                enablePrefetch: !isExpensive,
                enableMediaAutoDownload: !isExpensive,
                syncFrequency: .frequent,
                messageQueueing: false,
                cacheSize: .small
            )
        case .unknown:
            return RecommendedSettings(
                enablePrefetch: false,
                enableMediaAutoDownload: false,
                syncFrequency: .occasional,
                messageQueueing: true,
                cacheSize: .medium
            )
        }
    }
    
    // MARK: - Types
    
    enum Feature {
        case aiChat
        case mediaDownload
        case backgroundSync
        case prefetch
        case streaming
        case offlineMode
    }
    
    struct RecommendedSettings {
        let enablePrefetch: Bool
        let enableMediaAutoDownload: Bool
        let syncFrequency: SyncFrequency
        let messageQueueing: Bool
        let cacheSize: CacheSize
        
        enum SyncFrequency {
            case never
            case manual
            case occasional // Every 5 minutes
            case frequent   // Every 1 minute
        }
        
        enum CacheSize {
            case small   // 10MB
            case medium  // 25MB
            case large   // 50MB
            case maximum // 100MB
            
            var bytes: Int {
                switch self {
                case .small: return 10 * 1024 * 1024
                case .medium: return 25 * 1024 * 1024
                case .large: return 50 * 1024 * 1024
                case .maximum: return 100 * 1024 * 1024
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.isConnected = path.status == .satisfied
                self.isExpensive = path.isExpensive
                self.isConstrained = path.isConstrained
                
                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wired
                } else if path.usesInterfaceType(.loopback) {
                    self.connectionType = .loopback
                } else if path.usesInterfaceType(.other) {
                    self.connectionType = .other
                } else {
                    self.connectionType = .unknown
                }
                
                // Update connection quality based on type and constraints
                self.updateConnectionQuality(path: path)
                
                print("🌐 NetworkMonitor: Connected: \(self.isConnected), Type: \(self.connectionType.rawValue), Quality: \(self.connectionQuality.rawValue)")
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func updateConnectionQuality(path: NWPath) {
        guard path.status == .satisfied else {
            connectionQuality = .offline
            return
        }
        
        // Base quality on connection type
        var quality: ConnectionQuality = .unknown
        
        switch connectionType {
        case .wifi, .wired:
            quality = .excellent
        case .cellular:
            quality = .good
        case .loopback:
            quality = .excellent
        case .other, .unknown:
            quality = .moderate
        }
        
        // Adjust for constraints
        if isConstrained {
            quality = downgradeQuality(quality)
        }
        
        if isExpensive {
            quality = downgradeQuality(quality)
        }
        
        // Consider latency if available
        if !recentLatencies.isEmpty {
            let avgLatency = recentLatencies.reduce(0, +) / Double(recentLatencies.count)
            
            if avgLatency > 1.0 {
                quality = .poor
            } else if avgLatency > 0.5 {
                quality = downgradeQuality(quality)
            }
        }
        
        connectionQuality = quality
    }
    
    private func downgradeQuality(_ quality: ConnectionQuality) -> ConnectionQuality {
        switch quality {
        case .excellent: return .good
        case .good: return .moderate
        case .moderate: return .poor
        case .poor, .offline, .unknown: return quality
        }
    }
    
    private func setupLatencyMonitoring() {
        // Measure latency periodically
        pingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task { @MainActor in
                await self.measureLatency()
            }
        }
    }
    
    private func measureLatency() async {
        guard isConnected else { return }
        
        let startTime = Date()
        
        do {
            // Make a lightweight API call to measure latency
            let url = URL(string: "https://api.anthropic.com/health")!
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                let latency = Date().timeIntervalSince(startTime)
                
                recentLatencies.append(latency)
                if recentLatencies.count > maxLatencySamples {
                    recentLatencies.removeFirst()
                }
                
                // Update quality based on new latency
                updateConnectionQuality(path: monitor.currentPath)
            }
        } catch {
            // Network error, assume poor quality
            if isConnected {
                connectionQuality = .poor
            }
        }
    }
}

// MARK: - Comparable Extension

extension NetworkMonitor.ConnectionQuality: Comparable {
    static func < (lhs: NetworkMonitor.ConnectionQuality, rhs: NetworkMonitor.ConnectionQuality) -> Bool {
        let order: [NetworkMonitor.ConnectionQuality] = [.offline, .poor, .moderate, .good, .excellent, .unknown]
        let lhsIndex = order.firstIndex(of: lhs) ?? 5
        let rhsIndex = order.firstIndex(of: rhs) ?? 5
        return lhsIndex < rhsIndex
    }
}