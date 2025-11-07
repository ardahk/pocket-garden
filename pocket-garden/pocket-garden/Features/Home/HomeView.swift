//
//  HomeView.swift
//  pocket-garden
//
//  Home Screen - Daily Check-in
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EmotionEntry.date, order: .reverse) private var entries: [EmotionEntry]

    @Binding var selectedTab: Int
    @State private var todayRating: Int = 7
    @State private var showJournalSheet = false
    @State private var hasSubmittedToday = false
    @State private var selectedEntry: EmotionEntry?

    var body: some View {
        ZStack {
            // Background gradient
            Color.peacefulGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    headerSection
                        .padding(.top, Spacing.md)

                    // Daily Challenge Card
                    if !hasSubmittedToday {
                        dailyChallengeSection
                    }

                    // Daily Rating Card
                    if !hasSubmittedToday {
                        dailyRatingCard
                    } else {
                        todayEntryCard
                    }

                    // Quick Actions
                    quickActionsSection

                    // Stats Overview
                    statsSection

                    // Weekly Insight (show if user has entries)
                    if !entries.isEmpty {
                        weeklyInsightSection
                    }

                    // Recent Entries Preview
                    recentEntriesSection
                }
                .padding(.horizontal, Layout.screenPadding)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showJournalSheet) {
            VoiceJournalView(emotionRating: todayRating)
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailView(entry: entry)
        }
        .onAppear {
            checkTodayEntry()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(greeting)
                .font(Typography.title)
                .foregroundColor(.textPrimary)

            Text(currentDate)
                .font(Typography.callout)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fadeIn()
    }

    // MARK: - Daily Challenge Section

    private var dailyChallengeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Daily Challenge")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            DailyChallengeCard(
                challenge: DailyChallenge.todaysChallenge(),
                hasCompletedToday: hasSubmittedToday
            ) {
                showJournalSheet = true
            }
        }
        .slideInFromBottom(delay: 0.05)
    }

    // MARK: - Daily Rating Card

    private var dailyRatingCard: some View {
        Card {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.sm) {
                    Text("How are you feeling today?")
                        .font(Typography.title2)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Rate your emotional wellness")
                        .font(Typography.callout)
                        .foregroundColor(.textSecondary)
                }

                EmotionSlider(rating: $todayRating)

                PrimaryButton("Continue to Journal", icon: "arrow.right") {
                    showJournalSheet = true
                }
            }
            .padding(.vertical, Spacing.md)
        }
        .slideInFromBottom(delay: 0.1)
    }

    // MARK: - Today Entry Card

    private var todayEntryCard: some View {
        Group {
            if let todayEntry = entries.first(where: { $0.isToday }) {
                Card {
                    VStack(spacing: Spacing.lg) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.successGreen)

                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Today's Entry Complete")
                                    .font(Typography.headline)
                                    .foregroundColor(.textPrimary)

                                Text("Great job checking in!")
                                    .font(Typography.callout)
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()
                        }

                        HStack(spacing: Spacing.lg) {
                            VStack(spacing: Spacing.xs) {
                                Text(Theme.emoji(for: todayEntry.emotionRating))
                                    .font(.system(size: 40))

                                Text("\(todayEntry.emotionRating)/10")
                                    .font(Typography.caption)
                                    .foregroundColor(.textSecondary)
                            }

                            Divider()
                                .frame(height: 60)

                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(TreeStage(rawValue: todayEntry.treeStage)?.emoji ?? "🌱")
                                    .font(.system(size: 32))

                                Text(TreeStage(rawValue: todayEntry.treeStage)?.name ?? "Growing")
                                    .font(Typography.caption)
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.md)
                        .background(Color.backgroundCream.opacity(0.5))
                        .cornerRadius(CornerRadius.sm)
                    }
                }
                .slideInFromBottom(delay: 0.1)
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quick Actions")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: Spacing.md) {
                QuickActionButton(
                    icon: "leaf.fill",
                    title: "View Garden",
                    color: .primaryGreen
                ) {
                    selectedTab = 1 // Switch to garden tab
                    Theme.Haptics.light()
                }

                QuickActionButton(
                    icon: "book.fill",
                    title: "Past Entries",
                    color: .secondaryTerracotta
                ) {
                    selectedTab = 2 // Switch to history tab
                    Theme.Haptics.light()
                }
            }
        }
        .slideInFromBottom(delay: 0.2)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your Progress")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            HStack(spacing: Spacing.md) {
                StatCard(
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    icon: "flame.fill",
                    color: .accentGold
                )

                StatCard(
                    value: String(format: "%.1f", averageRating),
                    label: "Avg Rating",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .primaryGreen
                )

                StatCard(
                    value: "\(totalTrees)",
                    label: "Trees",
                    icon: "leaf.fill",
                    color: .emotionContent
                )
            }
        }
        .slideInFromBottom(delay: 0.3)
    }

    // MARK: - Weekly Insight Section

    private var weeklyInsightSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            WeeklyInsightCard(insight: WeeklyInsight.generate(from: entries))
        }
        .slideInFromBottom(delay: 0.35)
    }

    // MARK: - Recent Entries

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Recent Entries")
                    .font(Typography.headline)
                    .foregroundColor(.textPrimary)

                Spacer()

                Button("View All") {
                    selectedTab = 2 // Switch to history tab
                    Theme.Haptics.light()
                }
                .font(Typography.callout)
                .foregroundColor(.primaryGreen)
            }

            if entries.isEmpty {
                EmptyStateCard(
                    icon: "leaf.fill",
                    title: "No Entries Yet",
                    description: "Start your emotional wellness journey today",
                    actionTitle: "Create First Entry"
                ) {
                    showJournalSheet = true
                }
            } else {
                ForEach(entries.prefix(3)) { entry in
                    EmotionEntryCard(entry: entry) {
                        selectedEntry = entry
                        Theme.Haptics.light()
                    }
                }
            }
        }
        .slideInFromBottom(delay: 0.4)
    }

    // MARK: - Helper Properties

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current

        for i in 0..<entries.count {
            let expectedDate = calendar.date(byAdding: .day, value: -i, to: Date())!
            if let entry = entries.first(where: {
                calendar.isDate($0.date, inSameDayAs: expectedDate)
            }) {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    private var averageRating: Double {
        guard !entries.isEmpty else { return 0.0 }
        let sum = entries.reduce(0) { $0 + $1.emotionRating }
        return Double(sum) / Double(entries.count)
    }

    private var totalTrees: Int {
        entries.count
    }

    // MARK: - Helper Methods

    private func checkTodayEntry() {
        hasSubmittedToday = entries.contains { $0.isToday }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            action()
        }) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)

                Text(title)
                    .font(Typography.callout)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.1), color.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(CornerRadius.md)
            .cardShadow()
        }
        .pressAnimation()
    }
}

// MARK: - Preview

#Preview("Home View") {
    @Previewable @State var selectedTab = 0

    NavigationStack {
        HomeView(selectedTab: $selectedTab)
    }
    .modelContainer(for: EmotionEntry.self, inMemory: true)
}

#Preview("Home View with Entries") {
    @Previewable @State var selectedTab = 0

    let container = try! ModelContainer(
        for: EmotionEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    // Add sample entries
    let entries = EmotionEntry.sampleEntries()
    for entry in entries {
        container.mainContext.insert(entry)
    }

    return NavigationStack {
        HomeView(selectedTab: $selectedTab)
    }
    .modelContainer(container)
}
