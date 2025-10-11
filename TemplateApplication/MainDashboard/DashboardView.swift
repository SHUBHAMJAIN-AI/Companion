//
// Main Dashboard for RWJUH Hospitalist Companion
//

import SwiftUI

struct DashboardView: View {
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var isRecording = false
    @State private var isProcessing = false
    @State private var chatHistory: [(question: String, answer: String)] = []
    @State private var showDocumentUpload = false
    @State private var showContacts = false
    @State private var showDiscover = false
    @State private var presentingAccount = false
    @FocusState private var isSearchFocused: Bool
    @StateObject private var openAIService = OpenAIService()
    
    var body: some View {
        VStack(spacing: 0) {
            topNavBar
            
            ScrollView {
                VStack(spacing: 20) {
                    searchBar
                    quickActionButtons
                    uploadButton
                    qaCards
                }
                .padding()
            }
            
            bottomNavBar
        }
        .background(Color(UIColor.systemGroupedBackground))
        .sheet(isPresented: $showContacts) {
            Contacts(presentingAccount: $presentingAccount)
        }
        .sheet(isPresented: $showDiscover) {
            DiscoverView()
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
            
            Button("Contact Admin") {
                // Contact admin action
            }
            .foregroundColor(.white)
            .font(.subheadline)
        }
        .padding()
        .background(Color(hex: "1976D2"))
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Q:")
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "1976D2"))
                        Text(chat.question)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(alignment: .top) {
                        Text("A:")
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        Text(chat.answer)
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
    }
    
    private var quickActionButtons: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            QuickActionButton(title: "Order CT Scan", icon: "cross.case.fill")
            QuickActionButton(title: "Cardiology Consult", icon: "heart.fill")
            QuickActionButton(title: "Sepsis Protocol", icon: "waveform.path.ecg")
            QuickActionButton(title: "Stroke Alert", icon: "brain.head.profile")
        }
    }
    
    private var uploadButton: some View {
        Button(action: {
            showDocumentUpload = true
        }) {
            HStack {
                Image(systemName: "doc.badge.plus")
                Text("Scan / Upload Docs")
                    .fontWeight(.medium)
            }
            .foregroundColor(Color(hex: "1976D2"))
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "1976D2"), lineWidth: 2)
            )
        }
        .sheet(isPresented: $showDocumentUpload) {
            DocumentUploadView()
        }
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