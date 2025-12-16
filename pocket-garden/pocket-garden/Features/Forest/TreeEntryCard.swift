//
//  TreeEntryCard.swift
//  pocket-garden
//
//  Compact entry card for the tree detail view
//

import SwiftUI

struct TreeEntryCard: View {
    let entry: EmotionEntry
    let onTap: () -> Void
    
    private var emotionColor: Color {
        Color.emotionColor(for: entry.emotionRating)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: entry.date)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: entry.date)
    }
    
    private var monthAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: entry.date)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: entry.date)
    }
    
    private var transcriptionPreview: String? {
        guard let text = entry.cleanedTranscription, !text.isEmpty else { return nil }
        let maxLength = 80
        if text.count > maxLength {
            return String(text.prefix(maxLength)) + "..."
        }
        return text
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Date badge
                VStack(spacing: 2) {
                    Text(formattedDate)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    Text(dayNumber)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text(monthAbbrev)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                .frame(width: 44)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(Color.backgroundCream)
                )
                
                // Divider line with emotion color
                Rectangle()
                    .fill(emotionColor)
                    .frame(width: 3)
                    .cornerRadius(1.5)
                
                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Rating and time
                    HStack(spacing: Spacing.sm) {
                        // Emotion circle
                        ZStack {
                            Circle()
                                .fill(emotionColor.opacity(0.2))
                                .frame(width: 28, height: 28)
                            
                            Text("\(entry.emotionRating)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(emotionColor)
                        }
                        
                        Text(entry.emotionLabel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Text(timeString)
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                    }
                    
                    // Transcription preview
                    if let preview = transcriptionPreview {
                        Text(preview)
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    } else {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "waveform")
                                .font(.system(size: 10))
                            Text("Voice entry")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.textSecondary.opacity(0.7))
                    }
                    
                    // Metadata row
                    HStack(spacing: Spacing.md) {
                        if entry.isFavorite {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondaryTerracotta)
                                Text("Favorite")
                                    .font(.system(size: 10))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        if entry.hasAIFeedback {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10))
                                    .foregroundColor(.primaryGreen)
                                Text("Has feedback")
                                    .font(.system(size: 10))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        // View details indicator
                        HStack(spacing: 2) {
                            Text("View")
                                .font(.system(size: 10, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .semibold))
                        }
                        .foregroundColor(.primaryGreen)
                    }
                }
                .padding(.vertical, Spacing.xs)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.md) {
        TreeEntryCard(
            entry: EmotionEntry.sample(rating: 8, includeTranscription: true, includeFeedback: true)
        ) {
            print("Tapped")
        }
        
        TreeEntryCard(
            entry: EmotionEntry.sample(rating: 5, includeTranscription: false, includeFeedback: false)
        ) {
            print("Tapped")
        }
        
        TreeEntryCard(
            entry: EmotionEntry.sample(rating: 3, includeTranscription: true, includeFeedback: true)
        ) {
            print("Tapped")
        }
    }
    .padding()
    .background(Color.peacefulGradient)
}

