//
// Firestore Storage Service
// Document storage using Firestore (metadata) + Firebase Storage (files)
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation

@MainActor
class FirestoreStorageService: ObservableObject, DocumentStorageProtocol {
    private let database = Firestore.firestore()
    private let storage = Storage.storage()
    private let collectionName: String
    private let storagePrefix: String

    @Published var isUploading = false
    @Published var uploadProgress: Double = 0

    init(
        collectionName: String = ServiceConfiguration.firestoreDocumentsCollection,
        storagePrefix: String = ServiceConfiguration.firebaseStoragePrefix
    ) {
        self.collectionName = collectionName
        self.storagePrefix = storagePrefix
    }

    /// Upload a document to Firebase Storage with metadata in Firestore
    func uploadDocument(data: Data, filename: String, contentType: String, metadata: [String: String]?) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw StorageServiceError.authenticationError
        }

        isUploading = true
        uploadProgress = 0

        defer {
            isUploading = false
        }

        // Generate unique document ID
        let documentId = UUID().uuidString

        // Create storage path
        let storagePath = "\(storagePrefix)/\(userId)/\(documentId)/\(filename)"
        let storageRef = storage.reference().child(storagePath)

        // Upload file to Firebase Storage
        let storageMetadata = StorageMetadata()
        storageMetadata.contentType = contentType

        do {
            // Upload with progress tracking
            let uploadTask = storageRef.putData(data, metadata: storageMetadata)

            // Observe progress
            let progressHandle = uploadTask.observe(.progress) { [weak self] snapshot in
                if let progress = snapshot.progress {
                    Task { @MainActor in
                        self?.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    }
                }
            }

            // Wait for completion with proper observer cleanup
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata, Error>) in
                var hasResumed = false
                var successHandle: String?
                var failureHandle: String?

                successHandle = uploadTask.observe(.success) { snapshot in
                    guard !hasResumed else {
                        return
                    }
                    hasResumed = true

                    // Clean up observers
                    uploadTask.removeObserver(withHandle: progressHandle)
                    if let handle = successHandle { uploadTask.removeObserver(withHandle: handle) }
                    if let handle = failureHandle { uploadTask.removeObserver(withHandle: handle) }

                    if let metadata = snapshot.metadata {
                        continuation.resume(returning: metadata)
                    } else {
                        continuation.resume(throwing: StorageServiceError.uploadFailed("No metadata returned"))
                    }
                }
                failureHandle = uploadTask.observe(.failure) { snapshot in
                    guard !hasResumed else {
                        return
                    }
                    hasResumed = true

                    // Clean up observers
                    uploadTask.removeObserver(withHandle: progressHandle)
                    if let handle = successHandle { uploadTask.removeObserver(withHandle: handle) }
                    if let handle = failureHandle { uploadTask.removeObserver(withHandle: handle) }

                    continuation.resume(throwing: StorageServiceError.uploadFailed(snapshot.error?.localizedDescription))
                }
            }

            // Store metadata in Firestore
            let documentData: [String: Any] = [
                "filename": filename,
                "contentType": contentType,
                "size": data.count,
                "uploadedAt": Timestamp(date: Date()),
                "uploadedBy": userId,
                "storagePath": storagePath,
                "metadata": metadata ?? [:]
            ]

            try await database.collection(collectionName).document(documentId).setData(documentData)

            if ServiceConfiguration.enableServiceLogging {
                print("FirestoreStorage: Uploaded \(filename) to \(storagePath)")
            }

            return storagePath

        } catch {
            throw StorageServiceError.uploadFailed(error.localizedDescription)
        }
    }

    /// Download a document from Firebase Storage
    func downloadDocument(path: String) async throws -> Data {
        let storageRef = storage.reference().child(path)

        do {
            // Download with max size of 50MB
            let maxSize: Int64 = 50 * 1024 * 1024
            let data = try await storageRef.data(maxSize: maxSize)

            if ServiceConfiguration.enableServiceLogging {
                print("FirestoreStorage: Downloaded \(path) (\(data.count) bytes)")
            }

            return data
        } catch {
            throw StorageServiceError.downloadFailed(error.localizedDescription)
        }
    }

    /// List documents for the current user
    func listDocuments(prefix: String?) async throws -> [StoredDocument] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw StorageServiceError.authenticationError
        }

        do {
            var query: Query = database.collection(collectionName)
                .whereField("uploadedBy", isEqualTo: userId)
                .order(by: "uploadedAt", descending: true)

            // Apply prefix filter if provided
            if let prefix = prefix {
                query = query.whereField("filename", isGreaterThanOrEqualTo: prefix)
                    .whereField("filename", isLessThan: prefix + "\u{f8ff}")
            }

            let snapshot = try await query.getDocuments()

            let documents = snapshot.documents.compactMap { doc -> StoredDocument? in
                let data = doc.data()
                guard let filename = data["filename"] as? String,
                      let contentType = data["contentType"] as? String,
                      let size = data["size"] as? Int,
                      let timestamp = data["uploadedAt"] as? Timestamp,
                      let storagePath = data["storagePath"] as? String else {
                    return nil
                }

                return StoredDocument(
                    id: doc.documentID,
                    filename: filename,
                    contentType: contentType,
                    size: size,
                    uploadedAt: timestamp.dateValue(),
                    uploadedBy: data["uploadedBy"] as? String,
                    storagePath: storagePath,
                    metadata: data["metadata"] as? [String: String]
                )
            }

            if ServiceConfiguration.enableServiceLogging {
                print("FirestoreStorage: Listed \(documents.count) documents")
            }

            return documents
        } catch {
            throw StorageServiceError.networkError(error)
        }
    }

    /// Delete a document from both Firebase Storage and Firestore
    func deleteDocument(path: String) async throws {
        // Find the document in Firestore by storage path
        do {
            let snapshot = try await database.collection(collectionName)
                .whereField("storagePath", isEqualTo: path)
                .getDocuments()

            guard let document = snapshot.documents.first else {
                throw StorageServiceError.documentNotFound(path)
            }

            // Delete from Firebase Storage
            let storageRef = storage.reference().child(path)
            try await storageRef.delete()

            // Delete from Firestore
            try await document.reference.delete()

            if ServiceConfiguration.enableServiceLogging {
                print("FirestoreStorage: Deleted \(path)")
            }
        } catch let error as StorageServiceError {
            throw error
        } catch {
            throw StorageServiceError.deleteFailed(error.localizedDescription)
        }
    }

    /// Get document metadata from Firestore
    func getDocumentMetadata(path: String) async throws -> StoredDocument {
        do {
            let snapshot = try await database.collection(collectionName)
                .whereField("storagePath", isEqualTo: path)
                .getDocuments()

            guard let doc = snapshot.documents.first else {
                throw StorageServiceError.documentNotFound(path)
            }

            let data = doc.data()
            guard let filename = data["filename"] as? String,
                  let contentType = data["contentType"] as? String,
                  let size = data["size"] as? Int,
                  let timestamp = data["uploadedAt"] as? Timestamp,
                  let storagePath = data["storagePath"] as? String else {
                throw StorageServiceError.invalidData
            }

            return StoredDocument(
                id: doc.documentID,
                filename: filename,
                contentType: contentType,
                size: size,
                uploadedAt: timestamp.dateValue(),
                uploadedBy: data["uploadedBy"] as? String,
                storagePath: storagePath,
                metadata: data["metadata"] as? [String: String]
            )
        } catch let error as StorageServiceError {
            throw error
        } catch {
            throw StorageServiceError.networkError(error)
        }
    }

    // MARK: - Helper Methods

    /// Get download URL for a document
    func getDownloadURL(path: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        return try await storageRef.downloadURL()
    }

    /// Read document content as string (for text files)
    func readDocumentAsString(path: String) async throws -> String {
        let data = try await downloadDocument(path: path)
        guard let content = String(data: data, encoding: .utf8) else {
            throw StorageServiceError.invalidData
        }
        return content
    }
}
