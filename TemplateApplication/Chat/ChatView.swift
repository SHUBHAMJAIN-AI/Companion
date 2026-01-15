//
// Health Companion Chat Interface
//

import AVFoundation
import Speech
import SpeziViews
import SwiftUI

struct ChatView: View {
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @StateObject private var openAIService = OpenAIService()
    @StateObject private var speechService = SpeechService()
    @State private var isProcessing = false
    @Binding var presentingAccount: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                chatMessagesView
                inputAreaView
            }
            .navigationTitle("Health Assistant")
            .onChange(of: speechService.recognizedText) { _, newText in
                if !newText.isEmpty && !speechService.isRecording {
                    messageText = newText
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Account") {
                        presentingAccount = true
                    }
                }
            }
        }
    }
    
    private var chatMessagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var inputAreaView: some View {
        VStack {
            HStack {
                TextField("Ask about your health documents...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: toggleRecording) {
                    Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                        .foregroundColor(speechService.isRecording ? .red : .blue)
                        .accessibilityLabel(speechService.isRecording ? "Stop recording" : "Start recording")
                }
                
                Button("Send", action: sendMessage)
                    .disabled(messageText.isEmpty || isProcessing)
            }
            .padding()
            
            if isProcessing {
                processingIndicator
            }
        }
    }
    
    private var processingIndicator: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("AI is thinking...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else {
            return
        }
        
        let userMessage = ChatMessage(content: messageText, isUser: true)
        messages.append(userMessage)
        
        // Process with OpenAI (placeholder)
        processWithAI(messageText)
        messageText = ""
    }
    
    private func processWithAI(_ text: String) {
        isProcessing = true
        
        Task { @MainActor in
            do {
                let response = try await openAIService.sendMessage(text)
                let aiMessage = ChatMessage(content: response, isUser: false)
                messages.append(aiMessage)
                speakText(response)
                isProcessing = false
            } catch {
                let errorMessage = ChatMessage(content: "Sorry, I'm having trouble processing your request. Please try again.", isUser: false)
                messages.append(errorMessage)
                isProcessing = false
            }
        }
    }
    
    private func speakText(_ text: String) {
        speechService.speak(text)
    }
    
    private func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            do {
                try speechService.startRecording()
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .frame(maxWidth: 250, alignment: .trailing)
            } else {
                Text(message.content)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .frame(maxWidth: 250, alignment: .leading)
                Spacer()
            }
        }
    }
}
