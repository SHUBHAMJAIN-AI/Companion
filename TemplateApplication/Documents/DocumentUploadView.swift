//
// Document Upload Interface for Health Companion
//

import SwiftUI
import UniformTypeIdentifiers
import SpeziViews

struct DocumentUploadView: View {
    @State private var showingDocumentPicker = false
    @State private var uploadedDocuments: [HealthDocument] = []
    @StateObject private var s3Service = AWSS3Service()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                documentContentView
                Spacer()
                uploadButton
            }
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.pdf, .image, .text],
                allowsMultipleSelection: false
            ) { result in
                handleDocumentSelection(result)
            }
        }
    }
    
    private var documentContentView: some View {
        Group {
            if uploadedDocuments.isEmpty {
                emptyStateView
            } else {
                documentListView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Upload Health Documents")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Upload medical reports, lab results, or other health documents to get AI-powered insights")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Upload Document") {
                showingDocumentPicker = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var documentListView: some View {
        List {
            ForEach(uploadedDocuments) { document in
                DocumentRow(document: document)
            }
            .onDelete(perform: deleteDocuments)
        }
    }
    
    private var uploadButton: some View {
        Button("Upload New Document") {
            showingDocumentPicker = true
        }
        .buttonStyle(.bordered)
        .padding()
    }
    
    private func handleDocumentSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                uploadDocument(from: url)
            }
        case .failure(let error):
            print("Document selection failed: \(error)")
        }
    }
    
    private func uploadDocument(from url: URL) {
        let document = HealthDocument(
            name: url.lastPathComponent,
            type: getDocumentType(from: url),
            uploadDate: Date(),
            url: url
        )
        uploadedDocuments.append(document)
        uploadToS3(document)
    }
    
    private func uploadToS3(_ document: HealthDocument) {
        guard let data = try? Data(contentsOf: document.url) else {
            print("Failed to read document data")
            return
        }
        
        Task { @MainActor in
            do {
                let key = try await s3Service.uploadDocument(document, data: data)
                print("Successfully uploaded \(document.name) to S3 with key: \(key)")
            } catch {
                print("Failed to upload to S3: \(error)")
            }
        }
    }
    
    private func getDocumentType(from url: URL) -> DocumentType {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "pdf":
            return .pdf
        case "jpg", "jpeg", "png":
            return .image
        case "txt":
            return .text
        default:
            return .other
        }
    }
    
    private func deleteDocuments(offsets: IndexSet) {
        uploadedDocuments.remove(atOffsets: offsets)
    }
}

struct HealthDocument: Identifiable {
    let id = UUID()
    let name: String
    let type: DocumentType
    let uploadDate: Date
    let url: URL
}

enum DocumentType {
    case pdf, image, text, other
    
    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .image: return "photo.fill"
        case .text: return "text.document.fill"
        case .other: return "doc.fill"
        }
    }
}

struct DocumentRow: View {
    let document: HealthDocument
    
    var body: some View {
        HStack {
            Image(systemName: document.type.icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(document.name)
                    .font(.headline)
                Text("Uploaded \(document.uploadDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}