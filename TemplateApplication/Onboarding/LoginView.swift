//
// Login View for Health Companion
//

import FirebaseAuth
import SpeziOnboarding
import SpeziViews
import SwiftUI

struct LoginView: View {
    @Environment(ManagedNavigationStack.Path.self) private var managedNavigationPath
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isSignUpMode = false
    @State private var showForgotPassword = false
    
    var body: some View {
        VStack(spacing: 30) {
            headerView
            formFields
            Spacer()
            loginButton
        }
        .padding()
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private var forgotPasswordButton: some View {
        HStack {
            Spacer()
            Button("Forgot Password?") {
                showForgotPassword = true
            }
            .font(.subheadline)
            .foregroundColor(Color(hex: "1976D2"))
        }
        .padding(.top, 4)
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "1976D2"))
                .accessibilityHidden(true)

            Text(isSignUpMode ? "Create Account" : "Welcome Back")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(isSignUpMode ? "Sign up to get started" : "Sign in to continue")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
    
    private var formFields: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Enter your email", text: $username)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                
                if !isSignUpMode {
                    forgotPasswordButton
                }
            }
        }
    }
    
    private var loginButton: some View {
        VStack(spacing: 15) {
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                isSignUpMode ? signUp() : login()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUpMode ? "Sign Up" : "Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color(hex: "1976D2") : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!isFormValid || isLoading)
            
            Button {
                isSignUpMode.toggle()
                errorMessage = ""
            } label: {
                Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "1976D2"))
            }
        }
        .padding(.bottom, 40)
    }
    
    private var isFormValid: Bool {
        !username.isEmpty && username.contains("@") && !password.isEmpty
    }
    
    private func login() {
        isLoading = true
        errorMessage = ""
        
        Auth.auth().signIn(withEmail: username, password: password) { _, error in
            isLoading = false
            if error != nil {
                errorMessage = "Invalid email or password"
            } else {
                managedNavigationPath.nextStep()
            }
        }
    }
    
    private func signUp() {
        isLoading = true
        errorMessage = ""
        
        Auth.auth().createUser(withEmail: username, password: password) { _, error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                managedNavigationPath.nextStep()
            }
        }
    }
}
