//
// Protocols View with Flashcards
//

import SwiftUI

struct ProtocolItem: Identifiable, Codable {
    let id: String
    let title: String
    let icon: String
    let items: [String]
}

struct ProtocolsView: View {
    @State private var protocols: [ProtocolItem] = []
    @State private var searchText = ""
    
    var filteredProtocols: [ProtocolItem] {
        searchText.isEmpty ? protocols : protocols.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            contentView
        }
        .onAppear(perform: loadProtocols)
    }
    
    private var contentView: some View {
        VStack {
            searchBar
            protocolsList
        }
        .navigationTitle("Protocols")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            TextField("Search protocols...", text: $searchText).textFieldStyle(.plain)
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var protocolsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredProtocols) { protocolItem in
                    NavigationLink(destination: ProtocolDetailView(protocolItem: protocolItem)) {
                        ProtocolCard(protocolItem: protocolItem)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
    
    private func loadProtocols() {
        guard let url = Bundle.main.url(forResource: "protocols", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ProtocolItem].self, from: data) else { return }
        protocols = decoded
    }
}
