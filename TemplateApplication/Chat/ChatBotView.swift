//
// ChatBot View for Health Companion
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct ChatBotView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ragService = RAGService()
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var assemblyAI = AssemblyAIService()
    @State private var messages: [ChatBotMessage] = []
    @State private var inputText = ""
    @State private var isProcessing = false
    @State private var isPlayingAudio = false
    @FocusState private var isInputFocused: Bool
    private let database = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                chatScrollView
                inputBar
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        saveChatHistory()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        ChatHistoryListView()
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .accessibilityLabel("Chat history")
                    }
                }
            }
        }
    }
    
    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
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
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            micButton
            textField
            if !messages.isEmpty {
                speakerButton
            }
            sendButton
        }
        .padding()
        .background(Color.white)
    }
    
    private var micButton: some View {
        Button {
            toggleRecording()
        } label: {
            Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "mic.fill")
                .foregroundColor(.white)
                .padding(12)
                .background(audioRecorder.isRecording ? Color.red : Color(hex: "1976D2"))
                .clipShape(Circle())
                .accessibilityLabel(audioRecorder.isRecording ? "Stop recording" : "Start recording")
        }
        .disabled(isProcessing)
    }
    
    private var textField: some View {
        TextField("Ask a question...", text: $inputText)
            .focused($isInputFocused)
            .textFieldStyle(.plain)
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
    }
    
    private var speakerButton: some View {
        Button {
            playLastResponse()
        } label: {
            Image(systemName: isPlayingAudio ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                .foregroundColor(.white)
                .padding(12)
                .background(Color(hex: "1976D2"))
                .clipShape(Circle())
                .accessibilityLabel(isPlayingAudio ? "Playing audio" : "Play response")
        }
        .disabled(isProcessing || isPlayingAudio)
    }
    
    private var sendButton: some View {
        Button {
            sendMessage()
        } label: {
            Image(systemName: isProcessing ? "hourglass" : "paperplane.fill")
                .foregroundColor(.white)
                .padding(12)
                .background(Color(hex: "1976D2"))
                .clipShape(Circle())
                .accessibilityLabel(isProcessing ? "Processing" : "Send message")
        }
        .disabled(inputText.isEmpty || isProcessing)
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else {
            return
        }
        
        let userMessage = ChatBotMessage(text: inputText, isUser: true)
        messages.append(userMessage)
        
        let query = inputText
        inputText = ""
        isProcessing = true
        
        Task { @MainActor in
            do {
                let response = try await ragService.sendMessage(query)
                let botMessage = ChatBotMessage(text: response, isUser: false)
                messages.append(botMessage)
                isProcessing = false
            } catch {
                let errorMessage = ChatBotMessage(text: "Error: \(error.localizedDescription)", isUser: false)
                messages.append(errorMessage)
                isProcessing = false
            }
        }
    }
    
    private func saveChatHistory() {
        guard !messages.isEmpty, let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        Task {
            let title = await generateChatTitle()
            let chatData: [String: Any] = [
                "timestamp": Date().timeIntervalSince1970,
                "title": title,
                "messages": messages.map { ["isUser": $0.isUser, "text": $0.text] }
            ]
            
            await MainActor.run {
                database.collection("users").document(userId).collection("chatHistory").addDocument(data: chatData)
            }
        }
    }
    
    private func generateChatTitle() async -> String {
        guard let firstMessage = messages.first(where: { $0.isUser }) else {
            return "Chat Session"
        }
        
        let words = firstMessage.text.split(separator: " ").prefix(5)
        return words.joined(separator: " ")
    }
    
    private func toggleRecording() {
        if audioRecorder.isRecording {
            guard let audioURL = audioRecorder.stopRecording() else {
                return
            }
            processVoiceInput(audioURL: audioURL)
        } else {
            Task {
                try? await audioRecorder.startRecording()
            }
        }
    }
    
    private func processVoiceInput(audioURL: URL) {
        isProcessing = true
        Task { @MainActor in
            do {
                let transcription = try await assemblyAI.transcribeAudio(fileURL: audioURL)
                inputText = transcription
                sendMessage()
            } catch {
                let errorMessage = ChatBotMessage(text: "Voice recognition error: \(error.localizedDescription)", isUser: false)
                messages.append(errorMessage)
                isProcessing = false
            }
        }
    }
    
    private func playLastResponse() {
        guard let lastBotMessage = messages.last(where: { !$0.isUser }) else {
            return
        }
        isPlayingAudio = true
        Task { @MainActor in
            do {
                try await assemblyAI.speakText(lastBotMessage.text)
                isPlayingAudio = false
            } catch {
                isPlayingAudio = false
            }
        }
    }
}

struct ChatBotMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct MessageBubble: View {
    let message: ChatBotMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            if message.isUser {
                Text(message.text)
                    .padding(12)
                    .background(Color(hex: "1976D2"))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .frame(maxWidth: .infinity * 0.75, alignment: .trailing)
            } else {
                MessageTextView(text: message.text)
                    .padding(12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(16)
                    .frame(maxWidth: .infinity * 0.75, alignment: .leading)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct MessageTextView: View {
    let text: String
    
    var body: some View {
        Text(attributedText)
            .tint(.blue)
    }
    
    private var attributedText: AttributedString {
        var attributed = AttributedString(text)
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches.reversed() {
                if let range = Range(match.range, in: text) {
                    let urlString = String(text[range])
                    if let url = URL(string: urlString) {
                        if let attrRange = Range(match.range, in: attributed) {
                            attributed[attrRange].link = url
                            attributed[attrRange].foregroundColor = .blue
                            attributed[attrRange].underlineStyle = .single
                        }
                    }
                }
            }
        }
        return attributed
    }
}

struct ChatHistoryListView: View {
    @State private var chatSessions: [(id: String, data: [String: Any])] = []
    private let database = Firestore.firestore()
    
    var body: some View {
        List {
            ForEach(chatSessions, id: \.id) { session in
                NavigationLink {
                    ChatHistoryDetailView(sessionData: session.data)
                } label: {
                    VStack(alignment: .leading) {
                        Text(session.data["title"] as? String ?? "Chat Session")
                            .font(.headline)
                        if let timestamp = session.data["timestamp"] as? Double {
                            Text(formatDate(timestamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Chat History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadChatHistory()
        }
    }
    
    private func loadChatHistory() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        database.collection("users").document(userId).collection("chatHistory")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    chatSessions = documents.map { (id: $0.documentID, data: $0.data()) }
                }
            }
    }
    
    private func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ChatHistoryDetailView: View {
    let sessionData: [String: Any]
    @State private var messages: [ChatBotMessage] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(messages) { message in
                    MessageBubble(message: message)
                }
            }
            .padding()
        }
        .navigationTitle("Chat Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMessages()
        }
    }
    
    private func loadMessages() {
        guard let messagesData = sessionData["messages"] as? [[String: Any]] else {
            return
        }
        messages = messagesData.compactMap { dict in
            guard let text = dict["text"] as? String,
                  let isUser = dict["isUser"] as? Bool else {
                return nil
            }
            return ChatBotMessage(text: text, isUser: isUser)
        }
    }
}

