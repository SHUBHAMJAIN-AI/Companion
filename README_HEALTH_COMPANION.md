# Health Companion - AI-Powered Medical Assistant

## Overview
Health Companion is a healthcare application built on the Spezi framework, designed for doctors, residents, and administrators. It provides AI-powered document analysis, voice interaction, and secure cloud storage.

## Features Implemented

### 1. **Role-Based Authentication**
- Doctor, Resident, Administrator roles
- Role selection during onboarding
- Spezi Account integration with Firebase

### 2. **AI Chat Interface** 
- OpenAI GPT-4 integration for medical insights
- Real-time chat with AI assistant
- Document context awareness
- Processing indicators

### 3. **Document Management**
- Upload medical documents (PDF, images, text)
- AWS S3 integration for secure storage
- Document preview and management
- File type detection and organization

### 4. **Voice Interface**
- Speech-to-text for asking questions
- Text-to-speech for AI responses
- iOS Speech Framework integration
- Real-time voice recognition

### 5. **Contact Directory**
- Medical staff phone directory (existing Spezi Contact module)
- Role-based contact access

## Architecture

### Core Spezi Modules Used:
- **SpeziAccount** - User authentication and management
- **SpeziFirestore** - Chat history and user data storage
- **SpeziFirebaseStorage** - Document metadata storage
- **SpeziContact** - Phone directory functionality
- **SpeziOnboarding** - User setup flow
- **SpeziViews** - UI components
- **SpeziHealthKit** - Health data integration
- **SpeziConsent** - Document upload permissions

### Custom Services:
- **OpenAIService** - GPT-4 API integration
- **AWSS3Service** - Document storage service
- **SpeechService** - Voice recognition and synthesis

### App Structure:
```
HealthCompanionApp/
├── Chat/
│   └── ChatView.swift
├── Documents/
│   └── DocumentUploadView.swift
├── Services/
│   ├── OpenAIService.swift
│   ├── AWSS3Service.swift
│   └── SpeechService.swift
├── Onboarding/
│   └── RoleSelectionView.swift
└── Contacts/ (existing)
```

## Configuration Required

### 1. OpenAI API
- Add your OpenAI API key to `OpenAIService.swift`
- Configure model preferences (currently GPT-4)

### 2. AWS S3
- Set up AWS credentials in `AWSS3Service.swift`
- Configure S3 bucket for document storage
- Set appropriate IAM permissions

### 3. Firebase
- Update Firebase configuration for authentication
- Configure Firestore for chat history
- Set up Firebase Storage for document metadata

### 4. iOS Permissions
- Speech Recognition permission
- Microphone access
- Document access permissions

## User Flow

1. **Onboarding**: Role selection → Welcome → Account setup → Permissions
2. **Main App**: 
   - Chat tab: AI conversations with voice support
   - Documents tab: Upload and manage medical documents
   - Contacts tab: Medical staff directory
3. **AI Interaction**: Upload documents → Ask questions → Get AI insights

## Next Steps

1. **AWS Integration**: Complete S3 service implementation
2. **OpenAI Enhancement**: Add document content to AI context
3. **Security**: Implement HIPAA-compliant data handling
4. **Testing**: Add comprehensive test coverage
5. **Deployment**: Configure for production environment

## Dependencies

The app leverages the full Spezi ecosystem while adding AI and cloud capabilities for healthcare-specific use cases.