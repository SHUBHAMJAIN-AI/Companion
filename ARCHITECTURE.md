# Health Companion - Technical Architecture Documentation

## Table of Contents
- [Overview](#overview)
- [Architecture Pattern](#architecture-pattern)
- [Spezi Framework](#spezi-framework)
- [Cloud Infrastructure](#cloud-infrastructure)
- [Data Flow](#data-flow)
- [Security Architecture](#security-architecture)
- [Deployment Guide](#deployment-guide)
- [CI/CD with GitHub](#cicd-with-github)

---

## Overview

Health Companion is a SwiftUI-based iOS application built on Stanford's Spezi framework, designed for medical professionals. The application follows a modular, service-oriented architecture with cloud-based data persistence and AI integration.

### Technology Stack Summary

| Layer | Technology |
|-------|-----------|
| **Frontend** | SwiftUI (iOS 17.0+) |
| **Framework** | Stanford Spezi |
| **Language** | Swift 5.9+ |
| **Authentication** | Firebase Auth |
| **Database** | Cloud Firestore |
| **Storage** | AWS S3 |
| **AI Services** | OpenAI GPT-4, AssemblyAI |
| **Package Manager** | Swift Package Manager (SPM) |
| **Version Control** | Git/GitHub |

---

## Architecture Pattern

### 1. Clean Architecture Layers

The application follows a **modular clean architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (SwiftUI Views, ViewModels, UI Components)             │
├─────────────────────────────────────────────────────────┤
│                      Domain Layer                        │
│  (Business Logic, Use Cases, Spezi Modules)             │
├─────────────────────────────────────────────────────────┤
│                       Data Layer                         │
│  (Services, Repositories, Network, Storage)             │
├─────────────────────────────────────────────────────────┤
│                   Infrastructure Layer                   │
│  (Firebase, AWS, APIs, Third-party SDKs)                │
└─────────────────────────────────────────────────────────┘
```

### 2. Architectural Components

#### **Presentation Layer**
- **Views**: SwiftUI views for UI rendering
- **Navigation**: Role-based navigation flows
- **State Management**: `@StateObject`, `@EnvironmentObject`, `@Observable`

#### **Domain Layer**
- **Spezi Modules**: Encapsulated feature modules
- **Business Logic**: Medical workflows, user roles, permissions
- **Models**: Data models and entities

#### **Data Layer**
- **Services**: Custom services (OpenAI, AWS S3, AssemblyAI, Firestore)
- **Repositories**: Data access abstractions
- **Caching**: Local caching strategies

#### **Infrastructure Layer**
- **Firebase SDK**: Authentication, Firestore, Storage
- **AWS SDK**: S3 integration
- **Third-party APIs**: OpenAI, AssemblyAI

---

## Spezi Framework

### What is Spezi?

**Spezi** is Stanford's open-source framework for building digital health applications. It provides modular, reusable components that handle common healthcare app requirements.

### Core Spezi Architecture

```swift
@main
struct TemplateApplication: App {
    @ApplicationDelegateAdaptor(TemplateApplicationDelegate.self)
    var appDelegate

    var body: some Scene {
        WindowGroup {
            HomeView()
                .spezi(appDelegate)  // Injects Spezi modules
        }
    }
}
```

### Spezi Modules Used

#### 1. **SpeziAccount**
- **Purpose**: User authentication and account management
- **Features**:
  - Email/password authentication
  - User profile management
  - Account setup flows
  - Password recovery
  - Role-based user types (Doctor, Resident, Admin)

```swift
import SpeziAccount

AccountConfiguration {
    // Custom account setup
    CustomAccountSetup()
    ForgotPasswordView()
}
```

#### 2. **SpeziFirestore**
- **Purpose**: Cloud Firestore integration
- **Features**:
  - Real-time data synchronization
  - Offline persistence
  - Query management
  - Document modeling

```swift
import SpeziFirestore

@Firestore var firestore
firestore.collection("users").document(userId)
```

#### 3. **SpeziFirebaseStorage**
- **Purpose**: Firebase Storage for metadata
- **Features**:
  - File metadata storage
  - Document references
  - User-specific storage paths

#### 4. **SpeziOnboarding**
- **Purpose**: User onboarding flows
- **Features**:
  - Welcome screens
  - Role selection
  - Permissions requests
  - Sequential onboarding steps

```swift
OnboardingStack {
    Welcome()
    RoleSelectionView()
    AccountOnboarding()
    PermissionsView()
}
```

#### 5. **SpeziContact**
- **Purpose**: Contact management
- **Features**:
  - Contact directory
  - Communication actions (call, email)
  - Role-based contact access

#### 6. **SpeziViews**
- **Purpose**: Reusable UI components
- **Features**:
  - Common SwiftUI views
  - Layout helpers
  - Design system components

#### 7. **SpeziHealthKit**
- **Purpose**: HealthKit integration
- **Features**:
  - Health data reading/writing
  - Permission management
  - Data synchronization

#### 8. **SpeziConsent**
- **Purpose**: Consent management
- **Features**:
  - Document consent flows
  - Permission tracking
  - Compliance documentation

### Spezi Module Configuration

Modules are configured in `TemplateApplicationDelegate.swift`:

```swift
import Spezi

class TemplateApplicationDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration {
            // Account module
            AccountConfiguration {
                AccountSetup()
            }

            // Firestore module
            Firestore(
                settings: FirestoreSettings()
            )

            // Storage module
            FirebaseStorageConfiguration()

            // Contact module
            Contact(
                contacts: [/* contacts */]
            )

            // Onboarding module
            OnboardingDataSource()
        }
    }
}
```

### Benefits of Spezi Framework

1. **Modularity**: Each feature is a self-contained module
2. **Reusability**: Modules can be reused across projects
3. **HIPAA Compliance**: Built-in security and privacy features
4. **Healthcare Focus**: Designed specifically for medical applications
5. **SwiftUI Native**: Fully compatible with SwiftUI
6. **Open Source**: Community-driven development

---

## Cloud Infrastructure

### 1. Firebase Services

#### **Firebase Authentication**
- **Purpose**: User authentication and session management
- **Authentication Methods**:
  - Email/Password
  - Custom account creation
  - Password reset via email

```swift
import FirebaseAuth

// Sign in
Auth.auth().signIn(withEmail: email, password: password)

// Get current user
let user = Auth.auth().currentUser
```

#### **Cloud Firestore (Database)**
- **Purpose**: Primary NoSQL database
- **Data Model**:

```
Firestore Structure:
├── users/{userId}
│   ├── profile (name, email, role, etc.)
│   ├── chatHistory/
│   │   └── {chatId}
│   │       └── messages/{messageId}
│   └── documents/{documentId}
│
├── posts/{postId}
│   ├── author (email)
│   ├── content
│   ├── likes, dislikes
│   ├── timestamp
│   └── type (post/announcement)
│
└── contacts/{contactId}
    ├── name
    ├── role
    ├── phone
    └── email
```

**Security Rules**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data - only owner can access
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }

    // Posts - authenticated users can read, only author can delete
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth != null
                    && request.auth.token.email == resource.data.author;
      allow update: if request.auth != null;
    }

    // Contacts - read-only for authenticated users
    match /contacts/{contactId} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

**Key Collections**:

| Collection | Purpose | Access Control |
|------------|---------|----------------|
| `users` | User profiles and data | Owner only |
| `posts` | Community posts and announcements | Read: All, Delete: Author |
| `contacts` | Medical staff directory | Read: All, Write: Admin |
| `chatHistory` | AI chat conversations | Owner only |

#### **Firebase Storage**
- **Purpose**: Document metadata storage
- **Usage**: Reference storage for AWS S3 documents
- **Structure**:
  ```
  users/{userId}/documents/{documentId}/metadata
  ```

### 2. AWS Services

#### **AWS S3 (Simple Storage Service)**
- **Purpose**: Primary document storage
- **Use Cases**:
  - Medical document uploads (PDF, images, text)
  - Secure file storage
  - Large file handling

**Configuration**:
```swift
struct AWSS3Service {
    let accessKey: String
    let secretKey: String
    let region: String
    let bucketName: String

    func uploadDocument(data: Data, filename: String) async throws {
        // Upload to S3
        let url = "https://\(bucketName).s3.\(region).amazonaws.com/\(filename)"
        // ... upload logic
    }
}
```

**S3 Bucket Structure**:
```
s3://companion-documents/
├── users/{userId}/
│   ├── medical-records/
│   ├── lab-results/
│   └── patient-files/
```

**S3 Security**:
- IAM user with restricted permissions
- Bucket policy for user-specific access
- Server-side encryption (SSE-S3)

**IAM Policy Example**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::companion-documents/*",
        "arn:aws:s3:::companion-documents"
      ]
    }
  ]
}
```

### 3. AI Services

#### **OpenAI API (GPT-4)**
- **Purpose**: Medical AI assistant
- **Features**:
  - Context-aware responses
  - Document analysis
  - Medical insights

```swift
struct OpenAIService {
    func sendMessage(_ message: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        // ... API call
    }
}
```

#### **AssemblyAI API**
- **Purpose**: Voice interaction
- **Features**:
  - Speech-to-text transcription
  - Medical terminology support
  - High-accuracy transcription

```swift
struct AssemblyAIService {
    func transcribe(audioURL: URL) async throws -> String {
        // 1. Upload audio
        // 2. Create transcript job
        // 3. Poll for completion
        // 4. Return transcribed text
    }

    func speak(text: String) {
        // Use iOS AVSpeechSynthesizer
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(AVSpeechUtterance(string: text))
    }
}
```

### 4. Data Synchronization Strategy

```
┌─────────────┐
│  iOS App    │
└──────┬──────┘
       │
       ├─────────────────┐
       │                 │
       ▼                 ▼
┌─────────────┐   ┌──────────┐
│  Firebase   │   │  AWS S3  │
│  Firestore  │   │          │
└─────────────┘   └──────────┘
       │
       ├── Real-time sync for:
       │   • Chat messages
       │   • Posts/announcements
       │   • User profiles
       │
       └── Offline support:
           • Local cache
           • Auto-sync on reconnect
```

---

## Data Flow

### 1. User Authentication Flow

```
User Opens App
      │
      ▼
Check Auth State (Firebase Auth)
      │
      ├─── Not Authenticated ──→ Login/Signup Flow
      │                               │
      │                               ▼
      │                         Firebase Auth
      │                               │
      │                               ▼
      └─── Authenticated ───→ Fetch User Profile (Firestore)
                                      │
                                      ▼
                              Load Main Dashboard
```

### 2. Chat with AI Flow

```
User Input (Text/Voice)
      │
      ├─── Text Input ──→ Direct to OpenAI
      │
      └─── Voice Input ──→ AssemblyAI (STT) ──→ OpenAI
                                  │
                                  ▼
                         OpenAI GPT-4 Processing
                                  │
                                  ├─── RAG Service (if documents uploaded)
                                  │         │
                                  │         ▼
                                  │    AWS S3 (Retrieve docs)
                                  │
                                  ▼
                         AI Response Generated
                                  │
                                  ├─── Save to Firestore (chat history)
                                  │
                                  └─── Display to User
                                        │
                                        └─── Voice Output (Optional)
                                              │
                                              ▼
                                        AVSpeechSynthesizer
```

### 3. Document Upload Flow

```
User Selects Document
      │
      ▼
Validate File (type, size)
      │
      ▼
Upload to AWS S3
      │
      ├─── Success ──→ Save Metadata to Firestore
      │                       │
      │                       ▼
      │                Update UI
      │
      └─── Failure ──→ Show Error
```

### 4. Post Creation/Deletion Flow

```
Create Post:
User Writes Post → Validate Content → Save to Firestore → Real-time Update

Delete Post:
User Taps Delete → Check Authorship (client) → Confirm Dialog
                                  │
                                  ▼
                    Delete from Firestore (server validates authorship)
                                  │
                                  ▼
                    Real-time Update (post removed from all clients)
```

---

## Security Architecture

### 1. Authentication Security

- **Firebase Auth** with email/password
- **Password Requirements**: Enforced by Firebase (min 6 characters)
- **Password Recovery**: Email-based reset flow
- **Session Management**: Automatic token refresh

### 2. Authorization Model

**Role-Based Access Control (RBAC)**:

| Role | Permissions |
|------|-------------|
| **Doctor** | Full access to all features, patient data, AI chat, documents |
| **Resident** | Supervised access, limited patient data |
| **Administrator** | System management, user oversight, contact management |

### 3. Data Security

#### **At Rest**:
- Firestore: Encrypted by default
- AWS S3: Server-side encryption (SSE-S3)
- Local storage: iOS keychain for sensitive data

#### **In Transit**:
- HTTPS/TLS for all API communications
- Firebase SDK: Built-in encryption
- AWS SDK: TLS 1.2+

#### **API Key Management**:
```swift
// NEVER commit API keys to Git
// Store in APIKeys.swift (added to .gitignore)
struct APIKeys {
    static let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    static let awsAccessKey = ProcessInfo.processInfo.environment["AWS_ACCESS_KEY"] ?? ""
    static let awsSecretKey = ProcessInfo.processInfo.environment["AWS_SECRET_KEY"] ?? ""
    static let assemblyAI = ProcessInfo.processInfo.environment["ASSEMBLYAI_API_KEY"] ?? ""
}
```

### 4. HIPAA Compliance Considerations

⚠️ **Important**: This app implements security best practices but is **not certified HIPAA compliant**. For production medical use:

- [ ] Sign Business Associate Agreement (BAA) with Firebase
- [ ] Enable Firebase audit logging
- [ ] Implement end-to-end encryption for PHI
- [ ] Add user access logging
- [ ] Implement data retention policies
- [ ] Add breach notification mechanisms
- [ ] Conduct security audit
- [ ] Implement backup and disaster recovery

---

## Deployment Guide

### Prerequisites

1. **Xcode 15.0+** installed
2. **Apple Developer Account** ($99/year)
3. **GitHub Account**
4. **Firebase Project** created
5. **AWS Account** with S3 bucket
6. **OpenAI API Key**
7. **AssemblyAI API Key**

### Step 1: Configure Firebase

1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create new project "health-companion"
   - Enable Google Analytics (optional)

2. **Add iOS App**:
   - Bundle ID: `edu.stanford.spezi.templateapplication`
   - Download `GoogleService-Info.plist`
   - Add to Xcode project root

3. **Enable Firebase Services**:
   ```
   Authentication → Email/Password (Enable)
   Firestore Database → Create database (Start in test mode)
   Storage → Get started
   ```

4. **Update Firestore Security Rules**:
   - Copy rules from `FIRESTORE_SECURITY_RULES.md`
   - Publish rules in Firebase Console

### Step 2: Configure AWS S3

1. **Create S3 Bucket**:
   ```bash
   aws s3 mb s3://companion-documents --region us-east-1
   ```

2. **Create IAM User**:
   ```bash
   aws iam create-user --user-name companion-app
   ```

3. **Attach S3 Policy**:
   - Use policy from [Cloud Infrastructure](#2-aws-services) section
   - Generate access key and secret key

4. **Configure CORS**:
   ```json
   [
     {
       "AllowedHeaders": ["*"],
       "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
       "AllowedOrigins": ["*"],
       "ExposeHeaders": []
     }
   ]
   ```

### Step 3: Configure API Keys

Create `APIKeys.swift` (do NOT commit to Git):

```swift
// TemplateApplication/SharedContext/APIKeys.swift
struct APIKeys {
    static let openAIKey = "sk-..." // OpenAI API key
    static let awsAccessKey = "AKIA..." // AWS access key
    static let awsSecretKey = "..." // AWS secret key
    static let awsRegion = "us-east-1"
    static let awsBucketName = "companion-documents"
    static let assemblyAI = "..." // AssemblyAI API key
}
```

### Step 4: Xcode Configuration

1. **Open Project**:
   ```bash
   cd SpeziTemplateApplication-main
   open TemplateApplication.xcodeproj
   ```

2. **Select Team**:
   - Project Settings → Signing & Capabilities
   - Select your Apple Developer Team

3. **Update Bundle ID** (if needed):
   - Change to your unique identifier
   - Update Firebase and Apple Developer Portal

4. **Configure Capabilities**:
   - HealthKit
   - Push Notifications (optional)
   - Background Modes (optional)

### Step 5: Build and Test

1. **Select Simulator**:
   - iPhone 15 Pro (iOS 17.0+)

2. **Build and Run**:
   ```
   Cmd + R
   ```

3. **Test Key Flows**:
   - [ ] User signup/login
   - [ ] Role selection
   - [ ] Document upload
   - [ ] AI chat
   - [ ] Voice input/output
   - [ ] Contacts directory
   - [ ] Post creation/deletion

### Step 6: Archive for Distribution

1. **Select "Any iOS Device"** target

2. **Archive**:
   ```
   Product → Archive
   ```

3. **Export IPA**:
   - Organizer → Distribute App
   - Ad Hoc (for testing) or App Store

4. **Sign with Certificate**:
   - Use your distribution certificate
   - Select provisioning profile

---

## CI/CD with GitHub

### GitHub Repository Setup

1. **Create Repository**:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/Companion.git
   git push -u origin main
   ```

2. **Add .gitignore**:
   ```gitignore
   # API Keys (CRITICAL - NEVER COMMIT)
   **/APIKeys.swift

   # Xcode
   build/
   *.xcarchive
   *.ipa
   DerivedData/
   xcuserdata/

   # Firebase
   GoogleService-Info.plist  # Optional: can commit if no secrets

   # Environment
   .env
   ```

### GitHub Actions Workflow

Create `.github/workflows/ios.yml`:

```yaml
name: iOS Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    name: Build and Test
    runs-on: macos-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set up Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'

    - name: Create APIKeys.swift from secrets
      run: |
        cat > TemplateApplication/SharedContext/APIKeys.swift << EOF
        struct APIKeys {
            static let openAIKey = "${{ secrets.OPENAI_API_KEY }}"
            static let awsAccessKey = "${{ secrets.AWS_ACCESS_KEY }}"
            static let awsSecretKey = "${{ secrets.AWS_SECRET_KEY }}"
            static let awsRegion = "${{ secrets.AWS_REGION }}"
            static let awsBucketName = "${{ secrets.AWS_BUCKET_NAME }}"
            static let assemblyAI = "${{ secrets.ASSEMBLYAI_API_KEY }}"
        }
        EOF

    - name: Install dependencies
      run: xcodebuild -resolvePackageDependencies

    - name: Build
      run: |
        xcodebuild clean build \
          -project TemplateApplication.xcodeproj \
          -scheme TemplateApplication \
          -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0'

    - name: Run tests
      run: |
        xcodebuild test \
          -project TemplateApplication.xcodeproj \
          -scheme TemplateApplication \
          -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0'

  archive:
    name: Archive and Export IPA
    runs-on: macos-latest
    needs: build
    if: github.ref == 'refs/heads/main'

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set up Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'

    - name: Import certificates
      env:
        CERTIFICATE_BASE64: ${{ secrets.CERTIFICATE_BASE64 }}
        P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
      run: |
        echo $CERTIFICATE_BASE64 | base64 --decode > certificate.p12
        security create-keychain -p "" build.keychain
        security import certificate.p12 -k build.keychain -P $P12_PASSWORD -T /usr/bin/codesign
        security set-keychain-settings -t 3600 -u build.keychain
        security default-keychain -s build.keychain
        security unlock-keychain -p "" build.keychain
        security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain

    - name: Archive
      run: |
        xcodebuild archive \
          -project TemplateApplication.xcodeproj \
          -scheme TemplateApplication \
          -archivePath build/TemplateApplication.xcarchive \
          -configuration Release \
          CODE_SIGN_IDENTITY="iPhone Distribution" \
          PROVISIONING_PROFILE_SPECIFIER="${{ secrets.PROVISIONING_PROFILE_NAME }}"

    - name: Export IPA
      run: |
        xcodebuild -exportArchive \
          -archivePath build/TemplateApplication.xcarchive \
          -exportPath build \
          -exportOptionsPlist ExportOptions.plist

    - name: Upload IPA
      uses: actions/upload-artifact@v3
      with:
        name: TemplateApplication.ipa
        path: build/TemplateApplication.ipa
```

### Required GitHub Secrets

Add these secrets in GitHub Repository Settings → Secrets:

| Secret Name | Description |
|-------------|-------------|
| `OPENAI_API_KEY` | OpenAI API key |
| `AWS_ACCESS_KEY` | AWS access key ID |
| `AWS_SECRET_KEY` | AWS secret access key |
| `AWS_REGION` | AWS region (e.g., us-east-1) |
| `AWS_BUCKET_NAME` | S3 bucket name |
| `ASSEMBLYAI_API_KEY` | AssemblyAI API key |
| `CERTIFICATE_BASE64` | Base64-encoded p12 certificate |
| `P12_PASSWORD` | Certificate password |
| `PROVISIONING_PROFILE_NAME` | Provisioning profile name |

### Generating Certificate Base64

```bash
# Export certificate from Keychain as .p12
# Then convert to base64:
base64 -i certificate.p12 -o certificate_base64.txt
# Copy contents of certificate_base64.txt to GitHub Secret
```

### Branching Strategy

```
main (production)
  ↑
  └── Pull Request (required reviews)
       ↑
     develop (staging)
       ↑
       └── feature/voice-integration
       └── feature/new-dashboard
       └── bugfix/chat-error
```

**Workflow**:
1. Create feature branch from `develop`
2. Make changes and commit
3. Push and create Pull Request to `develop`
4. CI runs tests automatically
5. After approval, merge to `develop`
6. When ready, create PR from `develop` to `main`
7. CI builds and archives IPA
8. Deploy to TestFlight or App Store

### TestFlight Distribution

1. **Upload to App Store Connect**:
   ```bash
   xcrun altool --upload-app \
     -f build/TemplateApplication.ipa \
     -u "your-apple-id@email.com" \
     -p "app-specific-password"
   ```

2. **Or use GitHub Action**:
   ```yaml
   - name: Upload to TestFlight
     uses: apple-actions/upload-testflight-build@v1
     with:
       app-path: build/TemplateApplication.ipa
       issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
       api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
       api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}
   ```

### Continuous Deployment Pipeline

```
┌─────────────┐
│  Git Push   │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ GitHub Actions  │
│   Triggered     │
└──────┬──────────┘
       │
       ├─── Build ─────────┐
       │                   │
       ├─── Test ──────────┤
       │                   │
       └─── Archive ───────┤
                           │
                           ▼
                  ┌────────────────┐
                  │   Export IPA   │
                  └────────┬───────┘
                           │
                           ├─── TestFlight
                           │
                           └─── App Store
```

---

## Performance Optimization

### 1. Data Caching Strategy

```swift
// Cache Firestore queries
@Firestore(cacheSettings: .enabled) var posts

// Cache images
let imageCache = NSCache<NSString, UIImage>()
```

### 2. Lazy Loading

```swift
// Load contacts on demand
LazyVStack {
    ForEach(contacts) { contact in
        ContactCard(contact: contact)
    }
}
```

### 3. Background Processing

```swift
// Upload documents in background
Task.detached(priority: .background) {
    await uploadToS3(document)
}
```

---

## Monitoring and Analytics

### Firebase Analytics

```swift
import FirebaseAnalytics

// Log events
Analytics.logEvent("chat_message_sent", parameters: [
    "message_length": message.count
])
```

### Crash Reporting

```swift
import FirebaseCrashlytics

// Log errors
Crashlytics.crashlytics().record(error: error)
```

---

## Troubleshooting Deployment

### Common Issues

1. **"No such module 'Spezi'"**
   - Solution: File → Packages → Resolve Package Versions

2. **Code signing error**
   - Solution: Check Team selection and provisioning profile

3. **Firebase configuration error**
   - Solution: Verify GoogleService-Info.plist is in project

4. **AWS S3 upload fails**
   - Solution: Check IAM permissions and bucket policy

5. **GitHub Actions build fails**
   - Solution: Verify all secrets are set correctly

---

## Additional Resources

- [Stanford Spezi Documentation](https://github.com/StanfordSpezi/Spezi)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [AWS S3 iOS SDK](https://docs.aws.amazon.com/sdk-for-ios/)
- [GitHub Actions for iOS](https://docs.github.com/en/actions)
- [TestFlight Beta Testing](https://developer.apple.com/testflight/)

---

## Contact and Support

For issues and questions:
- **GitHub Issues**: [Repository Issues](https://github.com/SHUBHAMJAIN-AI/Companion/issues)
- **Documentation**: See README.md for feature documentation
- **Technical Support**: Open a GitHub Discussion

---

**Last Updated**: 2025-10-12
**Version**: 2.0
**Maintained by**: Shubham Jain
