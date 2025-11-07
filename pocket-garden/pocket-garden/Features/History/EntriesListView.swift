//
//  EntriesListView.swift
//  pocket-garden
//
//  History - List of All Entries
//

import SwiftUI
import SwiftData

struct EntriesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EmotionEntry.date, order: .reverse) private var entries: [EmotionEntry]

    @State private var searchText = ""
    @State private var selectedEntry: EmotionEntry?

    var body: some View {
        ZStack {
            Color.backgroundCream
                .ignoresSafeArea()

            if entries.isEmpty {
                emptyStateView
            } else {
                entriesListView
            }
        }
        .navigationTitle("History")
        .searchable(text: $searchText, prompt: "Search entries...")
        .sheet(item: $selectedEntry) { entry in
            EntryDetailView(entry: entry)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            EmptyStateCard(
                icon: "clock.fill",
                title: "No Entries Yet",
                description: "Your journal entries will appear here as you create them"
            )
        }
        .padding(Layout.screenPadding)
    }

    // MARK: - Entries List

    private var entriesListView: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(filteredEntries) { entry in
                    EmotionEntryCard(entry: entry) {
                        selectedEntry = entry
                    }
                }
            }
            .padding(Layout.screenPadding)
        }
    }

    // MARK: - Filtered Entries

    private var filteredEntries: [EmotionEntry] {
        if searchText.isEmpty {
            return entries
        } else {
            return entries.filter { entry in
                if let transcription = entry.transcription {
                    return transcription.localizedCaseInsensitiveContains(searchText)
                }
                if let tags = entry.tags {
                    return tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
                }
                return false
            }
        }
    }
}

// MARK: - Entry Detail View

struct EntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: EmotionEntry

    var body: some View {
        NavigationStack {
            ZStack {
                Color.peacefulGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xl) {
                        // Header Card
                        headerCard

                        // Transcription
                        if entry.hasTranscription {
                            transcriptionCard
                        }

                        // AI Feedback
                        if entry.hasAIFeedback {
                            aiFeedbackCard
                        }

                        // Tree Info
                        treeInfoCard
                    }
                    .padding(Layout.screenPadding)
                }
            }
            .navigationTitle(entry.formattedDate)
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

    // MARK: - Header Card

    private var headerCard: some View {
        Card {
            VStack(spacing: Spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(entry.dayOfWeek)
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)

                        Text(entry.formattedDate)
                            .font(Typography.title3)
                            .foregroundColor(.textPrimary)
                    }

                    Spacer()

                    Button(action: {
                        entry.toggleFavorite()
                        Theme.Haptics.light()
                    }) {
                        Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 24))
                            .foregroundColor(entry.isFavorite ? .errorRed : .textSecondary)
                    }
                }

                // Emotion Display
                HStack(spacing: Spacing.lg) {
                    Text(Theme.emoji(for: entry.emotionRating))
                        .font(.system(size: 60))

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(Theme.emotionLabel(for: entry.emotionRating))
                            .font(Typography.title2)
                            .foregroundColor(.textPrimary)

                        Text("Rating: \(entry.emotionRating)/10")
                            .font(Typography.callout)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()
                }
                .padding(Spacing.md)
                .background(Color.emotionColor(for: entry.emotionRating).opacity(0.1))
                .cornerRadius(CornerRadius.md)
            }
        }
    }

    // MARK: - Transcription Card

    private var transcriptionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.primaryGreen)

                    Text("Journal Entry")
                        .font(Typography.headline)
                        .foregroundColor(.textPrimary)

                    Spacer()
                }

                Text(entry.transcription ?? "")
                    .font(Typography.body)
                    .foregroundColor(.textPrimary)
            }
        }
    }

    // MARK: - AI Feedback Card

    private var aiFeedbackCard: some View {
        Card(backgroundColor: Color.accentGold.opacity(0.05)) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.accentGold)

                    Text("AI Feedback")
                        .font(Typography.headline)
                        .foregroundColor(.textPrimary)

                    Spacer()
                }

                Text(entry.aiFeedback ?? "")
                    .font(Typography.body)
                    .foregroundColor(.textPrimary)
            }
        }
    }

    // MARK: - Tree Info Card

    private var treeInfoCard: some View {
        Card {
            HStack(spacing: Spacing.lg) {
                Text(TreeStage(rawValue: entry.treeStage)?.emoji ?? "🌱")
                    .font(.system(size: 50))

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(TreeStage(rawValue: entry.treeStage)?.name ?? "Growing")
                        .font(Typography.headline)
                        .foregroundColor(.textPrimary)

                    Text(TreeStage(rawValue: entry.treeStage)?.description ?? "")
                        .font(Typography.callout)
                        .foregroundColor(.textSecondary)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview("Empty List") {
    NavigationStack {
        EntriesListView()
    }
    .modelContainer(for: EmotionEntry.self, inMemory: true)
}

#Preview("List with Entries") {
    let container = try! ModelContainer(
        for: EmotionEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let entries = EmotionEntry.sampleEntries()
    for entry in entries {
        container.mainContext.insert(entry)
    }

    return NavigationStack {
        EntriesListView()
    }
    .modelContainer(container)
}

#Preview("Entry Detail") {
    EntryDetailView(entry: .sample(rating: 9, includeTranscription: true, includeFeedback: true))
        .modelContainer(for: EmotionEntry.self, inMemory: true)
}
