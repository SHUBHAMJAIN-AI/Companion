//
// This source file is part of the Stanford Spezi Template Application open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

@_spi(TestingSupport) import SpeziAccount
import SpeziFirebaseAccount
import SpeziHealthKit
import SpeziNotifications
import SpeziOnboarding
import SpeziViews
import SwiftUI


/// Displays an multi-step onboarding flow for Health Companion.
struct OnboardingFlow: View {
    enum Step: String, CaseIterable {
        case roleSelection
        case welcome
        case interestingModules
        case consent
        case healthKitPermissions
        case notificationPermissions
        case accountSetup
    }
    @Environment(HealthKit.self) private var healthKit
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.notificationSettings) private var notificationSettings
    
    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
    @State private var onboardingSteps: [Step] = [.roleSelection]
    
    @State private var localNotificationAuthorization = false
    
    
    @MainActor private var healthKitAuthorization: Bool {
        // As HealthKit not available in preview simulator
        if ProcessInfo.processInfo.isPreviewSimulator {
            return false
        }
        return healthKit.isFullyAuthorized
    }
    
    var body: some View {
        ManagedNavigationStack(didComplete: $completedOnboardingFlow) {
            Welcome()
            
            RoleSelectionView(onboardingSteps: $onboardingSteps)
            LoginView()
#if !(targetEnvironment(simulator) && (arch(i386) || arch(x86_64)))
            Consent()
#endif
        }
        .interactiveDismissDisabled(!completedOnboardingFlow)
    }
}


#if DEBUG
#Preview {
    OnboardingFlow()
        .previewWith(standard: TemplateApplicationStandard()) {
            HealthKit()
            AccountConfiguration(service: InMemoryAccountService())
            TemplateApplicationScheduler()
        }
}
#endif
