//
// LLM Service Protocol
// Defines interface for LLM providers (OpenAI, OpenRouter, etc.)
//

import Foundation

/// Protocol defining the interface for LLM service providers
protocol LLMServiceProtocol {
    /// Send a message and get a response
    /// - Parameters:
    ///   - message: The user's message/query
    ///   - systemPrompt: Optional system prompt to set context
    ///   - context: Optional array of context strings (e.g., document contents)
    /// - Returns: The LLM's response
    func sendMessage(_ message: String, systemPrompt: String?, context: [String]?) async throws -> String

    /// Send a message and get a streaming response
    /// - Parameters:
    ///   - message: The user's message/query
    ///   - systemPrompt: Optional system prompt to set context
    ///   - context: Optional array of context strings
    /// - Returns: An async stream of response chunks
    func sendMessageStream(_ message: String, systemPrompt: String?, context: [String]?) -> AsyncThrowingStream<String, Error>
}

/// Default implementation for optional parameters
extension LLMServiceProtocol {
    func sendMessage(_ message: String) async throws -> String {
        try await sendMessage(message, systemPrompt: nil, context: nil)
    }

    func sendMessage(_ message: String, context: [String]?) async throws -> String {
        try await sendMessage(message, systemPrompt: nil, context: context)
    }

    func sendMessageStream(_ message: String) -> AsyncThrowingStream<String, Error> {
        sendMessageStream(message, systemPrompt: nil, context: nil)
    }
}

/// Errors that can occur in LLM services
enum LLMServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case rateLimited
    case authenticationError
    case modelNotFound(String)
    case contextTooLong
    case serverError(Int, String?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from LLM service"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .rateLimited:
            return "Rate limited - please try again later"
        case .authenticationError:
            return "Authentication failed - check API key"
        case .modelNotFound(let model):
            return "Model not found: \(model)"
        case .contextTooLong:
            return "Context too long for model"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message ?? "Unknown error")"
        }
    }
}

/// Common message structure for LLM requests
struct LLMMessage: Codable {
    let role: String
    let content: String

    static func system(_ content: String) -> LLMMessage {
        LLMMessage(role: "system", content: content)
    }

    static func user(_ content: String) -> LLMMessage {
        LLMMessage(role: "user", content: content)
    }

    static func assistant(_ content: String) -> LLMMessage {
        LLMMessage(role: "assistant", content: content)
    }
}
