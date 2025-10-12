//
// This source file is part of the Stanford Spezi Template Application open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

@_spi(TestingSupport) import SpeziAccount
import SpeziOnboarding
import SpeziViews
import SwiftUI


struct AccountOnboarding: View {
    @Environment(ManagedNavigationStack.Path.self) private var managedNavigationPath
    
    var body: some View {
        CustomAccountSetup {
            managedNavigationPath.nextStep()
        }
        .navigationTitle(Text(verbatim: ""))
        .toolbar(.visible)
    }
}


#if DEBUG
#Preview("Account Onboarding SignIn") {
    ManagedNavigationStack {
        AccountOnboarding()
    }
    .previewWith {
        AccountConfiguration(service: InMemoryAccountService())
    }
}

#Preview("Account Onboarding") {
    var details = AccountDetails()
    details.userId = "lelandstanford@stanford.edu"
    details.name = PersonNameComponents(givenName: "Leland", familyName: "Stanford")
    
    return ManagedNavigationStack {
        AccountOnboarding()
    }
    .previewWith {
        AccountConfiguration(service: InMemoryAccountService(), activeDetails: details)
    }
}
#endif
