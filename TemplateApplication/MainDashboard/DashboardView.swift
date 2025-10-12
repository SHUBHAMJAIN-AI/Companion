//
// Main Dashboard for RWJUH Hospitalist Companion
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DashboardView: View {
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var isRecording = false
    @State private var isProcessing = false
    @State private var chatHistory: [(question: String, answer: String)] = []
    @State private var showDocumentUpload = false
    @State private var showContacts = false
    @State private var showDiscover = false
    @State private var showProfile = false
    @State private var showChatBot = false
    @State private var showInbox = false
    @State private var showFeedback = false
    @State private var unreadCount = 0
    @State private var presentingAccount = false
    @FocusState private var isSearchFocused: Bool
    @StateObject private var openAIService = OpenAIService()
    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
    
    private var userRole: String {
        UserDefaults.standard.string(forKey: "userRole") ?? "doctor"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            topNavBar
            
            ScrollView {
                VStack(spacing: 20) {
                    searchBar
                    if userRole == "administrator" {
                        inboxButton
                        uploadButton
                    } else {
                        feedbackButton
                    }
                    qaCards
                }
                .padding()
            }
            
            bottomNavBar
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            if userRole == "administrator" {
                loadUnreadCount()
            }
        }
        .sheet(isPresented: $showContacts) {
            Contacts(presentingAccount: $presentingAccount)
        }
        .sheet(isPresented: $showDiscover) {
            DiscoverView()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showChatBot) {
            ChatBotView()
        }
        .sheet(isPresented: $showInbox) {
            InboxView()
        }
        .onChange(of: showInbox) { _, isShowing in
            if !isShowing && userRole == "administrator" {
                loadUnreadCount()
            }
        }
        .sheet(isPresented: $showFeedback) {
            FeedbackView()
        }
    }
    
    private func sendQuery() {
        guard !searchText.isEmpty else { return }
        
        isProcessing = true
        let query = searchText
        searchText = ""
        
        Task { @MainActor in
            do {
                let response = try await openAIService.sendMessage(query)
                chatHistory.insert((question: query, answer: response), at: 0)
                isProcessing = false
            } catch {
                print("OpenAI Error: \(error)")
                chatHistory.insert((question: query, answer: "Error: \(error.localizedDescription)"), at: 0)
                isProcessing = false
            }
        }
    }
    
    private var topNavBar: some View {
        HStack {
            Text("RWJUH Hospitalist Companion")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Logout") {
                logout()
            }
            .foregroundColor(.white)
            .font(.subheadline)
        }
        .padding()
        .background(Color(hex: "1976D2"))
    }
    
    private func logout() {
        try? Auth.auth().signOut()
        completedOnboardingFlow = false
    }
    
    private var searchBar: some View {
        VStack(spacing: 10) {
            searchInputRow
            if isProcessing {
                processingIndicator
            }
            if !chatHistory.isEmpty {
                chatHistoryView
            }
        }
    }
    
    private var searchInputRow: some View {
        HStack {
            TextField("Ask a hospital workflow question…", text: $searchText)
                .focused($isSearchFocused)
                .textFieldStyle(.plain)
                .padding(12)
            
            Button(action: {
                isRecording.toggle()
            }) {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .foregroundColor(Color(hex: "1976D2"))
            }
            .padding(.trailing, 8)
            
            if !searchText.isEmpty {
                sendButton
            }
        }
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    private var sendButton: some View {
        Button(action: sendQuery) {
            Image(systemName: "paperplane.fill")
                .foregroundColor(.white)
                .padding(8)
                .background(Color(hex: "1976D2"))
                .clipShape(Circle())
        }
        .padding(.trailing, 8)
    }
    
    private var processingIndicator: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("AI is thinking...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var chatHistoryView: some View {
        VStack(spacing: 12) {
            ForEach(Array(chatHistory.enumerated()), id: \.offset) { _, chat in
                ChatHistoryCard(question: chat.question, answer: chat.answer)
            }
        }
    }
    
    private var inboxButton: some View {
        InboxButtonWithBadge(unreadCount: unreadCount) { showInbox = true }
    }
    
    private func loadUnreadCount() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        Firestore.firestore().collection("feedback")
            .whereField("toEmail", isEqualTo: userEmail)
            .whereField("read", isEqualTo: false)
            .getDocuments { snapshot, _ in
                unreadCount = snapshot?.documents.count ?? 0
            }
    }
    
    private var uploadButton: some View {
        ActionButton(icon: "doc.badge.plus", title: "Scan / Upload Docs") { showDocumentUpload = true }
            .sheet(isPresented: $showDocumentUpload) { DocumentUploadView() }
    }
    
    private var feedbackButton: some View {
        ActionButton(icon: "message.badge", title: "Send Feedback") { showFeedback = true }
    }
    
    private var qaCards: some View {
        VStack(spacing: 15) {
            QACard(
                question: "How do I order a CT abdomen with contrast?",
                answer: "In Epic, choose *OrderSet → CT Abdomen + Pelvis w/Contrast*. " +
                       "Ensure indication, renal function, and allergies are documented. " +
                       "Notify Radiology via extension 8945 for urgent scans."
            )
            QACard(
                question: "Who do I call for cardiology consults after hours?",
                answer: "Page on-call cardiologist via operator (555-1111). " +
                       "After hours, use the cardiology night float pager listed in the on-call schedule."
            )
        }
    }
    
    private var bottomNavBar: some View {
        HStack(spacing: 0) {
            BottomNavItem(icon: "message.fill", label: "Ask", isSelected: selectedTab == 0) {
                selectedTab = 0
                showChatBot = true
            }
            BottomNavItem(icon: "list.bullet.clipboard", label: "Protocols", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            BottomNavItem(icon: "safari.fill", label: "Discover", isSelected: selectedTab == 2) {
                selectedTab = 2
                showDiscover = true
            }
            BottomNavItem(icon: "person.fill", label: "Profile", isSelected: selectedTab == 3) {
                selectedTab = 3
                showProfile = true
            }
            BottomNavItem(icon: "phone.fill", label: "Contact", isSelected: selectedTab == 4) {
                selectedTab = 4
                showContacts = true
            }
        }
        .padding(.vertical, 8)
        .background(Color.white)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: -2)
    }
}

struct ChatHistoryCard: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Q:")
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "1976D2"))
                Text(question)
                    .fontWeight(.semibold)
            }
            HStack(alignment: .top) {
                Text("A:")
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                Text(answer)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 5, x: 0, y: 2)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(hex: "1976D2"))
            .cornerRadius(12)
        }
    }
}

struct QACard: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Q:")
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "1976D2"))
                Text(question)
                    .fontWeight(.semibold)
            }
            
            HStack(alignment: .top) {
                Text("A:")
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                Text(answer)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 5, x: 0, y: 2)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title).fontWeight(.medium)
            }
            .foregroundColor(Color(hex: "1976D2"))
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "1976D2"), lineWidth: 2))
        }
    }
}

struct InboxButtonWithBadge: View {
    let unreadCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "tray.fill")
                Text("Inbox").fontWeight(.medium)
                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(Color(hex: "1976D2"))
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "1976D2"), lineWidth: 2))
        }
    }
}

struct BottomNavItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? Color(hex: "1976D2") : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}