//
// Custom Account Setup with Forgot Password
//

import SwiftUI
import FirebaseAuth
import SpeziOnboarding

struct CustomAccountSetup: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showForgotPassword = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var onComplete: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                formSection
                forgotPasswordButton
                actionButton
            }
            .padding()
        }
        .alert("Account", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Your Account")
                .font(.largeTitle)
                .bold()
                .padding(.top, 30)
            
            Picker("", selection: $isSignUp) {
                Text("Sign In").tag(false)
                Text("Sign Up").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 40)
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 15) {
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.top, 20)
    }
    
    private var forgotPasswordButton: some View {
        HStack {
            Spacer()
            Button("Forgot Password?") {
                showForgotPassword = true
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
    }
    
    private var actionButton: some View {
        Button(action: handleAction) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text(isSignUp ? "Sign Up" : "Sign In")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(email.isEmpty || password.isEmpty ? Color.gray : Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
        .disabled(email.isEmpty || password.isEmpty || isLoading)
        .padding(.top, 10)
    }
    
    private func handleAction() {
        isLoading = true
        if isSignUp {
            signUp()
        } else {
            signIn()
        }
    }
    
    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                onComplete()
            }
        }
    }
    
    private func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                onComplete()
            }
        }
    }
}
