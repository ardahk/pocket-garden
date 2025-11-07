//
//  SpeechRecognitionService.swift
//  pocket-garden
//
//  Voice Recording and Transcription Service
//

import Speech
import AVFoundation
import SwiftUI

@Observable
class SpeechRecognitionService {
    // MARK: - Published Properties

    var transcription: String = ""
    var isRecording: Bool = false
    var isTranscribing: Bool = false
    var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var error: RecognitionError?

    // MARK: - Private Properties

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?

    // MARK: - Initialization

    init() {
        // Initialize with on-device recognition for privacy
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

        // Check if on-device recognition is supported
        if let recognizer = speechRecognizer {
            print("✅ Speech recognizer initialized")
            print("📱 On-device recognition supported: \(recognizer.supportsOnDeviceRecognition)")
        } else {
            print("❌ Speech recognizer not available")
        }

        // Check initial authorization status
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }

    // MARK: - Authorization

    /// Request speech recognition and microphone permissions
    func requestAuthorization() async -> Bool {
        // Request speech recognition authorization
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        authorizationStatus = speechStatus

        guard speechStatus == .authorized else {
            error = .authorizationDenied
            return false
        }

        // Request microphone permission
        let micStatus = await AVAudioApplication.requestRecordPermission()

        guard micStatus else {
            error = .microphoneAccessDenied
            return false
        }

        return true
    }

    // MARK: - Recording

    /// Start recording and transcribing
    func startRecording() async throws {
        // Ensure we have permissions
        guard authorizationStatus == .authorized else {
            throw RecognitionError.authorizationDenied
        }

        // Cancel any ongoing recognition task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            throw RecognitionError.recognitionRequestFailed
        }

        // Enable on-device recognition for privacy
        recognitionRequest.requiresOnDeviceRecognition = true

        // Enable partial results for real-time transcription
        recognitionRequest.shouldReportPartialResults = true

        // Create audio engine
        audioEngine = AVAudioEngine()

        guard let audioEngine = audioEngine else {
            throw RecognitionError.audioEngineFailed
        }

        let inputNode = audioEngine.inputNode

        // Configure the microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition task
        isRecording = true
        isTranscribing = true
        transcription = ""
        error = nil

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                // ALWAYS use the FULL accumulated transcription
                // bestTranscription.formattedString contains ALL text up to this point
                let fullText = result.bestTranscription.formattedString

                // Update with complete accumulated text
                DispatchQueue.main.async {
                    self.transcription = fullText
                }

                // Check if result is final (but keep transcription!)
                if result.isFinal {
                    print("✅ Final transcription: \(fullText)")
                    // Don't stop immediately - let user decide when to stop
                }
            }

            if let error = error {
                print("❌ Recognition error: \(error.localizedDescription)")
                self.error = .recognitionFailed(error.localizedDescription)
                self.stopRecording()
            }
        }

        print("🎤 Recording started")
    }

    /// Stop recording and finalize transcription
    func stopRecording() {
        // Stop audio engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)

        // End recognition request
        recognitionRequest?.endAudio()

        // Update state
        isRecording = false
        isTranscribing = false

        // Clean up
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Failed to deactivate audio session: \(error)")
        }

        print("⏹️ Recording stopped. Final transcription: \(transcription)")
    }

    /// Cancel recording without saving
    func cancelRecording() {
        stopRecording()
        transcription = ""
        error = nil
    }

    // MARK: - Helper Methods

    var canRecord: Bool {
        authorizationStatus == .authorized && speechRecognizer != nil
    }

    var needsAuthorization: Bool {
        authorizationStatus == .notDetermined
    }
}

// MARK: - Recognition Error

enum RecognitionError: LocalizedError, Identifiable {
    case authorizationDenied
    case microphoneAccessDenied
    case recognitionRequestFailed
    case audioEngineFailed
    case recognitionFailed(String)
    case onDeviceNotSupported

    var id: String {
        switch self {
        case .authorizationDenied: return "auth_denied"
        case .microphoneAccessDenied: return "mic_denied"
        case .recognitionRequestFailed: return "request_failed"
        case .audioEngineFailed: return "audio_failed"
        case .recognitionFailed: return "recognition_failed"
        case .onDeviceNotSupported: return "on_device_not_supported"
        }
    }

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Speech recognition permission was denied. Please enable it in Settings."
        case .microphoneAccessDenied:
            return "Microphone access was denied. Please enable it in Settings."
        case .recognitionRequestFailed:
            return "Failed to create speech recognition request."
        case .audioEngineFailed:
            return "Failed to initialize audio engine."
        case .recognitionFailed(let message):
            return "Recognition failed: \(message)"
        case .onDeviceNotSupported:
            return "On-device speech recognition is not supported on this device."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .authorizationDenied:
            return "Go to Settings > Privacy > Speech Recognition and enable access for Pocket Garden."
        case .microphoneAccessDenied:
            return "Go to Settings > Privacy > Microphone and enable access for Pocket Garden."
        case .onDeviceNotSupported:
            return "Please update to iOS 17 or later for on-device speech recognition."
        default:
            return "Please try again. If the problem persists, restart the app."
        }
    }
}
