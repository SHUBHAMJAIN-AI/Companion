//
// This source file is part of the Stanford Spezi Template Application open-source project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseFirestore
import Foundation
import SpeziAccount
import SpeziContact
import SwiftUI


/// Displays the contacts for the Spezi Template Application.
struct Contacts: View {
    @State private var selectedTab = 0
    @State private var allContacts: [StaffContact] = []
    @Environment(Account.self) private var account: Account?
    @Binding var presentingAccount: Bool
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Contacts")
                .toolbar { toolbarContent }
                .task { await loadContacts() }
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            Picker("Contact Type", selection: $selectedTab) {
                Text("On Call Doctors").tag(0)
                Text("All Contacts").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if selectedTab == 0 {
                OnCallDoctorsView()
            } else {
                AllContactsList(contacts: allContacts)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Upload Data") {
                Task {
                    await ContactsService.shared.uploadInitialContacts()
                    await loadContacts()
                }
            }
        }
        if account != nil {
            ToolbarItem {
                AccountButton(isPresented: $presentingAccount)
            }
        }
    }
    
    private func loadContacts() async {
        allContacts = await ContactsService.shared.fetchContacts()
    }

    init(presentingAccount: Binding<Bool>) {
        self._presentingAccount = presentingAccount
    }
}

struct OnCallDoctorsView: View {
    var body: some View {
        ScrollView {
            doctorsList
        }
    }
    
    private var doctorsList: some View {
        VStack(spacing: 15) {
            onCallCard(
                icon: "heart.circle.fill",
                dept: "Cardiology - On Call",
                desc: "Cardiology specialist available for urgent consultations",
                phone: "+1 (732) 555-0101"
            )
            onCallCard(
                icon: "cross.case.circle.fill",
                dept: "Emergency Medicine - On Call",
                desc: "Emergency department attending physician",
                phone: "+1 (732) 555-0102"
            )
            onCallCard(
                icon: "lungs.fill",
                dept: "Internal Medicine - On Call",
                desc: "Hospitalist for general medicine consultations",
                phone: "+1 (732) 555-0103"
            )
            onCallCard(
                icon: "scissors.circle.fill",
                dept: "Surgery - On Call",
                desc: "General surgery attending for urgent cases",
                phone: "+1 (732) 555-0104"
            )
            onCallCard(
                icon: "camera.circle.fill",
                dept: "Radiology - On Call",
                desc: "Radiologist for urgent imaging interpretation",
                phone: "+1 (732) 555-0105"
            )
            onCallCard(
                icon: "brain.head.profile",
                dept: "Neurology - On Call",
                desc: "Neurologist for stroke and neuro emergencies",
                phone: "+1 (732) 555-0106"
            )
            onCallCard(
                icon: "bandage.fill",
                dept: "Orthopedics - On Call",
                desc: "Orthopedic surgeon for fractures and trauma",
                phone: "+1 (732) 555-0107"
            )
            onCallCard(
                icon: "figure.2.circle.fill",
                dept: "OB/GYN - On Call",
                desc: "Obstetrics and gynecology specialist",
                phone: "+1 (732) 555-0108"
            )
        }
        .padding()
    }
    
    private func onCallCard(icon: String, dept: String, desc: String, phone: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "1976D2"))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(dept).font(.headline).foregroundColor(.primary)
                Text(desc).font(.caption).foregroundColor(.secondary).lineLimit(2)
            }
            Spacer()
            HStack(spacing: 20) {
                Button { call(phone) } label: {
                    Image(systemName: "phone.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.green)
                        .clipShape(Circle())
                        .accessibilityLabel("Call \(dept)")
                }
                Button { message(phone) } label: {
                    Image(systemName: "message.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color(hex: "1976D2"))
                        .clipShape(Circle())
                        .accessibilityLabel("Message \(dept)")
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 5, x: 0, y: 2)
    }

    private func call(_ phone: String) {
        let clean = phone
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "tel://\(clean)") {
            UIApplication.shared.open(url)
        }
    }

    private func message(_ phone: String) {
        let clean = phone
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "sms://\(clean)") {
            UIApplication.shared.open(url)
        }
    }
}

struct StaffContact: Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let title: String
    let description: String
    let phone: String
    let email: String
    let icon: String
}

final class ContactsService: Sendable {
    static let shared = ContactsService()
    
