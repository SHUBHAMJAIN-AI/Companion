//
// Document Upload Interface for Health Companion
//

import SwiftUI
import UniformTypeIdentifiers
import SpeziViews

struct DocumentUploadView: View {
    @State private var showingDocumentPicker = false
    @State private var showingCamera = false
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
            .sheet(isPresented: $showingCamera) {
                ImagePicker(onImagePicked: handleCameraCapture)
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
            
            HStack(spacing: 15) {
                Button(action: { showingCamera = true }) {
                    VStack {
                        Image(systemName: "camera.fill")
                        Text("Camera")
                            .font(.caption)
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: { showingDocumentPicker = true }) {
                    VStack {
                        Image(systemName: "doc.fill")
                        Text("Files")
                            .font(.caption)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
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
        HStack(spacing: 15) {
            Button(action: { showingCamera = true }) {
                Label("Camera", systemImage: "camera.fill")
            }
            .buttonStyle(.bordered)
            
            Button(action: { showingDocumentPicker = true }) {
                Label("Files", systemImage: "doc.fill")
            }
            .buttonStyle(.bordered)
        }
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
    
    private func handleCameraCapture(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let filename = "photo_\(Date().timeIntervalSince1970).jpg"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tempURL)
        uploadDocument(from: tempURL)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
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