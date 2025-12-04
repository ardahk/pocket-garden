//
//  VoiceJournalExperimentView.swift
//  pocket-garden
//
//  Experimental Voice Journal View with SwiftWhisper Toggle
//

import SwiftUI
import SwiftData
import Inject

struct VoiceJournalExperimentView: View {
    @ObserveInjection var inject
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let emotionRating: Int
    var onComplete: (() -> Void)? = nil
    
    // Service selection - Default to Whisper only
    @State private var useWhisper = true
    
    // Services
    // @State private var speechService = SpeechRecognitionService()
    @State private var whisperService = WhisperService()
    @State private var classificationService: Any? = nil // Will be EntryClassificationService if available
    
    // Recording state
    @State private var recordingSeconds: Int = 0
    @State private var recordingTimer: Timer?
    @State private var showingPermissionDenied = false
    @State private var showingError = false
    @State private var isGeneratingFeedback = false
    @State private var showMascotFeedback = false
    @State private var savedEntry: EmotionEntry?
    @State private var previousTranscription: String = "" // For appending mode
    @State private var saveAudioAsFavorite: Bool = false
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.peacefulGradient
                    .ignoresSafeArea()
                
                VStack(spacing: Spacing.lg) {
                    // Remove service toggle - Whisper only
                    // serviceToggleView
                    
                    if needsAuthorization() {
                        permissionRequestView
                    } else {
                        mainContentView
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topLeading) {
                if !needsAuthorization() {
                    Button(action: {
                        cancelRecording()
                        dismiss()
                    }) {
                        Circle()
                            .fill(Color.cardBackground)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, Layout.screenPadding)
                    .padding(.top, 50)
                }
            }
            .overlay(alignment: .top) {
                if isRecording() && !needsAuthorization() {
                    Text(formatTime(recordingSeconds))
                        .font(.system(size: 18, weight: .medium))
                        .monospacedDigit()
                        .foregroundColor(.textPrimary)
                        .padding(.top, 50)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if isRecording() && !needsAuthorization() {
                // Stop recording button with panda
                Button(action: {
                    stopRecording()
                    Theme.Haptics.medium()
                }) {
                    HStack(spacing: Spacing.md) {
                        // Stop square icon
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(light: "FFFFFF", dark: "2A2A2E"))
                            .frame(width: 24, height: 24)
                        
                        Text("Stop Recording")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(light: "FFFFFF", dark: "2A2A2E"))
                        
                        Spacer()
                        
                        // Bumblebee emoji circle
                        Circle()
                            .fill(Color(light: "FFFFFF", dark: "2A2A2E"))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text("🐝")
                                    .font(.system(size: 28))
                            )
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 50)
                            .fill(Color.red.opacity(0.8))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Layout.screenPadding)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showMascotFeedback) {
            if let entry = savedEntry {
                MascotFeedbackView(entry: entry) {
                    showMascotFeedback = false
                    dismiss()
                    // Call completion callback to switch to garden tab
                    onComplete?()
                }
            }
        }
        .enableInjection()
    }
    
    // MARK: - Service Toggle (Commented out - Whisper only)
    /*
    private var serviceToggleView: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Transcription Method")
                    .font(Typography.subheadline)
                    .foregroundColor(.primaryGreen)
                
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(useWhisper ? "Whisper (OpenAI)" : "Apple SFSpeech")
                            .font(Typography.body)
                            .fontWeight(.medium)
                        
                        Text(useWhisper 
                            ? "Transcribes after recording • More reliable • Offline"
                            : "Real-time transcription • Timer-based restarts")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $useWhisper)
                        .labelsHidden()
                        .disabled(isRecording())
                }
            }
        }
        .opacity(isRecording() ? 0.6 : 1.0)
    }
    */
    
    // MARK: - Permission Request
    
    private var permissionRequestView: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.primaryGreen)
            
            VStack(spacing: Spacing.md) {
                Text("Voice Journaling")
                    .font(Typography.title)
                    .fontWeight(.bold)
                
                Text("Express your thoughts naturally with voice transcription")
                    .font(Typography.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                FeatureRow(
                    icon: "lock.shield.fill",
                    text: "Private & Secure",
                    description: "100% on-device processing"
                )
                
                FeatureRow(
                    icon: "waveform",
                    text: "Process After Recording",
                    description: "Speak freely, transcribe when done"
                )
                
                FeatureRow(
                    icon: "sparkles",
                    text: "AI-Powered Insights",
                    description: "Get gentle feedback from your garden mascot"
                )
            }
            .padding(.horizontal)
            
            PrimaryButton("Enable Voice Journaling", icon: "mic.fill") {
                Task {
                    let granted = await requestPermissions()
                    if !granted {
                        showingPermissionDenied = true
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Main Content
    
    private var mainContentView: some View {
        VStack(spacing: Spacing.xl) {
            // Add top spacing to avoid X button overlap
            Spacer()
                .frame(height: 40)
            
            // Status
            statusView
            
            // Transcription
            if !transcription().isEmpty {
                transcriptionView
            }
            
            Spacer()
            
            // Controls
            recordingControlsView
            
            // Action buttons
            if !transcription().isEmpty && !isRecording() {
                VStack(spacing: Spacing.md) {
                    // Favorite + keep audio toggle (directly under transcription)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Toggle(isOn: $saveAudioAsFavorite) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: saveAudioAsFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(saveAudioAsFavorite ? .errorRed : .textSecondary)
                                Text("Mark as favorite and keep audio (up to 5 minutes)")
                                    .font(Typography.callout)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .tint(.primaryGreen)
                        .disabled(recordingSeconds > 300)
                        .opacity(recordingSeconds > 300 ? 0.6 : 1.0)

                        if recordingSeconds > 300 {
                            Text("Recordings over 5 minutes save text only.")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    // Continue Adding button
                    SecondaryButton("Continue Adding", icon: "plus.mic.fill") {
                        previousTranscription = transcription()
                        startRecording()
                        Theme.Haptics.medium()
                    }

                    // Save button
                    saveButtonView

                    // Record again text button
                    Button("Record Again") {
                        cancelRecording()
                        recordingSeconds = 0
                        saveAudioAsFavorite = false
                    }
                    .buttonStyle(.plain)
                    .font(Typography.callout)
                    .foregroundColor(.primaryGreen)
                }
            }
            
            // Bottom spacing to avoid stop button overlap
            Spacer()
                .frame(height: 100)
        }
        .padding()
    }
    
    // MARK: - Status View
    
    private var statusView: some View {
        VStack(spacing: Spacing.xl) {
            if isTranscribing() {
                // Thinking panda with cleaner design
                VStack(spacing: Spacing.xl) {
                    GardenMascot(emotion: .thinking, size: 120)
                    
                    Text("Transcribing...")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    if whisperService.transcriptionProgress > 0 {
                        ProgressView(value: whisperService.transcriptionProgress)
                            .tint(.primaryGreen)
                            .frame(width: 200)
                    }
                }
            } else if !isRecording() {
                // Initial state - simple instruction
                EmptyView()
            }
        }
    }
    
    // MARK: - Transcription View
    
    private var transcriptionView: some View {
        Card {
            TextEditor(text: Binding(
                get: { transcription() },
                set: { whisperService.transcription = $0 }
            ))
            .font(Typography.body)
            .frame(minHeight: 140, maxHeight: 300, alignment: .topLeading)
            .scrollContentBackground(.hidden)
            .padding(.top, Spacing.xs)
        }
    }
    
    // MARK: - Recording Controls
    
    private var recordingControlsView: some View {
        VStack(spacing: 0) {
            if isRecording() {
                // Concentric circles driven by live audio level (slow, voice-synced pulse)
                let level = whisperService.audioLevel
                ZStack {
                    // Outer circle - very subtle, slow swell
                    Circle()
                        .fill(Color.primaryGreen.opacity(0.08))
                        .frame(width: 300, height: 300)
                        .scaleEffect(0.95 + 0.10 * level)
                        .animation(.easeOut(duration: 0.25), value: level)
                    
                    // Middle circle
                    Circle()
                        .fill(Color.primaryGreen.opacity(0.15))
                        .frame(width: 220, height: 220)
                        .scaleEffect(0.96 + 0.14 * level)
                        .animation(.easeOut(duration: 0.22), value: level)
                    
                    // Inner circle - main pulse
                    Circle()
                        .fill(Color.primaryGreen)
                        .frame(width: 140, height: 140)
                        .scaleEffect(0.98 + 0.18 * level)
                        .animation(.easeOut(duration: 0.2), value: level)
                    
                    // Center icon
                    Image(systemName: "mic.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color(light: "FFFFFF", dark: "2A2A2E"))
                }
                .padding(.vertical, 30)
            } else if !isTranscribing() && transcription().isEmpty {
                // Initial state - concentric circles
                ZStack {
                    // Outer circle
                    Circle()
                        .fill(Color.primaryGreen.opacity(0.1))
                        .frame(width: 300, height: 300)
                    
                    // Middle circle
                    Circle()
                        .fill(Color.primaryGreen.opacity(0.2))
                        .frame(width: 220, height: 220)
                    
                    // Inner circle
                    Circle()
                        .fill(Color.primaryGreen)
                        .frame(width: 140, height: 140)
                    
                    // Center icon
                    Image(systemName: "mic.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color(light: "FFFFFF", dark: "2A2A2E"))
                }
                .padding(.vertical, 60)
                .onTapGesture {
                    startRecording()
                    Theme.Haptics.medium()
                }
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButtonView: some View {
        PrimaryButton("Save Journal Entry", icon: "checkmark.circle.fill") {
            saveEntry()
        }
        .disabled(isGeneratingFeedback)
    }
    
    // MARK: - Helper Methods
    
    private func needsAuthorization() -> Bool {
        // Whisper doesn't need speech recognition authorization, only microphone
        false
    }
    
    private func isRecording() -> Bool {
        whisperService.isRecording
    }
    
    private func isTranscribing() -> Bool {
        whisperService.isTranscribing
    }
    
    private func transcription() -> String {
        whisperService.transcription
    }
    
    private func requestPermissions() async -> Bool {
        return await whisperService.requestPermissions()
    }
    
    private func startRecording() {
        Task {
            do {
                try await whisperService.startRecording()
                
                // Start timer
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    recordingSeconds += 1
                }
                saveAudioAsFavorite = false
            } catch {
                showingError = true
            }
        }
    }
    
    private func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        Task {
            await whisperService.stopRecording()
            
            // If we were appending, combine with previous transcription
            if !previousTranscription.isEmpty {
                whisperService.transcription = previousTranscription + " " + whisperService.transcription
                previousTranscription = "" // Reset
            }
        }
    }
    
    private func cancelRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingSeconds = 0
        saveAudioAsFavorite = false
        
        whisperService.cancelRecording()
    }
    
    private func saveEntry() {
        isGeneratingFeedback = true
        let shouldFavorite = saveAudioAsFavorite
        let shouldSaveAudio = saveAudioAsFavorite && recordingSeconds <= 300

        let entry = EmotionEntry(
            emotionRating: emotionRating,
            date: Date(),
            transcription: transcription().isEmpty ? nil : transcription()
        )
        entry.isFavorite = shouldFavorite
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
            savedEntry = entry
            
            // Classify entry in background
            Task {
                await classifyEntry(entry)
            }
            
            if shouldSaveAudio {
                Task {
                    do {
                        let url = try await whisperService.exportCompressedAudio(forEntryID: entry.id)
                        await MainActor.run {
                            entry.voiceRecordingURL = url
                            try? modelContext.save()
                        }
                    } catch {
                        whisperService.discardRecordingFile()
                        print("Failed to export audio: \(error)")
                    }
                }
            } else {
                whisperService.discardRecordingFile()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isGeneratingFeedback = false
                showMascotFeedback = true
                saveAudioAsFavorite = false
                recordingSeconds = 0
            }
        } catch {
            print("Failed to save entry: \(error)")
            showingError = true
            isGeneratingFeedback = false
        }
    }
    
    private func classifyEntry(_ entry: EmotionEntry) async {
        guard let text = entry.cleanedTranscription, !text.isEmpty else { return }
        
        // Try AFM classification first (iOS 26+)
        if #available(iOS 26.0, *) {
            if classificationService == nil {
                classificationService = EntryClassificationService()
            }
            
            if let service = classificationService as? EntryClassificationService {
                do {
                    let result = try await service.classifyEntry(transcription: text)
                    await MainActor.run {
                        entry.moodCategory = result.moodCategory
                        entry.focusArea = result.focusArea
                        try? modelContext.save()
                    }
                    return
                } catch {
                    print("AFM classification failed: \(error)")
                }
            }
        }
        
        // Fallback classification
        let fallback = FallbackClassificationService()
        let result = fallback.classifyEntry(transcription: text, rating: entry.emotionRating)
        await MainActor.run {
            entry.moodCategory = result.moodCategory
            entry.focusArea = result.focusArea
            try? modelContext.save()
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.primaryGreen)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(text)
                    .font(Typography.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

// MARK: - Voice Service Protocol (Commented out - not needed for Whisper only)
/*
protocol VoiceServiceProtocol {
    var isRecording: Bool { get }
    var isTranscribing: Bool { get }
    var transcription: String { get }
}

extension SpeechRecognitionService: VoiceServiceProtocol {}
extension WhisperService: VoiceServiceProtocol {}
*/

// MARK: - Preview

#Preview {
    VoiceJournalExperimentView(emotionRating: 4)
        .modelContainer(for: EmotionEntry.self, inMemory: true)
}
