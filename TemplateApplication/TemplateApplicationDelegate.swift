//
// This source file is part of the Stanford Spezi Template Application open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseCore
import class FirebaseFirestore.FirestoreSettings
import class FirebaseFirestore.MemoryCacheSettings
import Spezi
import SpeziAccount
import SpeziFirebaseAccount
import SpeziFirebaseAccountStorage
import SpeziFirebaseStorage
import SpeziFirestore
import SpeziHealthKit
import SpeziNotifications
import SpeziOnboarding
import SpeziScheduler
import SwiftUI


class TemplateApplicationDelegate: SpeziAppDelegate {
    override init() {
        FirebaseApp.configure()
        super.init()
    }
    override var configuration: Configuration {
        Configuration(standard: TemplateApplicationStandard()) {
            if !FeatureFlags.disableFirebase {
                AccountConfiguration(
                    service: FirebaseAccountService(providers: [.emailAndPassword], emulatorSettings: nil),
                    storageProvider: FirestoreAccountStorage(storeIn: FirebaseConfiguration.userCollection),
                    configuration: [
                        .requires(\.userId),
                        .requires(\.name)
                    ]
                )
                
                firestore
                FirebaseStorageConfiguration()
            }
            
            healthKit
            
            TemplateApplicationScheduler()
            Scheduler()
            
            Notifications()
        }
    }
    
    private var accountEmulator: (host: String, port: Int)? {
        if FeatureFlags.useFirebaseEmulator {
            (host: "localhost", port: 9099)
        } else {
            nil
        }
    }
    
    private var firestore: Firestore {
        Firestore(settings: FirestoreSettings())
    }
    
    private var healthKit: HealthKit {
        HealthKit {
            CollectSample(.stepCount)
            CollectSample(.heartRate)
        }
    }
}
