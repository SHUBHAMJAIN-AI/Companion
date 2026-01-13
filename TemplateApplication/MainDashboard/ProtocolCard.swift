//
// Protocol Card Component
//

import SwiftUI

struct ProtocolCard: View {
    let protocolItem: ProtocolItem

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: protocolItem.icon)
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "1976D2"))
                .frame(width: 50)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(protocolItem.title).font(.headline).foregroundColor(.primary)
                Text("\(protocolItem.items.count) items").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .accessibilityHidden(true)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct ProtocolDetailView: View {
    let protocolItem: ProtocolItem

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Array(protocolItem.items.enumerated()), id: \.offset) { _, item in
                    ProtocolItemCard(text: item)
                }
            }
            .padding()
        }
        .navigationTitle(protocolItem.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProtocolItemCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}
