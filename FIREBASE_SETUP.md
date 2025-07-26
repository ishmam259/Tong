# Firebase Setup Instructions for Tong Messenger

## Current Status
✅ **Build System**: Ready for Firebase integration  
✅ **Authentication Structure**: Implemented with fallback for development  
✅ **UI Components**: Login, signup, and profile screens created  
⚠️ **Firebase Configuration**: Using placeholder - needs real Firebase project  

## Quick Start (Development Mode)
The app currently works in development mode with placeholder Firebase configuration. You can:
- Build and run the app ✅
- Access the welcome screen ✅
- Navigate through authentication screens ✅
- Use messaging features without authentication ✅

## Production Setup (Firebase Integration)

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name (e.g., "tong-messenger")
4. Enable Google Analytics (optional)
5. Create project

### Step 2: Add Android App
1. In Firebase Console, click "Add app" → Android
2. Enter package name: `com.example.tong` (or change in `android/app/build.gradle.kts`)
3. Enter app nickname: "Tong Messenger"
4. Download `google-services.json`
5. Replace the placeholder file at `android/app/google-services.json`

### Step 3: Enable Authentication
1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" provider
5. Save changes

### Step 4: Setup Firestore Database
1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (or configure security rules)
4. Select location closest to your users
5. Done

### Step 5: Update Firebase Configuration
Replace the placeholder content in `lib/firebase_options.dart` with your actual Firebase configuration:

```dart
// Get this configuration from Firebase Console > Project Settings > General > Your apps
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-actual-api-key',
    appId: 'your-actual-app-id',
    messagingSenderId: 'your-actual-messaging-sender-id',
    projectId: 'your-actual-project-id',
    storageBucket: 'your-actual-project-id.appspot.com',
  );
}
```

### Step 6: Configure Firestore Security Rules
In Firebase Console > Firestore > Rules, update to:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read other users (for discovery)
    match /users/{userId} {
      allow read: if request.auth != null;
    }
  }
}
```

## Architecture Overview

### Authentication Flow
```
App Start → Firebase Init → Auth Check → Welcome/Home Screen
    ↓
Welcome → Login/Signup → Firebase Auth → Home Screen
    ↓
Home Screen → Profile/Settings → Logout → Welcome
```

### Data Storage
- **User Profiles**: Firebase Firestore (cloud sync)
- **Messages**: SQLite (local storage)
- **Settings**: SharedPreferences (local)
- **Bluetooth Devices**: SQLite (local)

### Error Handling
- Firebase initialization failures are gracefully handled
- Authentication errors show user-friendly messages
- Offline functionality maintained with local storage

## Testing the Integration

### 1. Development Testing (Current)
```bash
flutter run
# App launches in development mode
# Authentication screens are accessible
# Messaging works without auth
```

### 2. Production Testing (After Firebase Setup)
```bash
flutter run
# App initializes with real Firebase
# Authentication creates real user accounts
# User data syncs to Firestore
# Full authentication flow works
```

## Troubleshooting

### Build Issues
- Ensure Android SDK 35+ is installed
- NDK version 27.0.12077973 is required
- Google Services plugin is properly configured

### Firebase Issues
- Verify `google-services.json` is correctly placed
- Check Firebase Console for project configuration
- Ensure authentication is enabled
- Verify Firestore rules allow your operations

### Network Issues
- Firebase requires internet connection for initial setup
- Authentication works offline after initial login
- Local database maintains functionality without network

## Security Considerations

### Production Setup
- Use proper Firestore security rules
- Enable App Check for additional security
- Consider implementing email verification
- Use strong password requirements

### User Data
- Personal information is encrypted in Firestore
- Local SQLite database protects cached data
- Bluetooth communications use device pairing
- User sessions are securely managed

## Next Steps for Production

1. **Firebase Configuration**: Set up real Firebase project
2. **Testing**: Test authentication flow with real accounts
3. **Security**: Implement proper security rules
4. **Features**: Add profile picture upload, friend system
5. **Deployment**: Prepare for app store release

---

*The authentication system is now fully integrated and ready for production use with a real Firebase project!*
