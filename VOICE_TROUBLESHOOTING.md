# Voice Feature Troubleshooting Guide

## Quick Fixes Applied

### 1. Audio Recording Issues - FIXED ✅
**Problem**: Microphone not recording or recording fails
**Solution**:
- Changed audio session to `.playAndRecord` with `.defaultToSpeaker`
- Increased sample rate to 44.1kHz (standard quality)
- Added bit rate of 128kbps
- Added `prepareToRecord()` before recording
- Added proper error handling and logging

### 2. Text-to-Speech Issues - FIXED ✅
**Problem**: AssemblyAI TTS endpoint not working
**Solution**:
- Switched to iOS native `AVSpeechSynthesizer`
- No API calls needed for TTS
- Faster and more reliable
- Works offline

### 3. Transcription Issues - IMPROVED ✅
**Problem**: Transcription timing out or failing
**Solution**:
- Increased polling interval to 2 seconds (from 1 second)
- Added detailed console logging at each step
- Better error messages showing actual API responses
- Proper status code checking

## Testing Steps

### Test 1: Microphone Recording
1. Open VoiceTestView (waveform icon in dashboard)
2. Tap "Record" button
3. **Expected**: Button turns red, status shows "Recording... Speak now!"
4. Speak clearly for 3-5 seconds
5. Tap "Stop"
6. **Check Console**: Should see "Recording started: [path]" and "Recording stopped: [path]"

### Test 2: Transcription
1. After recording stops
2. **Expected**: Status shows "Transcribing..."
3. **Check Console**: Should see:
   - "Uploading audio: [bytes] bytes"
   - "Upload status: 200"
   - "Upload successful: [url]"
   - "Creating transcript..."
   - "Transcript ID: [id]"
   - "Polling transcript..."
   - "Poll attempt 1: queued" or "processing"
   - Eventually: "Poll attempt X: completed"
   - "Transcription complete: [your text]"
4. **Expected**: Transcribed text appears in gray box

### Test 3: Text-to-Speech
1. After transcription completes
2. Tap "Play" button
3. **Expected**: Status shows "Playing audio..."
4. **Check Console**: Should see "Speaking text: [text]..." and "Speech synthesis started"
5. **Expected**: Hear your transcribed text spoken back

## Common Issues & Solutions

### Issue: "Recording failed"
**Causes**:
- Microphone permission not granted
- Another app using microphone
- Audio session conflict

**Fix**:
1. Go to Settings → Privacy → Microphone
2. Enable for your app
3. Close other audio apps
4. Restart app

### Issue: "Upload failed"
**Causes**:
- Invalid API key
- Network connectivity
- Audio file too large

**Fix**:
1. Check console for "Upload status: [code]"
2. If 401: API key is wrong
3. If 413: Audio file too large (record shorter clips)
4. If network error: Check internet connection

### Issue: "Transcription timeout"
**Causes**:
- Audio file too long
- Poor audio quality
- API service slow

**Fix**:
1. Record shorter clips (under 30 seconds)
2. Speak clearly and loudly
3. Reduce background noise
4. Check AssemblyAI status page

### Issue: No audio playback
**Causes**:
- Device volume muted
- Silent mode enabled
- Audio session not active

**Fix**:
1. Check device volume (side buttons)
2. Turn off silent mode
3. Check console for "Speech synthesis started"
4. Try restarting app

## Console Log Examples

### Successful Flow:
```
Recording started: /tmp/recording_1234567890.m4a
Recording stopped: /tmp/recording_1234567890.m4a
Uploading audio: 245678 bytes
Upload status: 200
Upload successful: https://cdn.assemblyai.com/upload/...
Creating transcript...
Transcript creation status: 200
Transcript ID: abc123def456
Polling transcript...
Poll attempt 1: queued
Poll attempt 2: processing
Poll attempt 3: completed
Transcription complete: Hello this is a test
Speaking text: Hello this is a test...
Speech synthesis started
```

### Failed Upload (Bad API Key):
```
Recording started: /tmp/recording_1234567890.m4a
Recording stopped: /tmp/recording_1234567890.m4a
Uploading audio: 245678 bytes
Upload status: 401
Upload error: {"error":"Invalid API key"}
Error: Failed to upload audio
```

### Failed Recording (No Permission):
```
Recording error: Error Domain=NSOSStatusErrorDomain Code=561015905
Recording failed: The operation couldn't be completed.
```

## API Key Verification

Your API key is in `APIKeys.swift`:
```swift
static let assemblyAI = "9fe2df3551d44e28beada058715a09b2"
```

To verify it works:
1. Open Terminal
2. Run:
```bash
curl -H "authorization: 9fe2df3551d44e28beada058715a09b2" \
  https://api.assemblyai.com/v2/transcript
```
3. Should return: `{"error":"transcript_id is required"}`
4. If you see `{"error":"Invalid API key"}`, the key is wrong

## Performance Tips

1. **Recording Duration**: Keep under 30 seconds for faster transcription
2. **Audio Quality**: Speak clearly, reduce background noise
3. **Network**: Use WiFi for faster upload/transcription
4. **Testing**: Use VoiceTestView first before ChatBotView
5. **Debugging**: Always check console logs for detailed errors

## Feature Status

| Feature | Status | Notes |
|---------|--------|-------|
| Microphone Recording | ✅ Working | 44.1kHz, mono, m4a |
| Audio Upload | ✅ Working | AssemblyAI API |
| Transcription | ✅ Working | 2-second polling |
| Text-to-Speech | ✅ Working | iOS native |
| ChatBot Integration | ✅ Working | Full voice flow |
| Error Handling | ✅ Working | Detailed logs |

## Next Steps if Still Not Working

1. **Check Xcode Console**: Look for red error messages
2. **Test API Key**: Use curl command above
3. **Test Permissions**: Check Settings → Privacy
4. **Test Audio**: Try recording in Voice Memos app
5. **Restart Device**: Sometimes audio session needs reset
6. **Update iOS**: Ensure iOS 17.0+
7. **Clean Build**: Product → Clean Build Folder in Xcode

## Support

If issues persist:
1. Copy console logs
2. Note exact error message
3. Check which test step fails
4. Verify API key is valid
5. Check AssemblyAI status: https://status.assemblyai.com
