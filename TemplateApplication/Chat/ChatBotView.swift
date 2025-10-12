//
// ChatBot View for Health Companion
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatBotView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var openAIService = OpenAIService()
    @State private var messages: [ChatBotMessage] = []
    @State private var inputText = ""
    @State private var isProcessing = false
    @FocusState private var isInputFocused: Bool
    private let db = Firestore.firestore()
    
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
            TextField("Ask a question...", text: $inputText)
                .focused($isInputFocused)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: isProcessing ? "hourglass" : "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color(hex: "1976D2"))
                    .clipShape(Circle())
            }
            .disabled(inputText.isEmpty || isProcessing)
        }
        .padding()
        .background(Color.white)
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let userMessage = ChatBotMessage(text: inputText, isUser: true)
        messages.append(userMessage)
        
        let query = inputText
        inputText = ""
        isProcessing = true
        
        Task { @MainActor in
            do {
                let response = try await openAIService.sendMessage(query)
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
        guard !messages.isEmpty, let userId = Auth.auth().currentUser?.uid else { return }
        
        let chatData: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "messages": messages.map { ["isUser": $0.isUser, "text": $0.text] }
        ]
        
        db.collection("users").document(userId).collection("chatHistory").addDocument(data: chatData)
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
            
            Text(message.text)
                .padding(12)
                .background(message.isUser ? Color(hex: "1976D2") : Color.gray.opacity(0.2))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)
                .frame(maxWidth: .infinity * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct ChatHistoryListView: View {
    @State private var chatSessions: [(id: String, data: [String: Any])] = []
    private let db = Firestore.firestore()
    
    var body: some View {
        List {
            ForEach(chatSessions, id: \.id) { session in
                NavigationLink {
                    ChatHistoryDetailView(sessionData: session.data)
                } label: {
                    VStack(alignment: .leading) {
                        Text("Chat Session")
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
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("chatHistory")
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
        guard let messagesData = sessionData["messages"] as? [[String: Any]] else { return }
        messages = messagesData.compactMap { dict in
            guard let text = dict["text"] as? String,
                  let isUser = dict["isUser"] as? Bool else { return nil }
            return ChatBotMessage(text: text, isUser: isUser)
        }
    }
}
