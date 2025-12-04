//
//  EntryDetailViewRedesigned.swift
//  pocket-garden
//
//  Redesigned Entry Detail View
//

import SwiftUI
import SwiftData
import AVFoundation

struct EntryDetailViewRedesigned: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let entry: EmotionEntry
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackRate: Float = 1.0
    @State private var audioDelegate: EntryAudioDelegate?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peacefulGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header with date and favorite
                        headerSection
                        
                        emotionCard
                        
                        if entry.voiceRecordingURL != nil {
                            audioCard
                        }
                        
                        // Journal entry
                        if entry.hasTranscription {
                            journalEntryCard
                        }
                        
                        // What Panda Says (AI Feedback)
                        if entry.hasAIFeedback {
                            bumblebeeFeedbackCard
                        }
                    }
                    .padding(Layout.screenPadding)
                    .padding(.bottom, Spacing.xxxl)
                }
            }
            .navigationTitle(entry.formattedDateShort)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGreen)
                }
            }
            .onDisappear {
                stopPlayback()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(entry.dayOfWeek)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                
                Text(entry.formattedDate)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
            
            Button(action: {
                let wasFavorite = entry.isFavorite
                entry.toggleFavorite()
                if wasFavorite && !entry.isFavorite, let url = entry.voiceRecordingURL {
                    try? FileManager.default.removeItem(at: url)
                    entry.voiceRecordingURL = nil
                }
                try? modelContext.save()
                Theme.Haptics.light()
            }) {
                Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 28))
                    .foregroundColor(entry.isFavorite ? .errorRed : .textSecondary.opacity(0.3))
            }
        }
        .fadeIn()
    }
    
    // MARK: - Emotion Card
    
    private var emotionCard: some View {
        Card {
            HStack(spacing: Spacing.lg) {
                // Emotion emoji
                Text(Theme.emoji(for: entry.emotionRating))
                    .font(.system(size: 64))
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(Theme.emotionLabel(for: entry.emotionRating))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Rating: \(entry.emotionRating)/10")
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
            }
            .padding(.vertical, Spacing.sm)
        }
        .slideInFromBottom(delay: 0.1)
    }
    
    // MARK: - Audio Card

    private var audioCard: some View {
        Card {
            HStack(spacing: Spacing.md) {
                // Play / pause area
                Button(action: togglePlayback) {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.primaryGreen)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Voice Recording")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.textPrimary)

                            if !isPlaying {
                                Text("Tap to play your original journal audio.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Playback speed control
                Button(action: cyclePlaybackRate) {
                    Text(playbackRateLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.cardBackground.opacity(0.9))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .slideInFromBottom(delay: 0.15)
    }
    
    // MARK: - Journal Entry Card
    
    private var journalEntryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header with icon
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 18))
                        .foregroundColor(.primaryGreen)
                    
                    Text("Journal Entry")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                }
                
                // Cleaned transcription (without Whisper artifacts)
                Text(entry.cleanedTranscription ?? "")
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(6)
                
                // Tags
                if entry.moodCategory != nil || entry.focusArea != nil {
                    HStack(spacing: Spacing.sm) {
                        if let mood = entry.moodCategory {
                            TagView(text: mood, color: moodColor(for: mood))
                        }
                        
                        if let focus = entry.focusArea {
                            TagView(text: focus, color: .textSecondary)
                        }
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }
        .slideInFromBottom(delay: 0.2)
    }
    
    // MARK: - Bumblebee Feedback Card
    
    private var bumblebeeFeedbackCard: some View {
        Card(backgroundColor: Color.accentGold.opacity(0.08)) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header with panda
                HStack(spacing: Spacing.sm) {
                    Text("🐝")
                        .font(.system(size: 24))
                    
                    Text("What Bumblebee Says")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                }
                
                // Feedback text
                Text(entry.aiFeedback ?? "")
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(6)
            }
        }
        .slideInFromBottom(delay: 0.3)
    }
    
    // MARK: - Helper Functions
    
    private func moodColor(for mood: String) -> Color {
        switch mood {
        case "Productive": return .primaryGreen
        case "Mindful": return .emotionContent
        case "Reflective": return .secondaryTerracotta
        case "Excited": return .accentGold
        case "Grateful": return .primaryGreen
        case "Peaceful": return .emotionContent
        case "Energized": return .accentGold
        case "Joyful": return .primaryGreen
        default: return .textSecondary
        }
    }
    
    private func togglePlayback() {
        guard let url = entry.voiceRecordingURL else { return }

        // Pause if already playing
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
            return
        }

        // Ensure file still exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Audio file not found at path: \(url.path)")
            return
        }

        // Configure audio session for playback
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        // Lazily create the player
        if audioPlayer == nil {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.enableRate = true
                player.rate = playbackRate
                player.prepareToPlay()

                let delegate = EntryAudioDelegate()
                delegate.onFinish = {
                    DispatchQueue.main.async {
                        isPlaying = false
                    }
                }
                player.delegate = delegate
                audioDelegate = delegate

                audioPlayer = player
            } catch {
                print("Failed to load audio: \(error)")
                return
            }
        }

        audioPlayer?.enableRate = true
        audioPlayer?.rate = playbackRate
        audioPlayer?.play()
        isPlaying = true
    }

    private var playbackRateLabel: String {
        switch playbackRate {
        case 1.0: return "1x"
        case 1.5: return "1.5x"
        default: return "2x"
        }
    }

    private func cyclePlaybackRate() {
        if playbackRate == 1.0 {
            playbackRate = 1.5
        } else if playbackRate == 1.5 {
            playbackRate = 2.0
        } else {
            playbackRate = 1.0
        }

        audioPlayer?.enableRate = true
        audioPlayer?.rate = playbackRate
    }

    private func stopPlayback() {
        guard isPlaying || audioPlayer != nil else { return }

        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false

        // Deactivate the audio session so playback fully stops when leaving
        // this screen, while letting other audio (like music/podcasts) resume.
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}

// MARK: - Audio Delegate

final class EntryAudioDelegate: NSObject, AVAudioPlayerDelegate {
    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}

// MARK: - EmotionEntry Extension

extension EmotionEntry {
    var formattedDateShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
