//
// Feedback View for Doctors
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAdmin = ""
    @State private var feedbackText = ""
    @State private var isSubmitting = false
    private let db = Firestore.firestore()
    
    private let adminEmails = [
        "admin1@hospital.com",
        "admin2@hospital.com",
        "admin3@hospital.com"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Select Administrator") {
                    Picker("Administrator", selection: $selectedAdmin) {
                        Text("Select...").tag("")
                        ForEach(adminEmails, id: \.self) { email in
                            Text(email).tag(email)
                        }
                    }
                }
                
                Section("Your Feedback") {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 150)
                }
                
                Section {
                    Button(action: submitFeedback) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Feedback")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(selectedAdmin.isEmpty || feedbackText.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitFeedback() {
        isSubmitting = true
        
        let feedbackData: [String: Any] = [
            "toEmail": selectedAdmin,
            "message": feedbackText,
            "timestamp": Date().timeIntervalSince1970,
            "read": false
        ]
        
        db.collection("feedback").addDocument(data: feedbackData) { error in
            isSubmitting = false
            if error == nil {
                dismiss()
            }
        }
    }
}
