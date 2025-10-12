//
// Voice Test View - Test AssemblyAI Integration
//

import SwiftUI

struct VoiceTestView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var assemblyAI = AssemblyAIService()
    @State private var transcription = ""
    @State private var isProcessing = false
    @State private var statusMessage = "Ready"
    
    var body: some View {
        VStack(spacing: 20) {
            headerSection
            transcriptionSection
            controlButtons
            if isProcessing {
                ProgressView().scaleEffect(1.5)
            }
        }
        .padding()
    }
    
    private var headerSection: some View {
        VStack {
            Text("Voice Test").font(.largeTitle).bold()
            Text(statusMessage).foregroundColor(.secondary)
        }
    }
    
    private var transcriptionSection: some View {
        Group {
            if !transcription.isEmpty {
                ScrollView {
                    Text(transcription)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
                .frame(maxHeight: 200)
            }
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 30) {
            recordButton
            if !transcription.isEmpty {
                playButton
            }
        }
    }
    
    private var recordButton: some View {
        Button {
            toggleRecording()
        } label: {
            VStack {
                Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(audioRecorder.isRecording ? .red : .blue)
                Text(audioRecorder.isRecording ? "Stop" : "Record")
            }
        }
        .disabled(isProcessing)
    }
    
    private var playButton: some View {
        Button {
            testSpeech()
        } label: {
            VStack {
                Image(systemName: "speaker.wave.2.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("Play")
            }
        }
        .disabled(isProcessing)
    }
    
    private func toggleRecording() {
        if audioRecorder.isRecording {
            guard let audioURL = audioRecorder.stopRecording() else {
                statusMessage = "Recording failed"
                return
            }
            statusMessage = "Transcribing..."
            isProcessing = true
            
            Task { @MainActor in
                do {
                    transcription = try await assemblyAI.transcribeAudio(fileURL: audioURL)
                    statusMessage = "Transcription complete"
                    isProcessing = false
                } catch {
                    statusMessage = "Error: \(error.localizedDescription)"
                    transcription = "Error: \(error)"
                    isProcessing = false
                    print("Transcription error: \(error)")
                }
            }
        } else {
            statusMessage = "Recording..."
            Task {
                do {
                    try await audioRecorder.startRecording()
                    statusMessage = "Recording... Speak now!"
                } catch {
                    statusMessage = "Recording failed: \(error.localizedDescription)"
                    print("Recording error: \(error)")
                }
            }
        }
    }
    
    private func testSpeech() {
        statusMessage = "Playing audio..."
        isProcessing = true
        
        Task { @MainActor in
            do {
                try await assemblyAI.speakText(transcription)
                try await Task.sleep(nanoseconds: 2_000_000_000)
                statusMessage = "Playback complete"
                isProcessing = false
            } catch {
                statusMessage = "Playback error: \(error.localizedDescription)"
                isProcessing = false
                print("Playback error: \(error)")
            }
        }
    }
}
