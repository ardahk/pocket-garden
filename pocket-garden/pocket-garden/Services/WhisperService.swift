//
//  WhisperService.swift
//  pocket-garden
//
//  Whisper-based Speech Recognition Service
//  Uses OpenAI's Whisper model for on-device transcription
//

import SwiftUI
import AVFoundation
import SwiftWhisper

@Observable
class WhisperService {
    // MARK: - Published Properties
    
    var transcription: String = ""
    var isRecording: Bool = false
    var isTranscribing: Bool = false
    var error: WhisperError?
    var transcriptionProgress: Double = 0.0
    /// Normalized audio level (0...1) while recording, updated in real time.
    var audioLevel: CGFloat = 0
    
    // MARK: - Private Properties
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var whisper: Whisper? // Uncomment after adding package
    private let modelURL: URL?
    private var levelTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        // Look for Whisper model in app bundle
        // Default to tiny.bin model for fast transcription
        self.modelURL = Bundle.main.url(forResource: "tiny", withExtension: "bin")
        
        if modelURL == nil {
            print("⚠️ Whisper model not found. Please add a model file to the app bundle.")
            print("📥 Download models from: https://huggingface.co/ggerganov/whisper.cpp")
        } else {
            print("✅ Whisper model found at: \(modelURL!.path)")
            self.whisper = Whisper(fromFileURL: modelURL!)
            print("✅ Whisper initialized successfully")
            
        }
    }
    
    // MARK: - Permissions
    
    /// Request microphone permission
    func requestPermissions() async -> Bool {
        let micStatus = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
                    // Use AVAudioApplication for iOS 17.0+, fallback to AVAudioSession for older versions
                    if #available(iOS 17.0, *) {
                        AVAudioApplication.requestRecordPermission { granted in
                            cont.resume(returning: granted)
                        }
                    } else {
                        AVAudioSession.sharedInstance().requestRecordPermission { granted in
                            cont.resume(returning: granted)
                        }
                    }
                }
        
        guard micStatus else {
            error = .microphoneAccessDenied
            return false
        }
        
        return true
    }
    
    // MARK: - Recording
    
    /// Start recording audio to file
    func startRecording() async throws {
        guard modelURL != nil else {
            throw WhisperError.modelNotFound
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .default)
        try audioSession.setActive(true)
        
        // Create temporary recording URL
        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent(UUID().uuidString + ".wav")
        
        guard let recordingURL = recordingURL else {
            throw WhisperError.recordingFailed("Failed to create recording URL")
        }
        
        // Configure recording settings for 16kHz PCM (required by Whisper)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        // Create and start recorder
        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
        
        guard audioRecorder?.record() == true else {
            throw WhisperError.recordingFailed("Failed to start recording")
        }
        
        isRecording = true
        error = nil
        
        print("🎤 Whisper recording started")

        // Start updating audio level for UI animations
        startLevelMetering()
    }
    
    /// Stop recording and transcribe
    func stopRecording() async {
        guard isRecording else { return }
        
        // Stop recording
        audioRecorder?.stop()
        isRecording = false
        stopLevelMetering()
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("⚠️ Failed to deactivate audio session: \(error)")
        }
        
        print("⏹️ Whisper recording stopped")
        
        // Transcribe the recorded audio
        await transcribeRecording()
    }
    
    /// Cancel recording without transcribing
    func cancelRecording() {
        audioRecorder?.stop()
        isRecording = false
        isTranscribing = false
        transcription = ""
        error = nil
        stopLevelMetering()

        // Clean up recording file
        discardRecordingFile()
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("⚠️ Failed to deactivate audio session: \(error)")
        }
    }
    
    // MARK: - Transcription
    
    /// Transcribe the recorded audio file
    private func transcribeRecording() async {
        guard let recordingURL = recordingURL else {
            error = .transcriptionFailed("No recording found")
            return
        }
        
        guard let modelURL = modelURL else {
            error = .modelNotFound
            return
        }
        
        isTranscribing = true
        transcriptionProgress = 0.0
        
        do {
            // Convert audio to PCM array
            let pcmArray = try await convertAudioToPCM(fileURL: recordingURL)
            
            // Initialize Whisper if needed
            if whisper == nil {
                whisper = Whisper(fromFileURL: modelURL)
            }
            
            guard let whisper = whisper else {
                throw WhisperError.transcriptionFailed("Whisper not initialized")
            }
            
            // Set delegate for progress updates
            whisper.delegate = self
            
            // Transcribe
            let segments = try await whisper.transcribe(audioFrames: pcmArray)
            
            // Combine segments into full transcription
            let fullText = segments.map(\.text).joined()
            
            // Clean up transcription artifacts
            let cleanedText = cleanTranscription(fullText)
            
            await MainActor.run {
                self.transcription = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
                self.isTranscribing = false
                self.transcriptionProgress = 1.0
            }
            
            print("✅ Whisper transcription complete: \(transcription)")
            
        } catch {
            await MainActor.run {
                self.error = .transcriptionFailed(error.localizedDescription)
                self.isTranscribing = false
            }
            print("❌ Whisper transcription failed: \(error)")
        }
    }
    
    /// Convert audio file to 16kHz PCM array required by Whisper
    private func convertAudioToPCM(fileURL: URL) async throws -> [Float] {
        // Read the WAV file data
        let data = try Data(contentsOf: fileURL)
        
        // Skip WAV header (44 bytes) and convert to Float array
        let pcmArray = stride(from: 44, to: data.count, by: 2).map { offset -> Float in
            let slice = data[offset..<offset + 2]
            return slice.withUnsafeBytes { buffer in
                let short = Int16(littleEndian: buffer.load(as: Int16.self))
                return max(-1.0, min(Float(short) / 32767.0, 1.0))
            }
        }
        
        return pcmArray
    }
    
    // MARK: - Helper Methods
    
    var canRecord: Bool {
        modelURL != nil
    }
    
    /// Clean transcription by removing common Whisper artifacts
    private func cleanTranscription(_ text: String) -> String {
        var cleaned = text
        
        // Remove content in square brackets: [MUSIC], [Applause], etc.
        cleaned = cleaned.replacingOccurrences(
            of: "\\[[^\\]]*\\]",
            with: "",
            options: .regularExpression
        )
        
        // Remove content in asterisks: *click*, *cough*, etc.
        cleaned = cleaned.replacingOccurrences(
            of: "\\*[^\\*]*\\*",
            with: "",
            options: .regularExpression
        )
        
        // Remove content in parentheses if it's non-speech: (laughs), (door opening), etc.
        let nonSpeechPatterns = [
            "laugh",
            "sigh",
            "cough",
            "click",
            "music",
            "applause",
            "background",
            "noise",
            "door",
            "opening",
            "closing"
        ]
        for pattern in nonSpeechPatterns {
            cleaned = cleaned.replacingOccurrences(
                of: "\\([^\\)]*\(pattern)[^\\)]*\\)",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        // Clean up multiple spaces and newlines
        cleaned = cleaned.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        
        return cleaned
    }

    // MARK: - Recording File Management & Compression

    /// Remove the temporary WAV recording from disk and clear the reference.
    func discardRecordingFile() {
        if let recordingURL = recordingURL {
            try? FileManager.default.removeItem(at: recordingURL)
        }
        recordingURL = nil
    }

    /// Compress the last recorded WAV to an AAC m4a file for the given entry ID.
    /// Returns the destination URL and deletes the original WAV on success.
    func exportCompressedAudio(forEntryID entryID: UUID) async throws -> URL {
        guard let sourceURL = recordingURL else {
            throw WhisperError.recordingFailed("No recording available for export")
        }

        let fileManager = FileManager.default
        guard let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw WhisperError.recordingFailed("Unable to access documents directory")
        }

        let folder = docs.appendingPathComponent("VoiceEntries", isDirectory: true)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        let destinationURL = folder.appendingPathComponent("\(entryID.uuidString).m4a")

        if fileManager.fileExists(atPath: destinationURL.path) {
            try? fileManager.removeItem(at: destinationURL)
        }

        let asset = AVURLAsset(url: sourceURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw WhisperError.recordingFailed("Failed to create export session")
        }

        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .m4a

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume(returning: ())
                case .failed, .cancelled:
                    let message = exportSession.error?.localizedDescription ?? "Export failed"
                    continuation.resume(throwing: WhisperError.recordingFailed(message))
                default:
                    let message = exportSession.error?.localizedDescription ?? "Export did not complete"
                    continuation.resume(throwing: WhisperError.recordingFailed(message))
                }
            }
        }

        // Remove original WAV to free space
        try? fileManager.removeItem(at: sourceURL)
        recordingURL = nil

        return destinationURL
    }

    // MARK: - Audio Level Metering
    
    private func startLevelMetering() {
        levelTimer?.invalidate()
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder, recorder.isRecording else { return }
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0) // -160...0 dB
            // Normalize into 0...1 range, focusing on the typical speech band
            let normalized = max(0, min(1, (power + 60) / 60))
            Task { @MainActor in
                self.audioLevel = CGFloat(normalized)
            }
        }
    }
    
    private func stopLevelMetering() {
        levelTimer?.invalidate()
        levelTimer = nil
        Task { @MainActor in
            self.audioLevel = 0
        }
    }
}

