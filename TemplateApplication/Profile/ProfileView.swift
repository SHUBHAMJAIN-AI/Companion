//
// Profile View for Health Companion
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showChangePassword = false
    
    private var currentUser: User? {
        Auth.auth().currentUser
    }
    
    var body: some View {
        NavigationView {
            List {
                profileSection
                settingsSection
                aboutSection
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
            }
        }
    }
    
    private var profileSection: some View {
        Section {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "1976D2"))
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(currentUser?.email ?? "No email")
                        .font(.headline)
                    Text(UserDefaults.standard.string(forKey: "userRole")?.capitalized ?? "User")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let department = UserDefaults.standard.string(forKey: "userDepartment"), !department.isEmpty {
                        Text(department)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 10)
            }
            .padding(.vertical, 10)
        }
    }
    
    private var settingsSection: some View {
        Section {
            NavigationLink {
                EditDepartmentView()
            } label: {
                HStack {
                    Image(systemName: "building.2")
                    Text("Department")
                    Spacer()
                    Text(UserDefaults.standard.string(forKey: "userDepartment") ?? "Not set")
                        .foregroundColor(.secondary)
                }
            }
            
            Button {
                showChangePassword = true
            } label: {
                HStack {
                    Image(systemName: "lock.rotation")
                    Text("Change Password")
                }
            }
        }
    }
    
    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                    Text("About")
                }
            }
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                passwordFields
                errorSection
                updateButton
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var passwordFields: some View {
        Section {
            SecureField("New Password", text: $newPassword)
            SecureField("Confirm Password", text: $confirmPassword)
        }
    }
    
    @ViewBuilder
    private var errorSection: some View {
        if !errorMessage.isEmpty {
            Section {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private var updateButton: some View {
        Section {
            Button {
                changePassword()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Update Password")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(newPassword.isEmpty || confirmPassword.isEmpty || isLoading)
        }
    }
    
    private func changePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                dismiss()
            }
        }
    }
}

struct EditDepartmentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var department = UserDefaults.standard.string(forKey: "userDepartment") ?? ""
    
    var body: some View {
        Form {
            Section {
                TextField("Department (Optional)", text: $department)
            }
            
            Section {
                Button("Save") {
                    UserDefaults.standard.set(department, forKey: "userDepartment")
                    dismiss()
                }
            }
        }
        .navigationTitle("Edit Department")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("2024.1")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Text("Health Companion is an AI-powered medical assistant designed for healthcare professionals.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Link(destination: URL(string: "https://github.com/SHUBHAMJAIN-AI/Companion")!) {
                    HStack {
                        Image(systemName: "link")
                        Text("GitHub Repository")
                    }
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
