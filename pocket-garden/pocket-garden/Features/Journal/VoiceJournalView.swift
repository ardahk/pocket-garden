//
//  VoiceJournalView.swift
//  pocket-garden
//
//  Voice Journal Entry View
//

import SwiftUI
import SwiftData

struct VoiceJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let emotionRating: Int

    @State private var isRecording = false
    @State private var transcription = ""
    @State private var showingSaveSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.peacefulGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xxxl) {
                        // Emotion Summary
                        emotionSummaryCard

                        // Recording Interface (Placeholder)
                        recordingInterface

                        // Transcription Display
                        if !transcription.isEmpty {
                            transcriptionCard
                        }

                        // Save Button
                        if !transcription.isEmpty {
                            saveButton
                        }
                    }
                    .padding(Layout.screenPadding)
                }
            }
            .navigationTitle("Voice Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGreen)
                }
            }
        }
        .alert("Entry Saved!", isPresented: $showingSaveSuccess) {
            Button("View Garden") {
                // Switch to garden tab
                dismiss()
            }
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Your tree is growing! 🌱")
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
        .fadeIn()
    }

    // MARK: - Recording Interface

    private var recordingInterface: some View {
        VStack(spacing: Spacing.xl) {
            Text(isRecording ? "Recording..." : "Tap to Start")
                .font(Typography.title3)
                .foregroundColor(.textPrimary)

            // Recording Button (Placeholder)
            Button(action: {
                Theme.Haptics.medium()
                isRecording.toggle()

                // Placeholder - simulate transcription after 2 seconds
                if !isRecording {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        transcription = "This is a placeholder transcription. In Part 2, we'll implement real voice recording and transcription using the Speech framework."
                    }
                }
            }) {
                ZStack {
                    if isRecording {
                        Circle()
                            .stroke(Color.errorRed.opacity(0.4), lineWidth: 4)
                            .frame(width: 100, height: 100)
                            .scaleEffect(isRecording ? 1.3 : 1.0)
                            .opacity(isRecording ? 0 : 1)
                            .animation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                                value: isRecording
                            )
                    }

                    Circle()
                        .fill(isRecording ? Color.errorRed : Color.primaryGreen)
                        .frame(width: 80, height: 80)

                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            .pressAnimation()

            Text("Voice recording will be implemented in Part 2")
                .font(Typography.caption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
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
                }

                Text(transcription)
                    .font(Typography.body)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
            }
        }
        .fadeIn()
    }

    // MARK: - Save Button

    private var saveButton: some View {
        PrimaryButton("Save Entry", icon: "checkmark") {
            saveEntry()
        }
        .slideInFromBottom()
    }

    // MARK: - Helper Methods

    private func saveEntry() {
        Theme.Haptics.success()

        // Create new entry
        let entry = EmotionEntry(
            emotionRating: emotionRating,
            transcription: transcription,
            aiFeedback: generatePlaceholderFeedback()
        )

        // Calculate tree stage based on total entries
        let allEntries = try? modelContext.fetch(FetchDescriptor<EmotionEntry>())
        let entryCount = (allEntries?.count ?? 0) + 1
        entry.updateTreeStage(entryCount: entryCount)

        // Save to database
        modelContext.insert(entry)

        showingSaveSuccess = true
    }

    private func generatePlaceholderFeedback() -> String {
        // Placeholder - AI feedback will be implemented in Part 2
        let templates = [
            "You're doing great! Keep nurturing these moments 🌱",
            "Your growth is inspiring! Keep going ✨",
            "Every day is a new opportunity to bloom 🌸",
            "You're building something beautiful 🌳"
        ]
        return templates.randomElement() ?? templates[0]
    }
}

// MARK: - Preview

#Preview {
    VoiceJournalView(emotionRating: 8)
        .modelContainer(for: EmotionEntry.self, inMemory: true)
}
