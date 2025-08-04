# Mookti iOS App - AI Agent Codebase Guide

## Overview
Mookti is an iOS learning platform that delivers educational content through an AI-powered chat interface. The app features a character named Ellen who guides users through learning modules with interactive conversations, multimedia content, and progress tracking.

## Technology Stack
- **Platform**: iOS (SwiftUI)
- **Minimum iOS Version**: iOS 17.0+
- **Language**: Swift 5.9+
- **Architecture**: MVVM with SwiftUI
- **Data Persistence**: SwiftData
- **Backend Services**: Firebase (Auth, Analytics, Firestore)
- **AI Integration**: Claude API via Vercel Edge Functions
- **Package Management**: Swift Package Manager

## Project Structure

```
Mookti MVP/
├── Mookti MVP.xcodeproj/     # Xcode project configuration
├── Mookti MVP/                # Main app source code
│   ├── MooktiApp.swift        # App entry point & Firebase setup
│   ├── ContentView.swift      # Root content view
│   ├── Models/                # Data models and view models
│   │   ├── EllenViewModel.swift     # Main chat VM with AI interaction
│   │   ├── HomeViewModel.swift      # Home screen state management
│   │   ├── SettingsViewModel.swift  # Settings management
│   │   ├── Conversation.swift       # Chat conversation model
│   │   ├── Message.swift           # Individual message model
│   │   ├── StoredMessage.swift     # SwiftData persistence model
│   │   ├── LearningNode.swift      # Content graph nodes
│   │   ├── ContentMetadata.swift   # Module metadata
│   │   ├── CardCarouselPayload.swift # Carousel content model
│   │   └── MediaPayload.swift      # Media attachment model
│   ├── Views/                 # SwiftUI views
│   │   ├── EllenChatView.swift     # Main chat interface
│   │   ├── HomeView.swift          # Home/dashboard screen
│   │   ├── LoginView.swift         # Authentication screen
│   │   ├── SettingsView.swift      # App settings
│   │   ├── CardCarouselView.swift  # Swipeable card carousel
│   │   ├── BubbleView.swift        # Chat message bubbles
│   │   ├── MediaThumbnailView.swift # Media preview component
│   │   ├── TypingIndicatorView.swift # Chat typing animation
│   │   ├── ConversationHistoryView.swift # Past conversations list
│   │   └── RootNavigationView.swift # Main navigation controller
│   ├── Services/              # Business logic & external integrations
│   │   ├── EllenAIService.swift    # AI chat orchestration
│   │   ├── CloudAIService.swift    # Vercel/Claude API client
│   │   ├── FirebaseAuthService.swift # Firebase authentication
│   │   ├── ContentGraphService.swift # Learning content management
│   │   ├── ConversationStore.swift  # Chat history persistence
│   │   ├── UserProgressService.swift # Learning progress tracking
│   │   ├── SettingsService.swift    # User preferences
│   │   ├── AIInteractionLogger.swift # AI usage analytics
│   │   └── AppLogger.swift         # General logging utilities
│   ├── Resources/             # Static assets & content
│   │   ├── ModuleCSVs/        # Learning module definitions
│   │   ├── StudyGuides/       # PDF study materials
│   │   └── Media/             # Images, videos, etc.
│   ├── Assets.xcassets/       # App icons & colors
│   └── GoogleService-Info.plist # Firebase configuration
├── Mookti MVPTests/           # Unit tests
└── Mookti MVPUITests/         # UI tests
```

## Key Components

### Core Services

#### EllenAIService
- Main AI orchestration service
- Manages conversation flow and content delivery
- Handles learning node navigation
- Integrates with CloudAIService for AI responses
- Location: `Services/EllenAIService.swift`

#### CloudAIService  
- Vercel Edge Function API client
- Sends requests to Claude AI backend
- Manages API authentication and rate limiting
- Location: `Services/CloudAIService.swift`

#### ContentGraphService
- Loads and manages learning modules from CSV files
- Builds directed graph of learning content
- Tracks module progression
- Location: `Services/ContentGraphService.swift`

### Data Models

#### LearningNode
- Represents a single piece of learning content
- Types: Text, Question, Media, CardCarousel, Branch
- Contains content, metadata, and graph connections
- Location: `Models/LearningNode.swift`

#### Message
- Chat message model with role (user/assistant/system)
- Supports text, media, and carousel payloads
- Includes timestamps and metadata
- Location: `Models/Message.swift`

### Views

#### EllenChatView
- Primary chat interface
- Displays messages with appropriate UI components
- Handles user input and interactions
- Supports pull-to-continue gesture
- Location: `Views/EllenChatView.swift`

#### CardCarouselView
- Swipeable card interface for structured content
- Navigation arrows for discoverability
- Supports markdown formatting
- Location: `Views/CardCarouselView.swift`

## Build Instructions

### Prerequisites
1. **Xcode 15.0+** installed (full Xcode, not just Command Line Tools)
2. **macOS Sonoma 14.0+** or later
3. **Active Apple Developer account** (for device testing)
4. **Swift Package Manager** (integrated with Xcode)

### Setup Steps

1. **Clone the repository**
```bash
git clone https://github.com/mooktidevops/mookti-mvp-ios.git
cd "Mookti MVP"
```

