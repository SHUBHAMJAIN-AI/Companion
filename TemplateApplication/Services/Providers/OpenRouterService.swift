//
// OpenRouter Service
// LLM provider using OpenRouter API (supports multiple models)
//

import Foundation

@MainActor
class OpenRouterService: ObservableObject, LLMServiceProtocol {
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    private let apiKey: String
    private let appName: String
    private let appURL: String

    @Published var currentModel: String

    init(
        apiKey: String = APIKeys.openRouter,
        model: String = ServiceConfiguration.openRouterModel,
        appName: String = "Health Companion",
        appURL: String = "https://health-companion.app"
    ) {
        self.apiKey = apiKey
        self.currentModel = model
        self.appName = appName
        self.appURL = appURL
    }

    /// Send a message and get a response
    func sendMessage(_ message: String, systemPrompt: String?, context: [String]?) async throws -> String {
        let messages = buildMessages(userMessage: message, systemPrompt: systemPrompt, context: context)
        let request = try createRequest(messages: messages)
        let data = try await performRequest(request)
        return try decodeResponse(data)
    }

    /// Send a message and get a streaming response
    func sendMessageStream(_ message: String, systemPrompt: String?, context: [String]?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let messages = buildMessages(userMessage: message, systemPrompt: systemPrompt, context: context)
                    var request = try createRequest(messages: messages, stream: true)
                    request.timeoutInterval = 120

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw LLMServiceError.invalidResponse
                    }

                    guard httpResponse.statusCode == 200 else {
                        throw LLMServiceError.serverError(httpResponse.statusCode, nil)
                    }

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if jsonString == "[DONE]" {
                                break
                            }
                            if let data = jsonString.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let choices = json["choices"] as? [[String: Any]],
                               let delta = choices.first?["delta"] as? [String: Any],
                               let content = delta["content"] as? String {
                                continuation.yield(content)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func buildMessages(userMessage: String, systemPrompt: String?, context: [String]?) -> [[String: String]] {
        var messages: [[String: String]] = []

        // Add system prompt
        let systemContent = systemPrompt ?? ServiceConfiguration.medicalSystemPrompt
        messages.append(["role": "system", "content": systemContent])

        // Add context if provided
        if let context = context, !context.isEmpty {
            let contextContent = "Context:\n" + context.joined(separator: "\n\n")
            messages.append(["role": "system", "content": contextContent])
        }

        // Add user message
        messages.append(["role": "user", "content": userMessage])

        return messages
    }

    private func createRequest(messages: [[String: String]], stream: Bool = false) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw LLMServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appURL, forHTTPHeaderField: "HTTP-Referer")
        request.setValue(appName, forHTTPHeaderField: "X-Title")

        let body: [String: Any] = [
            "model": currentModel,
            "messages": messages,
            "stream": stream,
            "max_tokens": 4096
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        if ServiceConfiguration.enableServiceLogging {
            print("OpenRouter Request - Model: \(currentModel)")
            print("OpenRouter Request - Messages count: \(messages.count)")
        }

        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMServiceError.invalidResponse
        }

        if ServiceConfiguration.enableServiceLogging {
            print("OpenRouter Response - Status: \(httpResponse.statusCode)")
        }

        switch httpResponse.statusCode {
        case 200:
            return data
        case 401:
            throw LLMServiceError.authenticationError
        case 429:
            throw LLMServiceError.rateLimited
        case 404:
            throw LLMServiceError.modelNotFound(currentModel)
        default:
            let errorMessage = String(data: data, encoding: .utf8)
            throw LLMServiceError.serverError(httpResponse.statusCode, errorMessage)
        }
    }

    private func decodeResponse(_ data: Data) throws -> String {
        struct OpenRouterResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        do {
            let response = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
            guard let content = response.choices.first?.message.content else {
                throw LLMServiceError.invalidResponse
            }

            if ServiceConfiguration.enableServiceLogging {
                print("OpenRouter Response - Content length: \(content.count)")
            }

            return content
        } catch let error as DecodingError {
            throw LLMServiceError.decodingError(error)
        }
    }

    // MARK: - Model Management

    /// Update the model being used
    func setModel(_ model: String) {
        currentModel = model
        ServiceConfiguration.openRouterModel = model
    }

    /// Get list of available models
    func getAvailableModels() -> [(id: String, name: String)] {
        ServiceConfiguration.availableOpenRouterModels
    }
}
