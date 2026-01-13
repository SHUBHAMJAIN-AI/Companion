//
// Storage Service Protocol
// Defines interface for document storage providers (S3, Firestore, etc.)
//

import Foundation

/// Represents a stored document with metadata
struct StoredDocument: Identifiable, Codable {
    let id: String
    let filename: String
    let contentType: String
    let size: Int
    let uploadedAt: Date
    let uploadedBy: String?
    let storagePath: String
    let metadata: [String: String]?

    init(
        id: String,
        filename: String,
        contentType: String,
        size: Int,
        uploadedAt: Date = Date(),
        uploadedBy: String? = nil,
        storagePath: String,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.filename = filename
        self.contentType = contentType
        self.size = size
        self.uploadedAt = uploadedAt
        self.uploadedBy = uploadedBy
        self.storagePath = storagePath
        self.metadata = metadata
    }
}

/// Protocol defining the interface for document storage providers
protocol DocumentStorageProtocol {
    /// Upload a document
    /// - Parameters:
    ///   - data: The document data
    ///   - filename: The filename to use
    ///   - contentType: MIME type of the document
    ///   - metadata: Optional metadata to store with the document
    /// - Returns: The storage path/URL of the uploaded document
    func uploadDocument(data: Data, filename: String, contentType: String, metadata: [String: String]?) async throws -> String

    /// Download a document
    /// - Parameter path: The storage path of the document
    /// - Returns: The document data
    func downloadDocument(path: String) async throws -> Data

    /// List documents
    /// - Parameter prefix: Optional prefix to filter documents
    /// - Returns: Array of stored documents
    func listDocuments(prefix: String?) async throws -> [StoredDocument]

    /// Delete a document
    /// - Parameter path: The storage path of the document to delete
    func deleteDocument(path: String) async throws

    /// Get document metadata
    /// - Parameter path: The storage path of the document
    /// - Returns: The stored document metadata
    func getDocumentMetadata(path: String) async throws -> StoredDocument
}

/// Default implementation for optional parameters
extension DocumentStorageProtocol {
    func uploadDocument(data: Data, filename: String, contentType: String) async throws -> String {
        try await uploadDocument(data: data, filename: filename, contentType: contentType, metadata: nil)
    }

    func listDocuments() async throws -> [StoredDocument] {
        try await listDocuments(prefix: nil)
    }
}

/// Errors that can occur in storage services
enum StorageServiceError: LocalizedError {
    case uploadFailed(String?)
    case downloadFailed(String?)
    case deleteFailed(String?)
    case documentNotFound(String)
    case invalidPath
    case authenticationError
    case quotaExceeded
    case networkError(Error)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .uploadFailed(let message):
            return "Upload failed: \(message ?? "Unknown error")"
        case .downloadFailed(let message):
            return "Download failed: \(message ?? "Unknown error")"
        case .deleteFailed(let message):
            return "Delete failed: \(message ?? "Unknown error")"
        case .documentNotFound(let path):
            return "Document not found: \(path)"
        case .invalidPath:
            return "Invalid storage path"
        case .authenticationError:
            return "Storage authentication failed"
        case .quotaExceeded:
            return "Storage quota exceeded"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid document data"
        }
    }
}

/// Helper to determine content type from filename
func contentType(for filename: String) -> String {
    let ext = (filename as NSString).pathExtension.lowercased()
    switch ext {
    case "pdf":
        return "application/pdf"
    case "jpg", "jpeg":
        return "image/jpeg"
    case "png":
        return "image/png"
    case "gif":
        return "image/gif"
    case "txt":
        return "text/plain"
    case "json":
        return "application/json"
    case "doc":
        return "application/msword"
    case "docx":
        return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    case "xls":
        return "application/vnd.ms-excel"
    case "xlsx":
        return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    default:
        return "application/octet-stream"
    }
}
