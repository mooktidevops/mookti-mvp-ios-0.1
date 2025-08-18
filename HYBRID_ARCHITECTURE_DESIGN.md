# Hybrid Architecture Design

## Overview
This document outlines the hybrid architecture for Mookti MVP, balancing server-side control with client-side performance and offline capabilities.

## Architecture Principles

### 1. Server-Managed (Source of Truth)
- Learning path definitions and content structure
- Ellen's AI responses and tool use decisions
- User progress tracking and analytics
- Authentication and authorization
- Content updates and versioning

### 2. Client-Cached (Performance Layer)
- Current and nearby learning path nodes
- Recent conversation history (last 20 messages)
- User preferences and settings
- Offline message queue
- Prefetched content for next likely nodes

### 3. Progressive Enhancement
- Core reading functionality works offline
- Messages queue when offline, send when online
- Progress syncs when connection restored
- Graceful feature degradation

## API Contracts

### 1. Learning Path API

#### GET /api/learning-paths
```json
{
  "available_paths": [
    {
      "id": "workplace_success",
      "name": "Workplace Success",
      "description": "Cultural Intelligence Learning Path",
      "version": "1.0.0",
      "node_count": 200,
      "estimated_duration": "4 hours"
    }
  ]
}
```

#### GET /api/learning-paths/{path_id}/content
```json
{
  "path_id": "workplace_success",
  "version": "1.0.0",
  "start_node": "1",
  "nodes": {
    "1": {
      "id": "1",
      "type": "system",
      "content": "Welcome to the learning path...",
      "next_nodes": ["2"],
      "prefetch_depth": 3
    }
  }
}
```

#### GET /api/learning-paths/{path_id}/nodes/{node_id}/context
Returns nodes within a certain radius for prefetching
```json
{
  "center_node": "15",
  "radius": 3,
  "nodes": {
    "14": { ... },
    "15": { ... },
    "16": { ... },
    "15.1": { ... },
    "15.2": { ... }
  }
}
```

### 2. Progress Sync API

#### POST /api/progress/sync
```json
{
  "user_id": "firebase_uid",
  "path_id": "workplace_success",
  "current_node": "15",
  "completed_nodes": ["1", "2", "3", ...],
  "timestamp": "2024-01-15T10:30:00Z",
  "session_id": "uuid"
}
```

#### GET /api/progress/{user_id}/{path_id}
```json
{
  "current_node": "15",
  "completed_nodes": ["1", "2", "3", ...],
  "last_sync": "2024-01-15T10:30:00Z",
  "total_time_spent": 3600,
  "completion_percentage": 45
}
```

### 3. Message Queue API

#### POST /api/messages/queue
For batch uploading offline messages
```json
{
  "messages": [
    {
      "id": "local_uuid",
      "content": "User message",
      "timestamp": "2024-01-15T10:30:00Z",
      "node_context": "15",
      "local_order": 1
    }
  ]
}
```

## Client-Side Components

### 1. CacheManager
```swift
class CacheManager {
    // Manages local storage of learning path content
    func cacheNodes(_ nodes: [String: LearningNode])
    func getCachedNode(_ id: String) -> LearningNode?
    func prefetchContext(around nodeId: String, radius: Int)
    func clearCache()
    func getCacheSize() -> Int
}
```

### 2. OfflineQueue
```swift
class OfflineQueue {
    // Manages messages sent while offline
    func enqueue(_ message: Message)
    func processQueue() async
    func getQueuedMessages() -> [Message]
    func clearProcessed()
}
```

### 3. SyncManager
```swift
class SyncManager {
    // Handles bidirectional sync
    func syncProgress() async
    func syncMessages() async
    func resolveConflicts(_ local: Progress, _ remote: Progress) -> Progress
    func scheduleBackgroundSync()
}
```

### 4. NetworkMonitor
```swift
class NetworkMonitor: ObservableObject {
    @Published var isConnected: Bool
    @Published var connectionQuality: ConnectionQuality
    
    enum ConnectionQuality {
        case offline
        case poor      // 2G/Edge
        case moderate  // 3G
        case good      // 4G/LTE
        case excellent // 5G/WiFi
    }
}
```

## Implementation Phases

### Phase 1: Foundation (Current Sprint)
- [ ] Create learning path API endpoints
- [ ] Implement basic client-side caching
- [ ] Add network monitoring
- [ ] Create offline message queue

### Phase 2: Sync & Conflict Resolution
- [ ] Implement progress sync API
- [ ] Add conflict resolution logic
- [ ] Create background sync tasks
- [ ] Add retry mechanisms

### Phase 3: Optimization
- [ ] Implement intelligent prefetching
- [ ] Add cache size management
- [ ] Optimize sync frequency based on network
- [ ] Add compression for data transfer

### Phase 4: Analytics & Monitoring
- [ ] Add offline usage analytics
- [ ] Implement sync failure tracking
- [ ] Create performance metrics
- [ ] Add error reporting

## Cache Strategy

### What to Cache
1. **Always Cache**:
   - Current learning path structure
   - Nodes within radius 3 of current position
   - Last 20 conversation messages
   - User settings and preferences

2. **Opportunistically Cache**:
   - Popular branch paths based on analytics
   - Recently accessed content
   - Media thumbnails (not full media)

3. **Never Cache**:
   - Full media files (stream on demand)
   - Other users' data
   - Sensitive authentication tokens

### Cache Invalidation
- Version-based invalidation for learning paths
- TTL of 7 days for content
- LRU eviction when cache exceeds 50MB
- Manual refresh option for users

## Network State Handling

### Offline Mode
- Read cached content
- Queue new messages
- Track progress locally
- Show offline indicator
- Disable features requiring connectivity

### Poor Connection
- Prioritize text over media
- Increase timeout thresholds
- Batch API calls
- Show sync status
- Retry failed requests

### Good Connection
- Prefetch upcoming content
- Sync all queued data
- Download media assets
- Update analytics
- Check for content updates

## Error Handling

### Sync Conflicts
1. **Last-write-wins** for simple fields
2. **Union merge** for completed nodes lists
3. **Server priority** for current node position
4. **User notification** for major conflicts

### Network Failures
1. Exponential backoff for retries
2. Queue operations for later
3. Graceful degradation of features
4. Clear user communication

## Security Considerations

1. **Cached Data Encryption**: Use iOS Keychain for sensitive data
2. **Token Refresh**: Handle expired tokens gracefully
3. **Data Validation**: Verify synced data integrity
4. **Privacy**: Clear cache on logout
5. **Audit Trail**: Log all sync operations

## Success Metrics

1. **Offline Usage**: % of time app usable offline
2. **Sync Success Rate**: % of successful syncs
3. **Cache Hit Rate**: % of content served from cache
4. **Queue Processing Time**: Average time to process offline queue
5. **User Satisfaction**: Offline experience ratings