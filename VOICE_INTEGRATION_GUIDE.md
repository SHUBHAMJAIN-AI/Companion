# Voice Integration Guide - AssemblyAI

## Overview
Complete voice input/output integration using AssemblyAI for speech-to-text and text-to-speech in the Hospitalist Companion app.

## Features Implemented

### 1. **ChatBotView Voice Integration**
- **Microphone Button**: Record voice questions (red when recording)
- **Speaker Button**: Play last AI response as audio
- **Full Flow**: Record → Transcribe → RAG Query → Display → Speak Response

### 2. **Services Created**

#### AudioRecorder.swift
- Records audio using AVAudioRecorder
- Saves to m4a format at 16kHz mono
- Manages recording state with @Published property

#### AssemblyAIService.swift
- **Speech-to-Text**: Upload → Create Transcript → Poll for completion
- **Text-to-Speech**: Synthesize → Play audio
- Error handling for upload/transcription/timeout failures

### 3. **Test Interface**
- **VoiceTestView**: Standalone test view for voice features
- Access via waveform icon in top nav bar
- Test recording, transcription, and playback independently

## Usage

### In ChatBotView
1. **Voice Input**:
   - Tap microphone button (turns red)
   - Speak your question
   - Tap stop button
   - Wait for transcription → auto-sends to RAG
   - Response appears in chat

2. **Voice Output**:
   - Tap speaker button after receiving response
   - AI response plays as audio
   - Button disabled during playback

### In VoiceTestView
1. Tap waveform icon in dashboard top bar
2. Tap "Record" button and speak
3. Tap "Stop" to transcribe
4. Tap "Play" to hear transcription as speech

## API Configuration

### AssemblyAI API Key
Located in `APIKeys.swift`:
```swift
static let assemblyAI = "9fe2df3551d44e28beada058715a09b2"
```

### Endpoints Used
- Upload: `https://api.assemblyai.com/v2/upload`
- Transcript: `https://api.assemblyai.com/v2/transcript`
- TTS: iOS Native AVSpeechSynthesizer (no API call needed)

## Permissions

Already configured in Info.plist:
- `NSMicrophoneUsageDescription`: "We need microphone access for voice input"
- `NSSpeechRecognitionUsageDescription`: "We need access to speech recognition to enable voice commands"

## File Structure

```
TemplateApplication/
├── Chat/
│   └── ChatBotView.swift          # Voice-enabled chat interface
├── Services/
│   ├── AudioRecorder.swift        # Audio recording service
│   ├── AssemblyAIService.swift    # STT/TTS service
│   └── RAGService.swift           # RAG pipeline integration
├── Testing/
│   └── VoiceTestView.swift        # Voice feature test interface
├── MainDashboard/
│   └── DashboardView.swift        # Added voice test button
└── SharedContext/
    └── APIKeys.swift              # AssemblyAI API key
```

## Technical Details

### Audio Recording
- Format: MPEG4AAC (m4a)
- Sample Rate: 44.1kHz
- Channels: Mono
- Quality: High
- Bit Rate: 128kbps
- Session: playAndRecord with defaultToSpeaker

### Transcription Flow
1. Record audio to temporary file
2. Upload audio to AssemblyAI
3. Create transcript job
4. Poll every 1 second (max 60 attempts)
5. Return transcribed text

### Speech Synthesis Flow
1. Use iOS native AVSpeechSynthesizer
2. Configure voice (en-US)
3. Set rate, pitch, volume
4. Speak utterance directly

### Error Handling
- Upload failures
- Transcription failures
- Timeout after 60 seconds
- Playback errors

## Testing Checklist

- [ ] Microphone permission granted
- [ ] Record button changes to red when recording
- [ ] Audio transcription completes successfully
- [ ] Transcribed text auto-sends to RAG
- [ ] RAG response displays in chat
- [ ] Speaker button plays response audio
- [ ] VoiceTestView accessible from dashboard
- [ ] Test view shows transcription
- [ ] Test view plays synthesized speech

## Troubleshooting

### No Audio Recording
- Check microphone permissions in Settings
- Verify AVAudioSession configuration
- Check for other apps using microphone

### Transcription Fails
- Verify API key is correct (check console logs)
- Check network connectivity
- Ensure audio file is valid m4a format
- Check AssemblyAI API status
- Review console logs for detailed error messages
- Verify microphone permissions granted

### Audio Playback Issues
- TTS uses native iOS speech synthesis
- Check device volume settings
- Verify AVAudioSession is active
- Ensure no other audio is playing

### Timeout Errors
- Increase polling timeout (currently 60 seconds)
- Check audio file size (large files take longer)
- Verify network speed

## Future Enhancements

- [ ] Real-time streaming transcription
- [ ] Voice activity detection
- [ ] Multiple language support
- [ ] Custom voice selection for TTS
- [ ] Audio waveform visualization
- [ ] Background audio processing
- [ ] Offline mode with local STT/TTS

## API Limits

AssemblyAI Free Tier:
- 5 hours of audio per month
- Standard transcription speed
- Basic TTS synthesis

For production, upgrade to paid plan for:
- Unlimited transcription
- Faster processing
- Premium voices
- Real-time streaming
