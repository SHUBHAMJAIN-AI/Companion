//
// RAG Pipeline Service
//

import Foundation

@MainActor
class RAGService: ObservableObject {
    private let endpoint = "https://n4erggelag.execute-api.us-west-2.amazonaws.com/prod/query"
    private let knowledgeBaseId = "K205PUDOUS"
    
    struct RAGResponse {
        let answer: String
        let sources: [Source]
    }
    
    struct Source {
        let content: String
        let score: Double
        let s3Uri: String
    }
    
    func sendMessage(_ query: String) async throws -> String {
        let response = try await sendMessageWithSources(query)
        return formatResponseWithSources(response)
    }
    
    func sendMessageWithSources(_ query: String) async throws -> RAGResponse {
        guard let url = URL(string: endpoint) else {
            throw RAGError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let requestBody: [String: String] = [
            "query": query,
            "knowledge_base_id": knowledgeBaseId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw RAGError.serverError
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let body = json["body"] as? String,
           let bodyData = body.data(using: .utf8),
           let bodyJson = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
           let answer = bodyJson["answer"] as? String {
            
            var sources: [Source] = []
            if let sourcesArray = bodyJson["sources"] as? [[String: Any]] {
                sources = sourcesArray.compactMap { sourceDict in
                    guard let content = sourceDict["content"] as? String,
                          let score = sourceDict["score"] as? Double,
                          let s3Uri = sourceDict["s3_uri"] as? String else { return nil }
                    return Source(content: content, score: score, s3Uri: s3Uri)
                }
            }
            
            return RAGResponse(answer: formatResponse(answer), sources: sources)
        }
        
        throw RAGError.invalidResponse
    }
    
    private func formatResponse(_ text: String) -> String {
        var formatted = text
        formatted = formatted.replacingOccurrences(of: "\\n", with: "\n")
        formatted = formatted.replacingOccurrences(of: "\n\n", with: "\n")
        formatted = formatted.trimmingCharacters(in: .whitespacesAndNewlines)
        return formatted
    }
    
    private func formatResponseWithSources(_ response: RAGResponse) -> String {
        var result = response.answer
        
        if !response.sources.isEmpty {
            result += "\n\n📚 Sources:\n"
            for (index, source) in response.sources.prefix(3).enumerated() {
                let fileName = source.s3Uri.components(separatedBy: "/").last ?? "Document"
                let cleanFileName = fileName.replacingOccurrences(of: "%20", with: " ").replacingOccurrences(of: ".docx", with: "")
                result += "\n\(index + 1). \(cleanFileName)\n   \(source.s3Uri)"
            }
        }
        
        return result
    }
}

enum RAGError: LocalizedError {
    case invalidURL
    case serverError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API endpoint"
        case .serverError: return "Server error occurred"
        case .invalidResponse: return "Invalid response from server"
        }
    }
}