// MARK: - Whisper Delegate (for future implementation)

extension WhisperService: WhisperDelegate {
    func whisper(_ aWhisper: Whisper, didUpdateProgress progress: Double) {
        Task { @MainActor in
            self.transcriptionProgress = progress
        }
    }
    
    func whisper(_ aWhisper: Whisper, didProcessNewSegments segments: [Segment], atIndex index: Int) {
        // Real-time segment processing if needed
        Task { @MainActor in
            let newText = segments.map(\.text).joined()
            self.transcription += newText
        }
    }
    
    func whisper(_ aWhisper: Whisper, didCompleteWithSegments segments: [Segment]) {
        Task { @MainActor in
            self.isTranscribing = false
            self.transcriptionProgress = 1.0
        }
    }
    
    func whisper(_ aWhisper: Whisper, didErrorWith error: Error) {
        Task { @MainActor in
            self.error = .transcriptionFailed(error.localizedDescription)
            self.isTranscribing = false
        }
    }
}

// MARK: - Whisper Error

enum WhisperError: LocalizedError, Identifiable {
    case modelNotFound
    case microphoneAccessDenied
    case recordingFailed(String)
    case transcriptionFailed(String)
    
    var id: String {
        switch self {
        case .modelNotFound: return "model_not_found"
        case .microphoneAccessDenied: return "mic_denied"
        case .recordingFailed: return "recording_failed"
        case .transcriptionFailed: return "transcription_failed"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Whisper model not found. Please add a model file to the app."
        case .microphoneAccessDenied:
            return "Microphone access was denied. Please enable it in Settings."
        case .recordingFailed(let message):
            return "Recording failed: \(message)"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelNotFound:
            return "Download a Whisper model from https://huggingface.co/ggerganov/whisper.cpp and add it to your app bundle."
        case .microphoneAccessDenied:
            return "Go to Settings > Privacy > Microphone and enable access for Pocket Garden."
        default:
            return "Please try again. If the problem persists, restart the app."
        }
    }
}
