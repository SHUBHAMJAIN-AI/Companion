//
// AssemblyAI Speech-to-Text and Text-to-Speech Service
//

import Foundation
import AVFoundation
import AVFAudio

@MainActor
class AssemblyAIService: NSObject, ObservableObject {
    private let apiKey = APIKeys.assemblyAI
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    func transcribeAudio(fileURL: URL) async throws -> String {
        let audioData = try Data(contentsOf: fileURL)
        let uploadURL = try await uploadAudio(data: audioData)
        let transcriptID = try await createTranscript(audioURL: uploadURL)
        return try await pollTranscript(id: transcriptID)
    }
    
    private func uploadAudio(data: Data) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.assemblyai.com/v2/upload")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "authorization")
        request.httpBody = data
        
        print("Uploading audio: \(data.count) bytes")
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Upload status: \(httpResponse.statusCode)")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
            let errorStr = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            print("Upload error: \(errorStr)")
            throw AssemblyAIError.uploadFailed
        }
        
        guard let uploadURL = json["upload_url"] as? String else {
            print("No upload_url in response: \(json)")
            throw AssemblyAIError.uploadFailed
        }
        
        print("Upload successful: \(uploadURL)")
        return uploadURL
    }
    
    private func createTranscript(audioURL: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.assemblyai.com/v2/transcript")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["audio_url": audioURL]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("Creating transcript...")
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Transcript creation status: \(httpResponse.statusCode)")
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
            let errorStr = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            print("Transcript error: \(errorStr)")
            throw AssemblyAIError.transcriptionFailed
        }
        
        guard let id = json["id"] as? String else {
            print("No id in response: \(json)")
            throw AssemblyAIError.transcriptionFailed
        }
        
        print("Transcript ID: \(id)")
        return id
    }
    
    private func pollTranscript(id: String) async throws -> String {
        let url = URL(string: "https://api.assemblyai.com/v2/transcript/\(id)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "authorization")
        
        print("Polling transcript...")
        for attempt in 0..<60 {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? String else { continue }
            
            print("Poll attempt \(attempt + 1): \(status)")
            
            if status == "completed", let text = json["text"] as? String {
                print("Transcription complete: \(text)")
                return text
            } else if status == "error" {
                let error = json["error"] as? String ?? "Unknown error"
                print("Transcription error: \(error)")
                throw AssemblyAIError.transcriptionFailed
            }
        }
        throw AssemblyAIError.timeout
    }
    
    func speakText(_ text: String) async throws {
        print("Speaking text: \(text.prefix(50))...")
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
        print("Speech synthesis started")
    }
}

enum AssemblyAIError: LocalizedError {
    case uploadFailed
    case transcriptionFailed
    case timeout
    case speechSynthesisFailed
    
    var errorDescription: String? {
        switch self {
        case .uploadFailed: return "Failed to upload audio"
        case .transcriptionFailed: return "Failed to transcribe audio"
        case .timeout: return "Transcription timeout"
        case .speechSynthesisFailed: return "Failed to synthesize speech"
        }
    }
}
