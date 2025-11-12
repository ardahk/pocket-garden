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
    
    // Service selection - Default to Whisper only
    @State private var useWhisper = true
    
    // Services
    // @State private var speechService = SpeechRecognitionService()
    @State private var whisperService = WhisperService()
    
    // Recording state
    @State private var recordingSeconds: Int = 0
    @State private var recordingTimer: Timer?
    @State private var showingPermissionDenied = false
    @State private var showingError = false
    @State private var isGeneratingFeedback = false
    @State private var showMascotFeedback = false
    @State private var savedEntry: EmotionEntry?
    
    
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
            .navigationTitle("Voice Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelRecording()
                        dismiss()
                    }
                    .foregroundColor(.primaryGreen)
                }
            }
        }
        .fullScreenCover(isPresented: $showMascotFeedback) {
            if let entry = savedEntry {
                MascotFeedbackView(entry: entry) {
                    showMascotFeedback = false
                    dismiss()
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
            // Status
            statusView
            
            // Transcription
            if !transcription().isEmpty {
                transcriptionView
            }
            
            Spacer()
            
            // Controls
            recordingControlsView
            
            // Save button
            if !transcription().isEmpty && !isRecording() {
                saveButtonView
            }
            
            // Record again
            if !transcription().isEmpty {
                Button("Record Again") {
                    cancelRecording()
                    recordingSeconds = 0
                }
                .font(Typography.callout)
                .foregroundColor(.primaryGreen)
            }
        }
        .padding()
    }
    
    // MARK: - Status View
    
    private var statusView: some View {
        VStack(spacing: Spacing.md) {
            // Recording indicator
            ZStack {
                Circle()
                    .fill(isRecording() ? Color.red.opacity(0.1) : Color.primaryGreen.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                if isRecording() {
                    Circle()
                        .stroke(Color.red, lineWidth: 3)
                        .frame(width: 120, height: 120)
                        .opacity(0.8)
                        .scaleEffect(1.1)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isRecording())
                }
                
                Image(systemName: isRecording() ? "waveform" : "mic.fill")
                    .font(.system(size: 50))
                    .foregroundColor(isRecording() ? .red : .primaryGreen)
            }
            
            // Status text
            if isRecording() {
                VStack(spacing: Spacing.xs) {
                    Text("Recording...")
                        .font(Typography.title3)
                        .fontWeight(.semibold)
                    
                    Text(formatTime(recordingSeconds))
                        .font(Typography.body)
                        .foregroundColor(.textSecondary)
                        .monospacedDigit()
                }
            } else if isTranscribing() {
                VStack(spacing: Spacing.xs) {
                    Text("Transcribing...")
                        .font(Typography.title3)
                        .fontWeight(.semibold)
                    
                    if whisperService.transcriptionProgress > 0 {
                        ProgressView(value: whisperService.transcriptionProgress)
                            .frame(width: 200)
                    } else {
                        ProgressView()
                    }
                }
            } else {
                Text("Tap to record")
                    .font(Typography.title3)
                    .fontWeight(.semibold)
            }
        }
    }
    
    // MARK: - Transcription View
    
    private var transcriptionView: some View {
        Card {
            ScrollView {
                Text(transcription())
                    .font(Typography.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxHeight: 300)
        }
    }
    
    // MARK: - Recording Controls
    
    private var recordingControlsView: some View {
        HStack(spacing: Spacing.xl) {
            // Stop/Cancel button
            if isRecording() {
                Button {
                    stopRecording()
                    Theme.Haptics.medium()
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "stop.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 24))
                            )
                        Text("Stop")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            } else {
                // Record button
                Button {
                    startRecording()
                    Theme.Haptics.medium()
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(Color.primaryGreen)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "mic.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 32))
                            )
                        Text("Record")
                            .font(Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }
                }
                .disabled(isTranscribing())
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
        }
    }
    
    private func cancelRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingSeconds = 0
        
        whisperService.cancelRecording()
    }
    
    private func saveEntry() {
        isGeneratingFeedback = true
        
        let entry = EmotionEntry(
            emotionRating: emotionRating,
            date: Date(),
            transcription: transcription().isEmpty ? nil : transcription()
        )
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
            savedEntry = entry
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isGeneratingFeedback = false
                showMascotFeedback = true
            }
        } catch {
            print("Failed to save entry: \(error)")
            showingError = true
            isGeneratingFeedback = false
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
