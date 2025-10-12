//
// Inbox View for Administrator
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct InboxView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [(id: String, data: [String: Any])] = []
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            List {
                if messages.isEmpty {
                    Text("No messages")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(messages, id: \.id) { message in
                        NavigationLink {
                            FeedbackDetailView(messageData: message.data, messageId: message.id)
                        } label: {
                            messageRow(message.data)
                        }
                    }
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadMessages()
            }
        }
    }
    
    private func messageRow(_ data: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Anonymous Feedback")
                .font(.headline)
            Text(data["message"] as? String ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            if let timestamp = data["timestamp"] as? Double {
                Text(formatDate(timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func loadMessages() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        db.collection("feedback")
            .whereField("toEmail", isEqualTo: userEmail)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    messages = documents.map { (id: $0.documentID, data: $0.data()) }
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

struct FeedbackDetailView: View {
    let messageData: [String: Any]
    let messageId: String
    private let db = Firestore.firestore()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Anonymous Feedback")
                    .font(.headline)
                
                if let timestamp = messageData["timestamp"] as? Double {
                    Text(formatDate(timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                Text(messageData["message"] as? String ?? "")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            markAsRead()
        }
    }
    
    private func markAsRead() {
        db.collection("feedback").document(messageId).updateData(["read": true])
    }
    
    private func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
