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
            title: "Health Companion",
            subtitle: "Your AI-powered medical assistant for healthcare professionals",
            areas: [
                OnboardingInformationView.Area(
                    icon: {
                        Image(systemName: "message.fill")
                            .accessibilityHidden(true)
                    },
                    title: "AI Chat Assistant",
                    description: "Get instant insights from your medical documents using advanced AI"
                ),
                OnboardingInformationView.Area(
                    icon: {
                        Image(systemName: "doc.fill")
                            .accessibilityHidden(true)
                    },
                    title: "Document Analysis",
                    description: "Upload and analyze medical reports, lab results, and patient documents"
                ),
                OnboardingInformationView.Area(
                    icon: {
                        Image(systemName: "mic.fill")
                            .accessibilityHidden(true)
                    },
                    title: "Voice Interface",
                    description: "Ask questions using speech and receive spoken responses"
                )
            ],
            actionText: "Learn More",
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
