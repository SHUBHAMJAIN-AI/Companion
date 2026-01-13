//
// Service Configuration
// Central configuration for service providers
//

import Foundation

/// Available LLM providers
enum LLMProvider: String, CaseIterable {
    case openAI = "openai"
    case openRouter = "openrouter"

    var displayName: String {
        switch self {
        case .openAI:
            return "OpenAI"
        case .openRouter:
            return "OpenRouter"
        }
    }
}

/// Available storage providers
enum StorageProvider: String, CaseIterable {
    case awsS3 = "aws_s3"
    case firestoreStorage = "firestore_storage"

    var displayName: String {
        switch self {
        case .awsS3:
            return "AWS S3"
        case .firestoreStorage:
            return "Firestore Storage"
        }
    }
}

/// Central service configuration
struct ServiceConfiguration {
    // MARK: - Provider Selection

    /// Current LLM provider (default: OpenRouter)
    static var llmProvider: LLMProvider {
        get {
            if let stored = UserDefaults.standard.string(forKey: "llm_provider"),
               let provider = LLMProvider(rawValue: stored) {
                return provider
            }
            return .openRouter // Default
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "llm_provider")
        }
    }

    /// Current storage provider (default: Firestore Storage)
    static var storageProvider: StorageProvider {
        get {
            if let stored = UserDefaults.standard.string(forKey: "storage_provider"),
               let provider = StorageProvider(rawValue: stored) {
                return provider
            }
            return .firestoreStorage // Default
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "storage_provider")
        }
    }

    // MARK: - OpenRouter Configuration

    /// OpenRouter model to use (default: Claude Sonnet 4)
    static var openRouterModel: String {
        get {
            UserDefaults.standard.string(forKey: "openrouter_model") ?? "anthropic/claude-sonnet-4"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "openrouter_model")
        }
    }

    /// Available OpenRouter models
    /// Note: Model IDs follow OpenRouter's naming conventions
    static let availableOpenRouterModels: [(id: String, name: String)] = [
        ("anthropic/claude-sonnet-4", "Claude Sonnet 4"),
        ("anthropic/claude-opus-4", "Claude Opus 4"),
        ("anthropic/claude-3.5-sonnet", "Claude 3.5 Sonnet"),
        ("openai/gpt-4o", "GPT-4o"),
        ("openai/gpt-4o-mini", "GPT-4o Mini"),
        ("google/gemini-2.0-flash-exp", "Gemini 2.0 Flash"),
        ("google/gemini-pro", "Gemini Pro"),
        ("meta-llama/llama-3.3-70b-instruct", "Llama 3.3 70B"),
        ("mistralai/mistral-large", "Mistral Large")
    ]

    // MARK: - OpenAI Configuration

    /// OpenAI model to use
    static var openAIModel: String {
        get {
            UserDefaults.standard.string(forKey: "openai_model") ?? "gpt-4o-mini"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "openai_model")
        }
    }

    // MARK: - Medical Assistant Configuration

    /// Default system prompt for medical assistant
    static let medicalSystemPrompt = """
        You are a helpful medical AI assistant for healthcare professionals.
        You provide accurate medical information while always recommending
        consultation with appropriate specialists for specific patient cases.
        You do not diagnose or prescribe - you provide educational information.
        """

    // MARK: - Storage Configuration

    /// Firestore collection for documents
    static let firestoreDocumentsCollection = "documents"

    /// Firebase Storage path prefix
    static let firebaseStoragePrefix = "documents"

    /// AWS S3 bucket name (from APIKeys)
    static var awsS3Bucket: String {
        "us-west-raw-files-sid"
    }

    /// AWS S3 region
    static var awsS3Region: String {
        "us-west-2"
    }

    // MARK: - Debug Configuration

    /// Enable debug logging for services
    static var enableServiceLogging: Bool {
        get {
            UserDefaults.standard.bool(forKey: "enable_service_logging")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "enable_service_logging")
        }
    }

    // MARK: - Reset

    /// Reset all configuration to defaults
    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: "llm_provider")
        UserDefaults.standard.removeObject(forKey: "storage_provider")
        UserDefaults.standard.removeObject(forKey: "openrouter_model")
        UserDefaults.standard.removeObject(forKey: "openai_model")
        UserDefaults.standard.removeObject(forKey: "enable_service_logging")
    }
}
