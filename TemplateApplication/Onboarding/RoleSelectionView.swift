//
// Role Selection for Health Companion Users
//

import SwiftUI
import SpeziViews
import SpeziOnboarding

struct RoleSelectionView: View {
    @Environment(ManagedNavigationStack.Path.self) private var managedNavigationPath
    @Binding var onboardingSteps: [OnboardingFlow.Step]
    @State private var selectedRole: UserRole?
    
    var body: some View {
        VStack(spacing: 30) {
            headerView
            roleCardsView
            Spacer()
            continueButton
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Text("Welcome to Hospitalist Companion")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Select your role to get started")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
    
    private var roleCardsView: some View {
        VStack(spacing: 20) {
            RoleCard(
                role: .doctor,
                title: "Doctor",
                description: "",
                icon: "stethoscope",
                isSelected: selectedRole == .doctor
            ) {
                selectedRole = .doctor
            }
            
            RoleCard(
                role: .administrator,
                title: "Administrator",
                description: "",
                icon: "person.badge.key",
                isSelected: selectedRole == .administrator
            ) {
                selectedRole = .administrator
            }
        }
        .padding(.horizontal)
    }
    
    private var continueButton: some View {
        Button("Continue") {
            if let role = selectedRole {
                UserDefaults.standard.set(role.rawValue, forKey: "userRole")
                managedNavigationPath.nextStep()
            }
        }
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(selectedRole == nil ? Color.gray : Color.blue)
        .cornerRadius(12)
        .disabled(selectedRole == nil)
        .padding(.horizontal)
        .padding(.bottom, 40)
    }
}

struct RoleCard: View {
    let role: UserRole
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    if !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum UserRole: String, CaseIterable {
    case doctor = "doctor"
    case resident = "resident"
    case administrator = "administrator"
    
    var displayName: String {
        switch self {
        case .doctor: return "Doctor"
        case .resident: return "Resident"
        case .administrator: return "Administrator"
        }
    }
}