//
//  VoiceJournalView.swift
//  pocket-garden
//
//  Voice Journal Entry View - Part 2 Implementation
//

import SwiftUI
import SwiftData

struct VoiceJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let emotionRating: Int

    @State private var speechService = SpeechRecognitionService()
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

                if speechService.needsAuthorization {
                    permissionRequestView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Voice Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if speechService.isRecording {
                            speechService.cancelRecording()
                        }
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
        .alert("Permission Required", isPresented: $showingPermissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            if let error = speechService.error {
                Text(error.recoverySuggestion ?? error.localizedDescription)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = speechService.error {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Permission Request View

    private var permissionRequestView: some View {
        ScrollView {
            VStack(spacing: Spacing.xxxl) {
                Spacer()
                    .frame(height: Spacing.xxxl)

                // Icon
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.primaryGreen)
                    .fadeIn()

                // Content
                VStack(spacing: Spacing.lg) {
                    Text("Voice Journaling")
                        .font(Typography.title)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Speak your thoughts and feelings. Your voice will be transcribed on-device for complete privacy.")
                        .font(Typography.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
                .fadeIn(delay: 0.2)

                // Privacy info cards
                VStack(spacing: Spacing.md) {
                    InfoCard(
                        icon: "lock.shield.fill",
                        title: "Private & Secure",
                        description: "All processing happens on your device. Nothing is sent to the cloud.",
                        iconColor: .successGreen
                    )

                    InfoCard(
                        icon: "waveform",
                        title: "Real-time Transcription",
                        description: "See your words appear as you speak using Apple's Speech Recognition.",
                        iconColor: .primaryGreen
                    )
                }
                .fadeIn(delay: 0.4)

                // Request button
                PrimaryButton("Enable Voice Journaling", icon: "mic.fill") {
                    Task {
                        let granted = await speechService.requestAuthorization()
                        if !granted {
                            showingPermissionDenied = true
                        }
                    }
                }
                .padding(.horizontal, Layout.screenPadding)
                .slideInFromBottom(delay: 0.6)

                Spacer()
            }
            .padding(Layout.screenPadding)
        }
    }

    // MARK: - Main Content View

    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: Spacing.xxxl) {
                // Emotion Summary
                emotionSummaryCard
                    .fadeIn()

                // Recording Interface
                recordingInterface
                    .slideInFromBottom(delay: 0.1)

                // Transcription Display
                if !speechService.transcription.isEmpty {
                    transcriptionCard
                        .fadeIn()
                }

                // Save Button
                if !speechService.transcription.isEmpty && !speechService.isRecording {
                    saveButton
                        .slideInFromBottom()
                }
            }
            .padding(Layout.screenPadding)
        }
    }

    // MARK: - Emotion Summary Card

    private var emotionSummaryCard: some View {
        Card {
            HStack(spacing: Spacing.lg) {
                Text(Theme.emoji(for: emotionRating))
                    .font(.system(size: 60))

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Feeling \(Theme.emotionLabel(for: emotionRating))")
                        .font(Typography.title3)
                        .foregroundColor(.textPrimary)

                    Text("Rating: \(emotionRating)/10")
                        .font(Typography.callout)
                        .foregroundColor(.textSecondary)
                }

                Spacer()
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Recording Interface

    private var recordingInterface: some View {
        VStack(spacing: Spacing.xl) {
            // Status text
            Text(statusText)
                .font(Typography.title3)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            // Waveform visualization or transcribing state
            ZStack {
                if speechService.isRecording {
                    CircularWaveform(isRecording: true)
                        .transition(.scale.combined(with: .opacity))
                } else if speechService.isTranscribing {
                    TranscriptionLoadingView()
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: speechService.isRecording || speechService.isTranscribing ? 200 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: speechService.isRecording)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: speechService.isTranscribing)

            // Recording button
            RecordingButton(
                isRecording: speechService.isRecording,
                isTranscribing: speechService.isTranscribing
            ) {
                toggleRecording()
            }
            .scaleEffect(speechService.isRecording ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: speechService.isRecording)

            // Recording timer
            if speechService.isRecording {
                RecordingTimer(seconds: recordingSeconds)
                    .transition(.scale.combined(with: .opacity))
            }

            // Helper text
            if !speechService.isRecording && speechService.transcription.isEmpty {
                Text("Tap the microphone to start recording")
                    .font(Typography.callout)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxl)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .cardShadow()
    }

    // MARK: - Transcription Card

    private var transcriptionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.primaryGreen)

                    Text("Transcription")
                        .font(Typography.headline)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    if speechService.isTranscribing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                Text(speechService.transcription)
                    .font(Typography.body)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled) // Allow text selection

                // Word count
                Text("\(wordCount) words")
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        VStack(spacing: Spacing.md) {
            if isGeneratingFeedback {
                // Show custom loading view when saving
                SavingEntryLoadingView()
                    .transition(.scale.combined(with: .opacity))
            } else {
                PrimaryButton(
                    "Save Entry",
                    icon: "checkmark",
                    isLoading: false
                ) {
                    Task {
                        await saveEntry()
                    }
                }
                .transition(.scale.combined(with: .opacity))

                if !speechService.transcription.isEmpty {
                    Button("Record Again") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            speechService.transcription = ""
                            recordingSeconds = 0
                        }
                    }
                    .font(Typography.callout)
                    .foregroundColor(.primaryGreen)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isGeneratingFeedback)
    }

    // MARK: - Helper Properties

    private var statusText: String {
        if speechService.isRecording {
            return "Recording..."
        } else if speechService.isTranscribing {
            return "Transcribing..."
        } else if !speechService.transcription.isEmpty {
            return "Recording Complete"
        } else {
            return "Ready to Record"
        }
    }

    private var wordCount: Int {
        speechService.transcription.split(separator: " ").count
    }

    // MARK: - Helper Methods

    private func toggleRecording() {
        if speechService.isRecording {
            // Stop recording
            stopRecording()
        } else {
            // Start recording
            startRecording()
        }
    }

    private func startRecording() {
        recordingSeconds = 0

        Task {
            do {
                try await speechService.startRecording()

                // Start timer
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    recordingSeconds += 1

                    // Auto-stop after 5 minutes
                    if recordingSeconds >= 300 {
                        stopRecording()
                    }
                }
            } catch {
                showingError = true
                print("❌ Failed to start recording: \(error)")
            }
        }
    }

    private func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil

        speechService.stopRecording()
    }

    private func saveEntry() async {
        isGeneratingFeedback = true

        // Create entry
        let entry = EmotionEntry(
            emotionRating: emotionRating,
            transcription: speechService.transcription
        )

        // Generate AI feedback
        let feedback = await AppleIntelligenceService.shared.generateFeedback(for: entry)
        entry.aiFeedback = feedback

        // Calculate tree stage
        let allEntries = try? modelContext.fetch(FetchDescriptor<EmotionEntry>())
        let entryCount = (allEntries?.count ?? 0) + 1
        entry.updateTreeStage(entryCount: entryCount)

        // Save to database
        modelContext.insert(entry)

        // Try to save context
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save entry: \(error)")
        }

        isGeneratingFeedback = false
        Theme.Haptics.success()

        // Show mascot feedback screen
        savedEntry = entry
        showMascotFeedback = true
    }
}

// MARK: - Preview

#Preview("Permission Request") {
    VoiceJournalView(emotionRating: 8)
        .modelContainer(for: EmotionEntry.self, inMemory: true)
}

#Preview("Recording") {
    struct RecordingPreview: View {
        @State private var service = SpeechRecognitionService()

        var body: some View {
            VoiceJournalView(emotionRating: 7)
                .modelContainer(for: EmotionEntry.self, inMemory: true)
                .onAppear {
                    service.authorizationStatus = .authorized
                }
        }
    }

    return RecordingPreview()
}
