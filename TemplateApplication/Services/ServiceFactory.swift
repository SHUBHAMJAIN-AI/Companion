//
// Service Factory
// Central factory for creating service instances based on configuration
//

import Foundation

/// Factory for creating service instances
@MainActor
class ServiceFactory {
    // MARK: - Singleton

    static let shared = ServiceFactory()

    private init() {}

    // MARK: - Cached Instances

    private var _llmService: (any LLMServiceProtocol)?
    private var _storageService: (any DocumentStorageProtocol)?

    // MARK: - LLM Service

    /// Get the configured LLM service
    func getLLMService() -> any LLMServiceProtocol {
        if let service = _llmService {
            return service
        }

        let service = createLLMService()
        _llmService = service
        return service
    }

    /// Create a new LLM service based on configuration
    func createLLMService(provider: LLMProvider? = nil) -> any LLMServiceProtocol {
        let selectedProvider = provider ?? ServiceConfiguration.llmProvider

        switch selectedProvider {
        case .openAI:
            return OpenAIServiceAdapter()
        case .openRouter:
            return OpenRouterService()
        }
    }

    /// Reset cached LLM service (call when provider changes)
    func resetLLMService() {
        _llmService = nil
    }

    // MARK: - Storage Service

    /// Get the configured storage service
    func getStorageService() -> any DocumentStorageProtocol {
        if let service = _storageService {
            return service
        }

        let service = createStorageService()
        _storageService = service
        return service
    }

    /// Create a new storage service based on configuration
    func createStorageService(provider: StorageProvider? = nil) -> any DocumentStorageProtocol {
        let selectedProvider = provider ?? ServiceConfiguration.storageProvider

        switch selectedProvider {
        case .awsS3:
            return AWSS3ServiceAdapter()
        case .firestoreStorage:
            return FirestoreStorageService()
        }
    }

    /// Reset cached storage service (call when provider changes)
    func resetStorageService() {
        _storageService = nil
    }

    // MARK: - Provider Management

    /// Switch LLM provider
    func switchLLMProvider(to provider: LLMProvider) {
        ServiceConfiguration.llmProvider = provider
        resetLLMService()
    }

    /// Switch storage provider
    func switchStorageProvider(to provider: StorageProvider) {
        ServiceConfiguration.storageProvider = provider
        resetStorageService()
    }

    /// Reset all cached services
    func resetAll() {
        _llmService = nil
        _storageService = nil
    }
}

// MARK: - OpenAI Adapter

/// Adapter to make existing OpenAIService conform to LLMServiceProtocol
@MainActor
class OpenAIServiceAdapter: LLMServiceProtocol {
    private let service = OpenAIService()

    func sendMessage(_ message: String, systemPrompt: String?, context: [String]?) async throws -> String {
        // Build the full message with context
        var fullMessage = message
        if let context = context, !context.isEmpty {
            fullMessage = "Context:\n" + context.joined(separator: "\n\n") + "\n\nQuestion: " + message
        }

        // Create empty documents array (OpenAIService uses documents differently)
        return try await service.sendMessage(fullMessage, documents: [])
    }

    func sendMessageStream(_ message: String, systemPrompt: String?, context: [String]?) -> AsyncThrowingStream<String, Error> {
        // OpenAI service doesn't support streaming in current implementation
        // Return a single-item stream with the full response
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await self.sendMessage(message, systemPrompt: systemPrompt, context: context)
                    continuation.yield(response)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - AWS S3 Adapter

/// Adapter to make existing AWSS3Service conform to DocumentStorageProtocol
@MainActor
class AWSS3ServiceAdapter: DocumentStorageProtocol {
    private let service = AWSS3Service()

    func uploadDocument(data: Data, filename: String, contentType: String, metadata: [String: String]?) async throws -> String {
        // Use existing upload method
        await service.uploadDocument(data: data, filename: filename)
        return "data-second-raw/\(filename)"
    }

    func downloadDocument(path: String) async throws -> Data {
        // Extract filename from path
        let filename = (path as NSString).lastPathComponent
        let content = try await service.downloadDocument(filename: filename)
        guard let data = content.data(using: .utf8) else {
            throw StorageServiceError.invalidData
        }
        return data
    }

    func listDocuments(prefix: String?) async throws -> [StoredDocument] {
        // AWS S3 list not implemented in current service
        // Return empty array
        return []
    }

    func deleteDocument(path: String) async throws {
        // AWS S3 delete not implemented in current service
        throw StorageServiceError.deleteFailed("Delete not implemented for S3")
    }

    func getDocumentMetadata(path: String) async throws -> StoredDocument {
        // AWS S3 metadata not implemented in current service
        throw StorageServiceError.documentNotFound(path)
    }
}
