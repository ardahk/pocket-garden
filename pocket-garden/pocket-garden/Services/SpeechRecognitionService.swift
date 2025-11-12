//
//  SpeechRecognitionService.swift
//  pocket-garden
//
//  Voice Recording and Transcription Service
//

internal import Speech
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
    
    // Accumulate all final transcriptions
    private var accumulatedTranscription: String = ""
    private var observersAdded: Bool = false
    private var lastProcessedSegmentIndex: Int = 0
    private var restartTimer: Timer?

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

    deinit {
        if observersAdded {
            NotificationCenter.default.removeObserver(self)
        }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard isRecording else { return }
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        switch type {
        case .began:
            isTranscribing = false
        case .ended:
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    Task { try? await self.restartRecognition() }
                }
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard isRecording else { return }
        Task { try? await self.restartRecognition() }
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

        // Request microphone permission (iOS)
        let micStatus = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }

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

        // Enable on-device recognition for privacy and optimize for dictation
        recognitionRequest.taskHint = .dictation
        recognitionRequest.requiresOnDeviceRecognition = speechRecognizer?.supportsOnDeviceRecognition ?? false

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
        error = nil

        // Seed accumulated text from any existing visible transcription
        if transcription.count > accumulatedTranscription.count {
            accumulatedTranscription = transcription
        }
        lastProcessedSegmentIndex = 0

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcription = result.bestTranscription
                let total = transcription.segments.count
                if total > self.lastProcessedSegmentIndex {
                    let newSegs = transcription.segments[self.lastProcessedSegmentIndex..<total]
                    var appended = ""
                    for seg in newSegs {
                        let s = seg.substring
                        if [".", ",", "!", "?", ":", ";"].contains(s) {
                            appended += s
                        } else {
                            appended += (appended.isEmpty && self.accumulatedTranscription.isEmpty) ? s : " " + s
                        }
                    }
                    let cleaned = appended.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleaned.isEmpty {
                        if self.accumulatedTranscription.isEmpty {
                            self.accumulatedTranscription = cleaned
                        } else {
                            self.accumulatedTranscription += (self.accumulatedTranscription.hasSuffix(" ") || cleaned.hasPrefix(" ") ? "" : " ") + cleaned
                        }
                        DispatchQueue.main.async { self.transcription = self.accumulatedTranscription }
                    }
                    self.lastProcessedSegmentIndex = total
                }

                if result.isFinal {
                    self.isTranscribing = false
                    print("📝 Finalized a segment. Total so far: \(self.accumulatedTranscription)")
                    // Timer will handle restart to prevent double-restarts
                }
            }

            if let error = error {
                let nsError = error as NSError
                // Ignore transient errors during continuous recognition (timer handles restarts)
                if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
                    print("⚠️ No speech detected, timer will restart...")
                    if self.isRecording {
                        if !self.transcription.isEmpty { self.accumulatedTranscription = self.transcription }
                    }
                    return
                }

                // Preserve text on transient errors while recording (timer handles restarts)
                if self.isRecording {
                    print("⚠️ Recognition interrupted: \(nsError.localizedDescription). Timer will restart…")
                    if !self.transcription.isEmpty { self.accumulatedTranscription = self.transcription }
                    return
                }

                print("❌ Recognition error: \(nsError.localizedDescription)")
                self.error = .recognitionFailed(nsError.localizedDescription)
                self.stopRecording()
            }
        }

        if !observersAdded {
            NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
            observersAdded = true
        }

        // Start timer to proactively restart recognition every 8 seconds
        // This prevents iOS from finalizing transcription on pauses
        startRestartTimer()

        print("🎤 Recording started")
    }

    /// Restart recognition task to continue capturing speech
    private func restartRecognition() async throws {
        guard isRecording, let audioEngine = audioEngine else { return }
        
        // Cancel current recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create new recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw RecognitionError.recognitionRequestFailed
        }
        
        // Enable on-device recognition for privacy and optimize for dictation
        recognitionRequest.taskHint = .dictation
        recognitionRequest.requiresOnDeviceRecognition = true
        
        // Enable partial results for real-time transcription
        recognitionRequest.shouldReportPartialResults = true
        
        if !audioEngine.isRunning {
            audioEngine.prepare()
            try? audioEngine.start()
        }

        // The audio engine is already running, we just need to reconnect the tap
        // Remove old tap
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Reinstall tap with new request
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        // Seed and reset segment index so we only append deltas
        if transcription.count > accumulatedTranscription.count {
            accumulatedTranscription = transcription
        }
        lastProcessedSegmentIndex = 0

        // Start new recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcription = result.bestTranscription
                let total = transcription.segments.count
                if total > self.lastProcessedSegmentIndex {
                    let newSegs = transcription.segments[self.lastProcessedSegmentIndex..<total]
                    var appended = ""
                    for seg in newSegs {
                        let s = seg.substring
                        if [".", ",", "!", "?", ":", ";"].contains(s) {
                            appended += s
                        } else {
                            appended += (appended.isEmpty && self.accumulatedTranscription.isEmpty) ? s : " " + s
                        }
                    }
                    let cleaned = appended.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleaned.isEmpty {
                        if self.accumulatedTranscription.isEmpty {
                            self.accumulatedTranscription = cleaned
                        } else {
                            self.accumulatedTranscription += (self.accumulatedTranscription.hasSuffix(" ") || cleaned.hasPrefix(" ") ? "" : " ") + cleaned
                        }
                        DispatchQueue.main.async { self.transcription = self.accumulatedTranscription }
                    }
                    self.lastProcessedSegmentIndex = total
                }

                if result.isFinal {
                    self.isTranscribing = false
                    print("📝 Finalized a segment. Total so far: \(self.accumulatedTranscription)")
                    // Timer will handle restart to prevent double-restarts
                }
            }
            
            if let error = error {
                let nsError = error as NSError
                // Ignore transient errors during continuous recognition (timer handles restarts)
                if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
                    print("⚠️ No speech detected, timer will restart...")
                    return
                }
                // Preserve text on transient errors while recording
                if self.isRecording {
                    if !self.transcription.isEmpty {
                        self.accumulatedTranscription = self.transcription
                    }
                    print("⚠️ Recognition error: \(nsError.localizedDescription). Timer will restart…")
                    return
                }

                print("❌ Recognition error: \(nsError.localizedDescription)")
                self.error = .recognitionFailed(nsError.localizedDescription)
                self.stopRecording()
            }
        }
        
        print("🔄 Recognition restarted")
    }
    
    /// Stop recording and finalize transcription
    func stopRecording() {
        // Stop timer
        stopRestartTimer()
        
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
        stopRestartTimer()
        stopRecording()
        transcription = ""
        accumulatedTranscription = ""
        error = nil
    }
    
    // MARK: - Timer Management
    
    /// Start a timer to proactively restart recognition every 8 seconds
    /// This prevents iOS from clearing transcription on pauses (iOS 18 issue)
    private func startRestartTimer() {
        stopRestartTimer()
        restartTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            print("⏱️ Timer-triggered restart to maintain continuous transcription")
            Task {
                try? await self.restartRecognition()
            }
        }
    }
    
    /// Stop and invalidate the restart timer
    private func stopRestartTimer() {
        restartTimer?.invalidate()
        restartTimer = nil
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
            return "Please update to iOS 18 or later for on-device speech recognition."
        default:
            return "Please try again. If the problem persists, restart the app or your device."
        }
    }
}
