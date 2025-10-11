# Health Companion - AI-Powered Medical Assistant

<div align="center">

![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)

An intelligent healthcare companion application built with the Stanford Spezi framework, integrating AI-powered document analysis, voice interaction, and secure cloud storage for medical professionals.

[Features](#features) • [Installation](#installation) • [Architecture](#architecture) • [Configuration](#configuration) • [Usage](#usage) • [Contributing](#contributing)

</div>

---

## Overview

**Health Companion** is a comprehensive iOS healthcare application designed for medical professionals including doctors, residents, and healthcare administrators. Built on Stanford's Spezi framework, it combines modern AI capabilities with secure data management to streamline medical workflows and enhance patient care.

### Key Highlights

- **AI-Powered Insights**: GPT-4 integration for intelligent medical document analysis
- **Voice Interface**: Hands-free interaction using speech-to-text and text-to-speech
- **Secure Document Management**: AWS S3 integration for HIPAA-compliant storage
- **Role-Based Access**: Tailored experiences for different medical professional roles
- **Real-Time Chat**: Interactive AI assistant with context-aware responses

---

## Features

### 🤖 AI Chat Interface
- Real-time conversations with GPT-4 powered medical assistant
- Context-aware responses based on uploaded documents
- Processing indicators for user feedback
- Chat history stored securely in Firebase Firestore

### 📄 Document Management
- Upload medical documents (PDF, images, text files)
- Secure storage using AWS S3
- Document preview and organization
- Automatic file type detection
- Integration with AI for document analysis

### 🎤 Voice Interaction
- **Speech-to-Text**: Ask questions using voice commands
- **Text-to-Speech**: Listen to AI responses
- iOS Speech Framework integration
- Real-time voice recognition with accuracy indicators

### 👥 Role-Based System
- **Doctor**: Full access to all features and patient data
- **Resident**: Supervised access with learning tools
- **Administrator**: System management and user oversight
- Seamless role selection during onboarding

### 📞 Contact Directory
- Medical staff phone directory
- Role-based contact access
- Quick communication with team members

### 🔐 Security & Privacy
- Firebase Authentication integration
- Spezi Account management
- Secure data storage and transmission
- HIPAA compliance considerations

---

## Screenshots

> Add screenshots of your app here to showcase the UI

---

## Installation

### Prerequisites

- **Xcode 15.0+**
- **iOS 17.0+**
- **Swift 5.9+**
- **CocoaPods** or **Swift Package Manager**
- Active Apple Developer account

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/SHUBHAMJAIN-AI/Companion.git
   cd Companion
   ```

2. **Install dependencies**
   ```bash
   # Dependencies are managed via Swift Package Manager
   # Open the project in Xcode to automatically resolve packages
   open TemplateApplication.xcodeproj
   ```

3. **Configure API Keys**

   Create or update `APIKeys.swift` with your credentials:
   ```swift
   // TemplateApplication/SharedContext/APIKeys.swift
   struct APIKeys {
       static let openAIKey = "your-openai-api-key"
       static let awsAccessKey = "your-aws-access-key"
       static let awsSecretKey = "your-aws-secret-key"
       static let awsRegion = "your-aws-region"
       static let awsBucketName = "your-s3-bucket-name"
   }
   ```

4. **Set up Firebase**
   - Download `GoogleService-Info.plist` from Firebase Console
   - Add it to the Xcode project
   - Configure Firebase Authentication and Firestore

5. **Configure iOS Permissions**

   Update `Info.plist` with required permissions:
   ```xml
   <key>NSSpeechRecognitionUsageDescription</key>
   <string>We need access to speech recognition to enable voice commands</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>We need microphone access for voice input</string>
   <key>NSHealthShareUsageDescription</key>
   <string>We need access to read your health data</string>
   <key>NSHealthUpdateUsageDescription</key>
   <string>We need access to update your health data</string>
   ```

6. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

---

## Architecture

### Technology Stack

- **Framework**: Stanford Spezi
- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **AI**: OpenAI GPT-4
- **Cloud Storage**: AWS S3
- **Voice**: iOS Speech Framework

### Core Spezi Modules

| Module | Purpose |
|--------|---------|
| `SpeziAccount` | User authentication and profile management |
| `SpeziFirestore` | Chat history and user data persistence |
| `SpeziFirebaseStorage` | Document metadata storage |
| `SpeziContact` | Medical staff directory |
| `SpeziOnboarding` | User onboarding flow |
| `SpeziViews` | Reusable UI components |
| `SpeziHealthKit` | Health data integration |
| `SpeziConsent` | Document upload permissions |

### Custom Services

#### OpenAIService
Handles communication with OpenAI's GPT-4 API for intelligent medical insights and document analysis.

```swift
// Location: TemplateApplication/Services/OpenAIService.swift
- Chat completion
- Streaming responses
- Context management
- Error handling
```

#### AWSS3Service
Manages secure document storage and retrieval from AWS S3.

```swift
// Location: TemplateApplication/Services/AWSS3Service.swift
- Document upload
- File retrieval
- Access control
- Bucket management
```

#### SpeechService
Provides voice interaction capabilities using iOS Speech Framework.

```swift
// Location: TemplateApplication/Services/SpeechService.swift
- Speech recognition
- Text-to-speech synthesis
- Audio session management
- Permission handling
```

### Project Structure

```
HealthCompanionApp/
├── Account/                    # User account management
│   ├── AccountButton.swift
│   ├── AccountSheet.swift
│   └── AccountSetupHeader.swift
├── Chat/                       # AI chat interface
│   └── ChatView.swift
├── Documents/                  # Document management
│   └── DocumentUploadView.swift
├── MainDashboard/              # Main dashboard UI
│   └── DashboardView.swift
├── Contacts/                   # Staff directory
│   └── Contacts.swift
├── Onboarding/                 # User onboarding flow
│   ├── Welcome.swift
│   ├── RoleSelectionView.swift
│   ├── OnboardingFlow.swift
│   └── AccountOnboarding.swift
├── Services/                   # Custom services
│   ├── OpenAIService.swift
│   ├── AWSS3Service.swift
│   └── SpeechService.swift
├── SharedContext/              # Shared app context
│   ├── FeatureFlags.swift
│   ├── StorageKeys.swift
│   └── APIKeys.swift
├── Firestore/                  # Firebase configuration
│   └── FirebaseConfiguration.swift
└── TemplateApplication.swift   # App entry point
```

---

## Configuration

### 1. OpenAI Setup

1. Sign up at [OpenAI Platform](https://platform.openai.com/)
2. Generate an API key
3. Add to `APIKeys.swift`
4. Configure model preferences in `OpenAIService.swift`

### 2. AWS S3 Setup

1. Create an AWS account
2. Set up an S3 bucket for document storage
3. Create IAM user with S3 permissions:
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
           "arn:aws:s3:::your-bucket-name/*",
           "arn:aws:s3:::your-bucket-name"
         ]
       }
     ]
   }
   ```
4. Add credentials to `APIKeys.swift`

### 3. Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication (Email/Password)
3. Create Firestore database
4. Download `GoogleService-Info.plist`
5. Add to Xcode project
6. Configure security rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### 4. Feature Flags

Customize app behavior via `FeatureFlags.swift`:

```swift
enum FeatureFlags {
    static let enableVoiceInput = true
    static let enableDocumentUpload = true
    static let enableAIChat = true
    static let enableHealthKit = false
}
```

---

## Usage

### For Medical Professionals

1. **First Launch**: Complete onboarding and select your role
2. **Upload Documents**: Add patient records or medical documents
3. **Ask Questions**: Use text or voice to query the AI assistant
4. **Review Insights**: Get AI-powered analysis and recommendations
5. **Access Contacts**: Quick access to medical staff directory

### User Flow

```
Launch App → Role Selection → Welcome → Account Setup → Permissions → Main Dashboard
                                                                            ↓
                                                              Chat / Documents / Contacts
```

### Code Examples

#### Uploading a Document
```swift
let service = AWSS3Service()
await service.uploadDocument(data: documentData, filename: "patient_record.pdf")
```

#### Asking AI a Question
```swift
let openAI = OpenAIService()
let response = await openAI.sendMessage("What are the key findings in this lab report?")
```

#### Voice Input
```swift
let speech = SpeechService()
speech.startRecording { transcription in
    // Handle transcribed text
}
```

---

## Testing

### Run Tests

```bash
# Unit tests
xcodebuild test -scheme TemplateApplication -destination 'platform=iOS Simulator,name=iPhone 15'

# UI tests
xcodebuild test -scheme TemplateApplicationUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage

- Authentication flow tests
- Document upload tests
- Chat interface tests
- Onboarding flow tests
- Contact directory tests

---

## Roadmap

### Current Version (v1.0)
- ✅ Role-based authentication
- ✅ AI chat interface
- ✅ Document upload
- ✅ Voice interaction
- ✅ Contact directory

### Upcoming Features
- [ ] Enhanced document OCR
- [ ] Multi-language support
- [ ] Offline mode
- [ ] Advanced analytics dashboard
- [ ] Team collaboration features
- [ ] Integration with EHR systems
- [ ] Apple Watch companion app

---

## Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit your changes**
   ```bash
   git commit -m "Add amazing feature"
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

### Development Guidelines

- Follow Swift style guide
- Add unit tests for new features
- Update documentation
- Ensure code passes SwiftLint checks

---

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

---

## Acknowledgments

- **Stanford Spezi**: Framework foundation
- **OpenAI**: GPT-4 integration
- **Firebase**: Backend infrastructure
- **AWS**: Secure storage solutions

---

## Support

For issues, questions, or contributions:

- **Issues**: [GitHub Issues](https://github.com/SHUBHAMJAIN-AI/Companion/issues)
- **Discussions**: [GitHub Discussions](https://github.com/SHUBHAMJAIN-AI/Companion/discussions)
- **Email**: your-email@example.com

---

## Disclaimer

This application is designed for medical professionals and should be used as a supplementary tool. Always verify AI-generated insights with professional medical judgment. This app is not a substitute for professional medical advice, diagnosis, or treatment.

---

<div align="center">

Made with ❤️ by [Shubham Jain](https://github.com/SHUBHAMJAIN-AI)

**Health Companion** - Empowering Healthcare Professionals with AI

</div>
