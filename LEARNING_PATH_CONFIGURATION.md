# Learning Path Configuration

## Overview
The Ellen chat interface now supports optional pre-written learning paths through a configurable `learningPath` field in `SettingsService`.

## Default Behavior
- When `learningPath` is `nil` (default), Ellen starts as a tutor without any pre-written content
- Users can immediately begin chatting with Ellen about any topic

## Loading Pre-Written Content
- When `learningPath` is set to a value (e.g., `"workplace_success"`), Ellen will load the associated pre-written learning path
- The system will look for a start node (currently node "1" by convention) and begin content delivery

## Configuration

### In Code
```swift
// To enable Workplace Success learning path
settings.learningPath = "workplace_success"

// To disable pre-written content (default)
settings.learningPath = nil
```

### Current Learning Paths
- `nil` - No pre-written content (default)
- `"workplace_success"` - Workplace Success / Cultural Intelligence learning path

## Implementation Details

### Key Files Modified
1. **SettingsService.swift**
   - Added `@AppStorage("learningPath") var learningPath: String? = nil`
   - Persists the learning path preference

2. **EllenViewModel.swift**
   - Modified `loadInitialContent()` to check `learningPath` setting
   - Only loads pre-written content when `learningPath` is set
   - Added `getStartNodeForLearningPath()` for future extensibility

### Adding New Learning Paths
To add a new learning path:
1. Create the CSV content files in `Resources/ModuleCSVs/`
2. Update `ContentGraphService` to load the new modules
3. Set `learningPath` to the new path identifier
4. Optionally update `getStartNodeForLearningPath()` if the path starts at a different node

## Testing
- With `learningPath = nil`: Ellen should start without any pre-written messages
- With `learningPath = "workplace_success"`: Ellen should load the Workplace Success content starting from node 1