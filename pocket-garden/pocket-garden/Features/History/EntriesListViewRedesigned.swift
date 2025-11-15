//
//  EntriesListViewRedesigned.swift
//  pocket-garden
//
//  Redesigned History View with AFM Classification
//

import SwiftUI
import SwiftData

struct EntriesListViewRedesigned: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EmotionEntry.date, order: .reverse) private var allEntries: [EmotionEntry]
    
    @State private var searchText = ""
    @State private var selectedEntry: EmotionEntry?
    @State private var showFavoritesOnly = false
    
    private var entries: [EmotionEntry] {
        showFavoritesOnly ? allEntries.filter { $0.isFavorite } : allEntries
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundCream
                    .ignoresSafeArea()
                
                if entries.isEmpty {
                    emptyStateView
                } else {
                    entriesListView
                }
            }
            .navigationTitle("Your Journals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Favorites filter button
                    Button(action: {
                        withAnimation {
                            showFavoritesOnly.toggle()
                        }
                        Theme.Haptics.light()
                    }) {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundColor(showFavoritesOnly ? .errorRed : .textSecondary)
                            .font(.system(size: 20))
                    }
                }
            }
            .searchable(
                text: $searchText,
                prompt: showFavoritesOnly ? "Search favorites..." : "Search entries..."
            )
            .sheet(item: $selectedEntry) { entry in
                EntryDetailViewRedesigned(entry: entry)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            Text(showFavoritesOnly ? "💝" : "📔")
                .font(.system(size: 80))
            
            Text(showFavoritesOnly ? "No Favorites Yet" : "No Entries Yet")
                .font(Typography.title2)
                .foregroundColor(.textPrimary)
            
            Text(showFavoritesOnly ? "Tap the heart on entries you love" : "Your journal entries will appear here")
                .font(Typography.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Layout.screenPadding)
    }
    
    // MARK: - Entries List
    
    private var entriesListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xl) {
                ForEach(orderedSections, id: \.self) { section in
                    Section {
                        VStack(spacing: Spacing.md) {
                            ForEach(groupedEntries[section] ?? []) { entry in
                                JournalEntryRow(entry: entry) {
                                    selectedEntry = entry
                                }
                            }
                        }
                    } header: {
                        Text(section)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Layout.screenPadding)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.backgroundCream)
                    }
                }
            }
            .padding(.vertical, Spacing.md)
        }
    }
    
    // MARK: - Grouped Entries
    
    private var groupedEntries: [String: [EmotionEntry]] {
        let calendar = Calendar.current
        let filtered = filteredEntries
        
        var groups: [String: [EmotionEntry]] = [:]
        
        for entry in filtered {
            let section: String
            
            if calendar.isDateInToday(entry.date) {
                section = "TODAY"
            } else if calendar.isDateInYesterday(entry.date) {
                section = "YESTERDAY"
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()),
                      entry.date >= weekAgo {
                section = "THIS WEEK"
            } else if let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()),
                      entry.date >= monthAgo {
                section = "THIS MONTH"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                section = formatter.string(from: entry.date).uppercased()
            }
            
            if groups[section] == nil {
                groups[section] = []
            }
            groups[section]?.append(entry)
        }
        
        return groups
    }

    /// Ordered section titles: Today, Yesterday, This Week, This Month, then older groups by name
    private var orderedSections: [String] {
        let priority: [String: Int] = [
            "TODAY": 0,
            "YESTERDAY": 1,
            "THIS WEEK": 2,
            "THIS MONTH": 3
        ]

        return groupedEntries.keys.sorted { lhs, rhs in
            let lp = priority[lhs] ?? 10
            let rp = priority[rhs] ?? 10
            if lp != rp { return lp < rp }
            // For older groups (months/years), keep most recent first
            return lhs > rhs
        }
    }
    
    // MARK: - Filtered Entries
    
    private var filteredEntries: [EmotionEntry] {
        if searchText.isEmpty {
            return entries
        } else {
            return entries.filter { entry in
                // Search in transcription
                if let transcription = entry.cleanedTranscription,
                   transcription.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                // Search in tags
                if let mood = entry.moodCategory,
                   mood.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                if let focus = entry.focusArea,
                   focus.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                return false
            }
        }
    }
}

// MARK: - Journal Entry Row

struct JournalEntryRow: View {
    let entry: EmotionEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Card(padding: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Header with time and duration
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(Color.primaryGreen)
                            .frame(width: 6, height: 6)
                        
                        Text(entry.formattedTime)
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                        
                        Text("•")
                            .foregroundColor(.textSecondary)
                        
                        Text(entry.readingTime)
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                        
                        if entry.voiceRecordingURL != nil {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.primaryGreen)
                        }
                        
                        Spacer()
                        
                        // Chevron
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    
                    // Title (first line of transcription or emotion label)
                    Text(entry.entryTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    // Preview text
                    if let preview = entry.cleanedTranscription {
                        Text(preview)
                            .font(.system(size: 15))
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                    }
                    
                    // Tags
                    HStack(spacing: Spacing.sm) {
                        // Mood category tag
                        if let mood = entry.moodCategory {
                            TagView(text: mood, color: moodColor(for: mood))
                        }
                        
                        // Focus area tag
                        if let focus = entry.focusArea {
                            TagView(text: focus, color: .textSecondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, Layout.screenPadding)
    }
    
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

// MARK: - Tag View

struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(color)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }
}

// MARK: - EmotionEntry Extensions

extension EmotionEntry {
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    var readingTime: String {
        guard let text = cleanedTranscription else { return "1m" }
        let wordCount = text.split(separator: " ").count
        let minutes = max(1, wordCount / 200) // Assuming 200 words per minute
        let seconds = (wordCount % 200) * 60 / 200
        if minutes == 0 && seconds > 0 {
            return "\(seconds)s"
        } else if seconds > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(minutes)m"
        }
    }
    
    var entryTitle: String {
        // Try to get first sentence or use emotion label
        if let text = cleanedTranscription {
            let sentences = text.components(separatedBy: ". ")
            if let first = sentences.first, !first.isEmpty {
                return first
            }
        }
        return Theme.emotionLabel(for: emotionRating)
    }
}
