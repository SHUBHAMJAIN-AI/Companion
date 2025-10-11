//
// This source file is part of the Stanford Spezi Template Application open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import SpeziAccount
import SpeziContact
import SwiftUI


/// Displays the contacts for the Spezi Template Application.
struct Contacts: View {
    @State private var selectedTab = 0
    @Environment(Account.self) private var account: Account?
    @Binding var presentingAccount: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Contact Type", selection: $selectedTab) {
                    Text("On Call Doctors").tag(0)
                    Text("All Contacts").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    ContactsList(contacts: onCallDoctors)
                } else {
                    ContactsList(contacts: allContacts)
                }
            }
            .navigationTitle("Contacts")
            .toolbar {
                if account != nil {
                    AccountButton(isPresented: $presentingAccount)
                }
            }
        }
    }
    
    private var onCallDoctors: [Contact] {
        [
            Contact(
                name: PersonNameComponents(givenName: "Sarah", familyName: "Johnson"),
                image: Image(systemName: "stethoscope.circle.fill"),
                title: "Cardiologist - On Call",
                description: "Cardiology specialist available for urgent consultations",
                organization: "RWJUH",
                contactOptions: [.call("+1 (732) 555-0101"), .text("+1 (732) 555-0101")]
            ),
            Contact(
                name: PersonNameComponents(givenName: "Michael", familyName: "Chen"),
                image: Image(systemName: "cross.case.circle.fill"),
                title: "Emergency Medicine - On Call",
                description: "Emergency department attending physician",
                organization: "RWJUH",
                contactOptions: [.call("+1 (732) 555-0102"), .text("+1 (732) 555-0102")]
            )
        ]
    }
    
    private var allContacts: [Contact] {
        [
            Contact(
                name: PersonNameComponents(givenName: "Emily", familyName: "Rodriguez"),
                image: Image(systemName: "person.circle.fill"),
                title: "Chief of Medicine",
                description: "Department head and internal medicine specialist",
                organization: "RWJUH",
                contactOptions: [.call("+1 (732) 555-0201"), .email(addresses: ["e.rodriguez@rwjuh.edu"])]
            ),
            Contact(
                name: PersonNameComponents(givenName: "David", familyName: "Kim"),
                image: Image(systemName: "brain.head.profile"),
                title: "Neurologist",
                description: "Neurology department specialist",
                organization: "RWJUH",
                contactOptions: [.call("+1 (732) 555-0202"), .email(addresses: ["d.kim@rwjuh.edu"])]
            ),
            Contact(
                name: PersonNameComponents(givenName: "Lisa", familyName: "Patel"),
                image: Image(systemName: "heart.circle.fill"),
                title: "Cardiologist",
                description: "Cardiovascular medicine specialist",
                organization: "RWJUH",
                contactOptions: [.call("+1 (732) 555-0203"), .email(addresses: ["l.patel@rwjuh.edu"])]
            )
        ]
    }
    
    
    init(presentingAccount: Binding<Bool>) {
        self._presentingAccount = presentingAccount
    }
}


#if DEBUG
#Preview {
    Contacts(presentingAccount: .constant(false))
}
#endif
