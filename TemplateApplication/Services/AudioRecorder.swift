//
// Audio Recorder for Voice Input
//

import Foundation
import AVFoundation

@MainActor
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    
    func startRecording() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        
        let tempDir = FileManager.default.temporaryDirectory
        audioFileURL = tempDir.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        guard let url = audioFileURL else { throw AudioError.recordingFailed }
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.prepareToRecord()
        let success = audioRecorder?.record() ?? false
        if success {
            isRecording = true
            print("Recording started: \(url.path)")
        } else {
            throw AudioError.recordingFailed
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        print("Recording stopped: \(audioFileURL?.path ?? "unknown")")
        try? AVAudioSession.sharedInstance().setActive(false)
        return audioFileURL
    }
}

enum AudioError: Error {
    case recordingFailed
    case playbackFailed
}
