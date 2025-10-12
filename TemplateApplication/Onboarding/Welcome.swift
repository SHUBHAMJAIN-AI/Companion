//
// This source file is part of the Stanford Spezi Template Application open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SpeziViews
import SwiftUI


struct Welcome: View {
    @Environment(ManagedNavigationStack.Path.self) private var managedNavigationPath
    
    
    var body: some View {
        OnboardingView(
            title: "Hospitalist Companion",
            subtitle: "Your AI-powered medical companion for healthcare professionals",
            areas: [
                OnboardingInformationView.Area(
                    icon: {
                        Image(systemName: "message.fill")
                            .accessibilityHidden(true)
                    },
                    title: "AI Chat Assistant",
                    description: "Answer all your questions about your hospital protocols."
                ),
                OnboardingInformationView.Area(
                    icon: {
                        Image(systemName: "safari.fill")
                            .accessibilityHidden(true)
                    },
                    title: "Discover",
                    description: "Stay up to date on all your department announcements."
                ),
                OnboardingInformationView.Area(
                    icon: {
                        Image(systemName: "phone.fill")
                            .accessibilityHidden(true)
                    },
                    title: "Directory",
                    description: "An easy way to navigate and find who you need quickly."
                )
            ],
            actionText: "Begin",
            action: {
                managedNavigationPath.nextStep()
            }
        )
        .padding(.top, 24)
    }
}


#if DEBUG
#Preview {
    ManagedNavigationStack {
        Welcome()
    }
}
#endif