2. **Open in Xcode**
```bash
open "Mookti MVP.xcodeproj"
```

3. **Configure Firebase**
- Ensure `GoogleService-Info.plist` is present in the project
- Firebase project should have Authentication and Firestore enabled

4. **Install Dependencies**
- Xcode will automatically resolve Swift Package Manager dependencies
- Wait for package resolution to complete

5. **Select Target Device**
- Choose a simulator (iPhone 15 recommended) or connected device
- Ensure deployment target matches your device iOS version

### Building the App

#### Via Xcode GUI
1. Select the "Mookti MVP" scheme
2. Choose your target device/simulator
3. Press `Cmd+B` to build or `Cmd+R` to build and run

#### Via Command Line
```bash
# Build for simulator
xcodebuild -project "Mookti MVP.xcodeproj" \
           -scheme "Mookti MVP" \
           -destination "platform=iOS Simulator,name=iPhone 15" \
           build

# Build for device (requires provisioning)
xcodebuild -project "Mookti MVP.xcodeproj" \
           -scheme "Mookti MVP" \
           -destination "generic/platform=iOS" \
           build
```

## Testing Instructions

### Running Tests

#### Unit Tests
```bash
# Run unit tests
xcodebuild test -project "Mookti MVP.xcodeproj" \
                -scheme "Mookti MVP" \
                -destination "platform=iOS Simulator,name=iPhone 15" \
                -only-testing:"Mookti MVPTests"
```

#### UI Tests
```bash
# Run UI tests
xcodebuild test -project "Mookti MVP.xcodeproj" \
                -scheme "Mookti MVP" \
                -destination "platform=iOS Simulator,name=iPhone 15" \
                -only-testing:"Mookti MVPUITests"
```

#### All Tests
```bash
# Run all tests
xcodebuild test -project "Mookti MVP.xcodeproj" \
                -scheme "Mookti MVP" \
                -destination "platform=iOS Simulator,name=iPhone 15"
```

### Manual Testing Checklist

1. **Authentication Flow**
   - Launch app → Should auto-sign in anonymously
   - Check Firebase console for new anonymous user

2. **Home Screen**
   - Verify module cards display correctly
   - Test navigation to Ellen chat
   - Check progress indicators

3. **Ellen Chat**
   - Send a message → Should receive AI response
   - Test card carousel navigation (arrows + swipe)
   - Verify media attachments display
   - Test pull-to-continue gesture
   - Check conversation persistence

4. **Settings**
   - Toggle preferences
   - Verify changes persist

## Common Development Tasks

### Adding a New Learning Module
1. Create CSV file in `Resources/ModuleCSVs/`
2. Follow format in `Templates/module_csv_template_guide.csv`
3. Update `ContentGraphService` to load new module

### Modifying AI Behavior
1. Edit prompt templates in `EllenAIService.swift`
2. Adjust conversation flow logic
3. Update `CloudAIService` for API changes

### Updating UI Components
1. Views are in `Views/` directory
2. Follow SwiftUI best practices
3. Test on multiple device sizes

### Debugging Tips
- Enable verbose logging in `AppLogger.swift`
- Check Xcode console for print statements
- Use Firebase console for backend issues
- Network debugging via Charles Proxy

## API Integration

### Vercel Edge Functions
- Base URL: Configured in `CloudAIService`
- Endpoints:
  - `/api/chat` - Main AI chat endpoint
  - `/api/claude` - Direct Claude API access
- Authentication: Firebase Auth tokens

### Firebase Services
- **Authentication**: Anonymous and email/password
- **Firestore**: User progress and preferences
- **Analytics**: User engagement tracking
- **Crashlytics**: Error reporting

## Environment Variables

Required environment configuration:
- `FIREBASE_PROJECT_ID`: Firebase project identifier
- `API_BASE_URL`: Vercel Edge Function URL
- `CLAUDE_API_VERSION`: Claude API version string

## Troubleshooting

### Common Issues

1. **Build Fails - Missing Dependencies**
   - Clean build folder: `Cmd+Shift+K`
   - Reset package caches: File → Packages → Reset Package Caches

2. **Firebase Connection Issues**
   - Verify `GoogleService-Info.plist` is correct
   - Check Firebase project settings
   - Ensure bundle ID matches Firebase config

3. **AI Responses Not Working**
   - Check Vercel function logs
   - Verify API keys are configured
   - Test network connectivity

4. **Simulator Performance**
   - Use Release configuration for better performance
   - Disable slow animations: Debug → Slow Animations

## Code Style Guidelines

- Use Swift 5.9+ features appropriately
- Follow SwiftUI declarative patterns
- Implement MVVM architecture
- Add meaningful comments for complex logic
- Use `// MARK: -` for section organization
- Prefer `@StateObject` for view models
- Use `async/await` for asynchronous operations

## Contact & Support

- **Repository**: https://github.com/mooktidevops/mookti-mvp-ios
- **Issue Tracking**: GitHub Issues
- **Documentation**: This file and inline code comments

## Recent Changes

- Enhanced `CardCarouselView` with navigation arrows and increased height
- Added pull-to-continue gesture in `EllenChatView`
- Migrated from local AI to cloud-based Claude API
- Implemented conversation history with SwiftData

---

*Last Updated: 2025-08-04*