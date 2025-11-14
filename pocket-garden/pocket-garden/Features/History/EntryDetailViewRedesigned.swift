//
//  EntryDetailViewRedesigned.swift
//  pocket-garden
//
//  Redesigned Entry Detail View
//

import SwiftUI
import SwiftData

struct EntryDetailViewRedesigned: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let entry: EmotionEntry
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peacefulGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header with date and favorite
                        headerSection
                        
                        // Emotion card
                        emotionCard
                        
                        // Journal entry
                        if entry.hasTranscription {
                            journalEntryCard
                        }
                        
                        // What Panda Says (AI Feedback)
                        if entry.hasAIFeedback {
                            pandaFeedbackCard
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
            
            // Favorite button
            Button(action: {
                entry.toggleFavorite()
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
    
    // MARK: - Panda Feedback Card
    
    private var pandaFeedbackCard: some View {
        Card(backgroundColor: Color.accentGold.opacity(0.08)) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header with panda
                HStack(spacing: Spacing.sm) {
                    Text("🐼")
                        .font(.system(size: 24))
                    
                    Text("What Panda Says")
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
}

// MARK: - EmotionEntry Extension

extension EmotionEntry {
    var formattedDateShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
