//
//  EmotionEntry.swift
//  pocket-garden
//
//  SwiftData Model - Emotion Entry
//

import Foundation
import SwiftData

@Model
final class EmotionEntry {
    // MARK: - Properties

    /// Unique identifier
    var id: UUID

    /// Date of the entry
    var date: Date

    /// Emotion rating (1-10)
    var emotionRating: Int

    /// Voice recording file URL (optional)
    var voiceRecordingURL: URL?

    /// Transcribed text from voice recording
    var transcription: String?

    /// AI-generated feedback
    var aiFeedback: String?

    /// Tree growth stage (1-5)
    var treeStage: Int

    /// Optional mood tags
    var tags: [String]?

    /// Has user listened to AI feedback
    var hasViewedFeedback: Bool

    /// Is this a favorite entry
    var isFavorite: Bool

    // MARK: - Computed Properties

    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Day of week
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    /// Is today's entry
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Emotion color based on rating
    var emotionColor: String {
        // Store as hex string for persistence
        switch emotionRating {
        case 9...10: return "FFD93D" // Joy
        case 7...8: return "A8E6CF" // Content
        case 5...6: return "C8D6E5" // Neutral
        case 3...4: return "B4A5D5" // Melancholy
        case 1...2: return "8FA2C0" // Sad
        default: return "C8D6E5"
        }
    }

    /// Emotion label
    var emotionLabel: String {
        Theme.emotionLabel(for: emotionRating)
    }

    /// Has transcription
    var hasTranscription: Bool {
        transcription != nil && !(transcription?.isEmpty ?? true)
    }

    /// Has AI feedback
    var hasAIFeedback: Bool {
        aiFeedback != nil && !(aiFeedback?.isEmpty ?? true)
    }

    // MARK: - Initialization

    init(
        emotionRating: Int,
        date: Date = Date(),
        transcription: String? = nil,
        aiFeedback: String? = nil,
        treeStage: Int = 1,
        tags: [String]? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.emotionRating = max(1, min(10, emotionRating)) // Clamp to 1-10
        self.transcription = transcription
        self.aiFeedback = aiFeedback
        self.treeStage = max(1, min(5, treeStage)) // Clamp to 1-5
        self.tags = tags
        self.hasViewedFeedback = false
        self.isFavorite = false
    }

    // MARK: - Helper Methods

    /// Update tree stage based on entry count
    func updateTreeStage(entryCount: Int) {
        // Calculate tree stage based on sequential entries
        // 1-2 entries: Seed (stage 1)
        // 3-5 entries: Sprout (stage 2)
        // 6-10 entries: Young tree (stage 3)
        // 11-20 entries: Mature tree (stage 4)
        // 21+ entries: Blooming tree (stage 5)

        switch entryCount {
        case 1...2:
            self.treeStage = 1
        case 3...5:
            self.treeStage = 2
        case 6...10:
            self.treeStage = 3
        case 11...20:
            self.treeStage = 4
        default:
            self.treeStage = 5
        }
    }

    /// Add tag to entry
    func addTag(_ tag: String) {
        if tags == nil {
            tags = []
        }
        if !tags!.contains(tag) {
            tags!.append(tag)
        }
    }

    /// Remove tag from entry
    func removeTag(_ tag: String) {
        tags?.removeAll { $0 == tag }
    }

    /// Toggle favorite status
    func toggleFavorite() {
        isFavorite.toggle()
    }

    /// Mark feedback as viewed
    func markFeedbackViewed() {
        hasViewedFeedback = true
    }
}

// MARK: - Sample Data

extension EmotionEntry {
    /// Create sample entry for previews
    static func sample(rating: Int = 8, includeTranscription: Bool = true, includeFeedback: Bool = true) -> EmotionEntry {
        let entry = EmotionEntry(
            emotionRating: rating,
            date: Date(),
            transcription: includeTranscription ? "Today was a really good day. I felt productive and accomplished a lot of my goals. The weather was beautiful and I went for a walk in the park." : nil,
            aiFeedback: includeFeedback ? "It's wonderful to hear you had such a productive day! Taking time to enjoy nature during your walk shows great balance. Keep nurturing these positive moments. 🌱" : nil,
            treeStage: 3,
            tags: ["productive", "nature", "happy"]
        )
        return entry
    }

    /// Create multiple sample entries
    static func sampleEntries() -> [EmotionEntry] {
        let calendar = Calendar.current
        var entries: [EmotionEntry] = []

        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let rating = Int.random(in: 4...10)
            let entry = EmotionEntry(
                emotionRating: rating,
                date: date,
                transcription: i % 2 == 0 ? "Sample journal entry for day \(i)" : nil,
                aiFeedback: i % 2 == 0 ? "You're doing great! Keep growing. 🌱" : nil,
                treeStage: min(5, i / 2 + 1)
            )
            entries.append(entry)
        }

        return entries
    }
}
