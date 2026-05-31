# ShortVideo - iOS App

## Setup

### Prerequisites
- Xcode 16+ (macOS)
- Node.js 22+
- Firebase CLI (`npm install -g firebase-tools`)
- CocoaPods or Swift Package Manager

### 1. Firebase Setup
1. Create a Firebase project at https://console.firebase.google.com
2. Enable: Authentication (Email/Password + Apple), Firestore, Storage, Cloud Functions, Cloud Messaging
3. Download `GoogleService-Info.plist` → place in `ios/DouyinClone/DouyinClone/Resources/`
4. `cd backend && npm install && firebase deploy`

### 2. iOS Setup
1. Open `ios/DouyinClone.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build & Run on iOS 17+ device

### 3. Local Development
```bash
cd backend/functions
npm install
npm run serve  # Starts Firebase emulators
```

## Project Structure

```
ios/DouyinClone/DouyinClone/
├── App/              # Entry point, AppDelegate
├── Models/           # Data models (User, Video, Comment, etc.)
├── ViewModels/       # MVVM ViewModels
├── Views/            # SwiftUI views, organized by feature
│   ├── Core/         # MainTabView, ContentView
│   ├── Auth/         # Login, SignUp
│   ├── Feed/         # Video feed (Phase 3)
│   ├── Record/       # Camera recording (Phase 2)
│   ├── Upload/       # Upload progress (Phase 2)
│   ├── Profile/      # User profile (Phase 3)
│   ├── Social/       # Comments, friends, notifications
│   ├── Discover/     # Search, trending
│   └── Components/   # Reusable components
├── Services/         # Firebase wrappers
├── Utilities/        # Helpers, extensions
└── Resources/        # Info.plist, assets

backend/
├── functions/src/    # Cloud Functions
├── firestore.rules   # Firestore security rules
├── storage.rules     # Storage security rules
└── firebase.json     # Firebase config
```

## Phases

- [x] Phase 1: Skeleton + Auth (current)
- [ ] Phase 2: Record + Upload + Playback
- [ ] Phase 3: Feed + Social Core
- [ ] Phase 4: Social Graph + Discovery
- [ ] Phase 5: Polish + Performance
