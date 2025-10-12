//
// Forgot Password and Username Recovery
//

import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            contentView
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 20) {
            headerSection
            emailField
            resetButton
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .alert("Password Reset", isPresented: $showAlert) {
            Button("OK") {
                if alertMessage.contains("sent") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Reset Password")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("Enter your email address and we'll send you a link to reset your password.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var emailField: some View {
        TextField("Email", text: $email)
            .textFieldStyle(.roundedBorder)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .padding(.horizontal)
            .padding(.top, 20)
    }
    
    private var resetButton: some View {
        Button(action: resetPassword) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("Send Reset Link")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(email.isEmpty ? Color.gray : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
        .padding(.horizontal)
        .disabled(email.isEmpty || isLoading)
    }
    
    private func resetPassword() {
        isLoading = true
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            isLoading = false
            if let error = error {
                alertMessage = error.localizedDescription
            } else {
                alertMessage = "Password reset link has been sent to \(email)"
            }
            showAlert = true
        }
    }
}
