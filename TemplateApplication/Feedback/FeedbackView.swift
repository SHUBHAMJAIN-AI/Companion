//
// Feedback View for Doctors
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct Department: Identifiable {
    let id = UUID()
    let name: String
    let email: String
}

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAdmin = ""
    @State private var feedbackText = ""
    @State private var isSubmitting = false
    private let db = Firestore.firestore()
    
    private let departments = [
        Department(name: "Cardiology", email: "cardiology@hospital.com"),
        Department(name: "Emergency Medicine", email: "emergency@hospital.com"),
        Department(name: "Internal Medicine", email: "internalmedicine@hospital.com"),
        Department(name: "Surgery", email: "surgery@hospital.com"),
        Department(name: "Administration", email: "admin@hospital.com")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Select Department") {
                    Picker("Department", selection: $selectedAdmin) {
                        Text("Select...").tag("")
                        ForEach(departments) { dept in
                            Text("\(dept.name) - \(dept.email)").tag(dept.email)
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