    private var initialContactsData: [[String: String]] {
        [
            [
                "firstName": "Emily",
                "lastName": "Rodriguez",
                "title": "Chief of Medicine",
                "description": "Department head and internal medicine specialist",
                "phone": "+1 (732) 555-0201",
                "email": "e.rodriguez@rwjuh.edu",
                "icon": "person.circle.fill"
            ],
            [
                "firstName": "David",
                "lastName": "Kim",
                "title": "Neurologist",
                "description": "Neurology department specialist",
                "phone": "+1 (732) 555-0202",
                "email": "d.kim@rwjuh.edu",
                "icon": "brain.head.profile"
            ],
            [
                "firstName": "Lisa",
                "lastName": "Patel",
                "title": "Cardiologist",
                "description": "Cardiovascular medicine specialist",
                "phone": "+1 (732) 555-0203",
                "email": "l.patel@rwjuh.edu",
                "icon": "heart.circle.fill"
            ],
            [
                "firstName": "Thomas",
                "lastName": "Anderson",
                "title": "Pharmacist",
                "description": "Clinical pharmacy specialist",
                "phone": "+1 (732) 555-0204",
                "email": "t.anderson@rwjuh.edu",
                "icon": "pills.circle.fill"
            ],
            [
                "firstName": "Maria",
                "lastName": "Garcia",
                "title": "Nurse Manager",
                "description": "Nursing supervisor for medical floors",
                "phone": "+1 (732) 555-0205",
                "email": "m.garcia@rwjuh.edu",
                "icon": "cross.circle.fill"
            ],
            [
                "firstName": "Kevin",
                "lastName": "O'Brien",
                "title": "ICU Director",
                "description": "Intensive care unit medical director",
                "phone": "+1 (732) 555-0206",
                "email": "k.obrien@rwjuh.edu",
                "icon": "waveform.path.ecg.rectangle.fill"
            ],
            [
                "firstName": "Sophia",
                "lastName": "Zhang",
                "title": "Pulmonologist",
                "description": "Pulmonary and critical care medicine",
                "phone": "+1 (732) 555-0207",
                "email": "s.zhang@rwjuh.edu",
                "icon": "staroflife.circle.fill"
            ],
            [
                "firstName": "Daniel",
                "lastName": "Murphy",
                "title": "Nephrologist",
                "description": "Kidney disease and dialysis specialist",
                "phone": "+1 (732) 555-0208",
                "email": "d.murphy@rwjuh.edu",
                "icon": "drop.circle.fill"
            ],
            [
                "firstName": "Patricia",
                "lastName": "Wilson",
                "title": "Infectious Disease",
                "description": "Infectious disease and antimicrobial stewardship",
                "phone": "+1 (732) 555-0209",
                "email": "p.wilson@rwjuh.edu",
                "icon": "allergens.fill"
            ],
            [
                "firstName": "Christopher",
                "lastName": "Taylor",
                "title": "Gastroenterologist",
                "description": "GI and hepatology specialist",
                "phone": "+1 (732) 555-0210",
                "email": "c.taylor@rwjuh.edu",
                "icon": "stomach.fill"
            ],
            [
                "firstName": "Angela",
                "lastName": "Davis",
                "title": "Physical Therapy",
                "description": "Physical therapy department coordinator",
                "phone": "+1 (732) 555-0211",
                "email": "a.davis@rwjuh.edu",
                "icon": "figure.walk.circle.fill"
            ],
            [
                "firstName": "Mark",
                "lastName": "Robinson",
                "title": "Social Worker",
                "description": "Patient care coordination and discharge planning",
                "phone": "+1 (732) 555-0212",
                "email": "m.robinson@rwjuh.edu",
                "icon": "person.text.rectangle.fill"
            ],
            [
                "firstName": "Nicole",
                "lastName": "Harris",
                "title": "Hospital Administrator",
                "description": "Operations and administrative services",
                "phone": "+1 (732) 555-0213",
                "email": "n.harris@rwjuh.edu",
                "icon": "building.2.circle.fill"
            ],
            [
                "firstName": "Steven",
                "lastName": "Clark",
                "title": "Lab Director",
                "description": "Clinical laboratory services director",
                "phone": "+1 (732) 555-0214",
                "email": "s.clark@rwjuh.edu",
                "icon": "chart.bar.doc.horizontal.fill"
            ],
            [
                "firstName": "Michelle",
                "lastName": "Lewis",
                "title": "Blood Bank",
                "description": "Transfusion medicine specialist",
                "phone": "+1 (732) 555-0215",
                "email": "m.lewis@rwjuh.edu",
                "icon": "cross.vial.fill"
            ]
        ]
    }
    
    func uploadInitialContacts() async {
        let database = Firestore.firestore()
        for contact in initialContactsData {
            try? await database.collection("contacts").addDocument(data: contact)
        }
        print("Uploaded \(initialContactsData.count) contacts to Firestore")
    }

    func fetchContacts() async -> [StaffContact] {
        do {
            let database = Firestore.firestore()
            let snapshot = try await database.collection("contacts").getDocuments()
            return snapshot.documents.compactMap { doc in
                let data = doc.data()
                guard let firstName = data["firstName"] as? String,
                      let lastName = data["lastName"] as? String,
                      let title = data["title"] as? String,
                      let description = data["description"] as? String,
                      let phone = data["phone"] as? String,
                      let email = data["email"] as? String,
                      let icon = data["icon"] as? String else { return nil }
                return StaffContact(
                    id: doc.documentID,
                    firstName: firstName,
                    lastName: lastName,
                    title: title,
                    description: description,
                    phone: phone,
                    email: email,
                    icon: icon
                )
            }
        } catch {
            print("Error fetching contacts: \(error)")
            return []
        }
    }
}

struct AllContactsList: View {
    let contacts: [StaffContact]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(contacts.indices, id: \.self) { index in
                    AllContactCard(contact: contacts[index])
                }
            }
            .padding()
        }
    }
}

struct AllContactCard: View {
    let contact: StaffContact

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: contact.icon)
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "1976D2"))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(contact.firstName) \(contact.lastName)")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(contact.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(contact.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            HStack(spacing: 15) {
                Button { call(contact.phone) } label: {
                    Image(systemName: "phone.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.green)
                        .clipShape(Circle())
                        .accessibilityLabel("Call \(contact.firstName)")
                }
                Button { email(contact.email) } label: {
                    Image(systemName: "envelope.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color(hex: "1976D2"))
                        .clipShape(Circle())
                        .accessibilityLabel("Email \(contact.firstName)")
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 5, x: 0, y: 2)
    }
    
    private func call(_ phone: String) {
        let clean = phone
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "tel://\(clean)") {
            UIApplication.shared.open(url)
        }
    }

    private func email(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}

#if DEBUG
#Preview {
    Contacts(presentingAccount: .constant(false))
}
#endif
