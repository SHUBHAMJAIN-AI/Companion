//
// OpenAI Integration Service for Health Companion
//

import Foundation

@MainActor
class OpenAIService: ObservableObject {
    private let apiKey = APIKeys.openAI
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    func sendMessage(_ message: String, documents: [HealthDocument] = []) async throws -> String {
        let request = try createRequest(message: message, documents: documents)
        let data = try await performRequest(request)
        return try decodeResponse(data)
    }
    
    private func createRequest(message: String, documents: [HealthDocument]) throws -> URLRequest {
        var prompt = "You are a medical AI assistant. Answer questions about health documents and provide medical insights. User question: \(message)"
        if !documents.isEmpty {
            prompt += "\n\nAvailable documents: \(documents.map { $0.name }.joined(separator: ", "))"
        }
        
        let requestBody = OpenAIRequest(
            model: "gpt-5-mini",
            messages: [
                OpenAIMessage(role: "system", content: "You are a helpful medical AI assistant for healthcare professionals."),
                OpenAIMessage(role: "user", content: prompt)
            ],
            maxCompletionTokens: nil
        )
        
        guard let url = URL(string: baseURL) else { throw OpenAIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        print("OpenAI Request URL: \(baseURL)")
        if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
            print("OpenAI Request Body: \(bodyString)")
        }
        return request
    }
    
    private func performRequest(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw OpenAIError.networkError }
        print("OpenAI Status Code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
            print("OpenAI Error Response: \(errorBody)")
            throw OpenAIError.networkError
        }
        return data
    }
    
    private func decodeResponse(_ data: Data) throws -> String {
        let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
        print("OpenAI Response Body: \(responseBody)")
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let content = openAIResponse.choices.first?.message.content ?? "No response available"
        print("OpenAI Decoded Content: \(content)")
        return content
    }
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxCompletionTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case model, messages
        case maxCompletionTokens = "max_completion_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

enum OpenAIError: Error {
    case invalidURL
    case encodingError
    case networkError
    case decodingError
}