//
//  HomeView.swift
//  pocket-garden
//
//  Home Screen - Daily Check-in
//

import SwiftUI
import SwiftData
import Inject
struct HomeView: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EmotionEntry.date, order: .reverse) private var entries: [EmotionEntry]
    @Query private var allTrees: [GrowingTree]

    @Binding var selectedTab: Int
    @State private var todayRating: Int = 7
    @State private var capturedRating: Int = 7
    @State private var showJournalSheet = false
    @State private var showExperimentalJournalSheet = false
    @State private var hasSubmittedToday = false
    @State private var selectedEntry: EmotionEntry?
    @State private var showMoodRatingSheet = false
    @State private var anotherRating: Int = 7
    @State private var showWeeklyInsightDetail = false
    @State private var openWeeklyInsightWithCalendar = false
    @State private var showMoodTrendChart = false
    
    // Quote of the day
    @State private var dailyQuote: Quote?
    @State private var isLoadingQuote = true
    private let quoteService = QuoteService()

    // Safe Space
    @State private var showSafeSpace = false

    var body: some View {
        ZStack {
            // Background gradient
            Color.peacefulGradient
                .ignoresSafeArea()

            // Vertical-only scrolling to avoid horizontal panning
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    // Header
                    headerSection
                        .padding(.top, Spacing.md)
                    
                    // Quote of the Day
                    quoteOfTheDaySection

                    // Safe Space - Always visible
                    safeSpaceSection

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

                    // Stats Overview
                    statsSection

                    // Weekly Insight (show if user has entries)
                    if !entries.isEmpty {
                        weeklyInsightSection
                    }
                }
                .padding(.horizontal, Layout.screenPadding)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showJournalSheet) {
            VoiceJournalExperimentView(emotionRating: capturedRating, onComplete: {
                // After journal is complete, switch to garden tab
                selectedTab = 1
            })
        }
        // Keep old Apple Speech version as backup (commented out)
        /*
        .sheet(isPresented: $showExperimentalJournalSheet) {
            VoiceJournalView(emotionRating: capturedRating)
        }
        */
        .sheet(isPresented: $showMoodRatingSheet) {
            NavigationStack {
                ZStack {
                    Color.peacefulGradient
                        .ignoresSafeArea()
                    VStack(spacing: Spacing.xl) {
                        VStack(spacing: Spacing.sm) {
                            Text("How are you feeling now?")
                                .font(Typography.title2)
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.center)
                            Text("Rate your emotional wellness")
                                .font(Typography.callout)
                                .foregroundColor(.textSecondary)
                        }
                        EmotionSlider(rating: $anotherRating)
                        PrimaryButton("Continue to Journal", icon: "arrow.right") {
                            capturedRating = anotherRating
                            showMoodRatingSheet = false
                            DispatchQueue.main.async {
                                showJournalSheet = true
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailView(entry: entry)
        }
        .fullScreenCover(isPresented: $showSafeSpace) {
            SafeSpaceView(modelContext: modelContext)
        }
        .sheet(isPresented: $showMoodTrendChart) {
            MoodTrendChartView(entries: entries)
        }
        .onAppear {
            checkTodayEntry()
        }
        .enableInjection()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(greeting)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.textPrimary)

            Text(currentDate)
                .font(Typography.body)
                .foregroundColor(.textSecondary.opacity(0.7))
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
                // Show mood rating first
                showMoodRatingSheet = true
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
                    capturedRating = todayRating
                    showJournalSheet = true
                }
            }
            .padding(.vertical, Spacing.md)
        }
        .slideInFromBottom(delay: 0.1)
    }

    // MARK: - Today Entry Card
    
    /// Get the current growing tree (not fully grown)
    private var currentGrowingTree: GrowingTree? {
        allTrees.first(where: { !$0.isFullyGrown })
    }

    private var todayEntryCard: some View {
        Group {
            if let todayEntry = entries.first(where: { $0.isToday }) {
                let treeInfo = currentTreeGrowthInfo
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
                                Text("Today's Growth")
                                    .font(Typography.caption)
                                    .foregroundColor(.textSecondary)

                                HStack(spacing: Spacing.xs) {
                                    Text(treeInfo.emoji)
                                        .font(.system(size: 24))

                                    Text(treeInfo.title)
                                        .font(Typography.callout)
                                        .foregroundColor(.textPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.9)
                                }

                                Text(growthSummarySubtitle(for: todayEntry.emotionRating))
                                    .font(Typography.caption)
                                    .foregroundColor(.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()
                        }
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.md)
                        .background(Color.backgroundCream.opacity(0.5))
                        .cornerRadius(CornerRadius.sm)

                        // Record another journal for testing or multiple entries per day
                        PrimaryButton("Record Another Journal", icon: "mic.fill") {
                            anotherRating = todayRating
                            showMoodRatingSheet = true
                            Theme.Haptics.light()
                        }
                        .padding(.top, Spacing.sm)
                        
                        // Fallback to Apple Speech (commented out - backup only)
                        /*
                        Button("🔄 Use Apple Speech (Fallback)") {
                            showExperimentalJournalSheet = true
                            Theme.Haptics.light()
                        }
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                        */
                    }
                }
                .slideInFromBottom(delay: 0.1)
            }
        }
    }
    
    /// Get growth info based on current tree's actual watering progress
    private var currentTreeGrowthInfo: (emoji: String, title: String) {
        guard let tree = currentGrowingTree else {
            // No tree yet - first entry plants a seed
            return ("🌱", "New seed planted")
        }
        
        let waterCount = max(tree.waterCount, 0)
        let daysToGrow = max(tree.daysToGrow, 1)
        let treeType = TreeType(rawValue: tree.treeType) ?? .oak
        let stage = tree.growthStage
        let emoji = treeType.emojiForStage(stage)
        let remainingDays = max(daysToGrow - waterCount, 0)

        // Use the normalized growthStage (0–5) so stages line up correctly
        // for different tree lengths: Oak (7 days), Pine (10), Cherry (14).
        switch stage {
        case 0:
            // Just planted (day 1 for any tree type)
            return (emoji, "New seed planted")
        case 1:
            // Very early growth
            return (emoji, "Watering your seedling")
        case 2:
            // Early-middle
            return (emoji, "Your sprout is growing")
        case 3:
            // Middle stage
            return (emoji, "Your young tree is taking root")
        case 4, 5:
            // Late stages depend on remaining days
            if remainingDays == 0 || tree.isFullyGrown {
                return (emoji, "Tree fully grown! 🎉")
            } else if remainingDays <= 2 {
                return (emoji, "Almost fully grown")
            } else {
                return (emoji, "Your tree is growing strong")
            }
        default:
            return (emoji, "Your tree is growing")
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
                .onTapGesture {
                    openWeeklyInsightWithCalendar = true
                    showWeeklyInsightDetail = true
                    Theme.Haptics.light()
                }

                StatCard(
                    value: String(format: "%.1f", averageRating),
                    label: "Avg Mood",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .primaryGreen
                )
                .onTapGesture {
                    showMoodTrendChart = true
                    Theme.Haptics.light()
                }

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
                .onTapGesture {
                    showWeeklyInsightDetail = true
                    Theme.Haptics.light()
                }
        }
        .slideInFromBottom(delay: 0.35)
        .sheet(isPresented: $showWeeklyInsightDetail) {
            WeeklyInsightDetailView(
                entries: entries,
                startWithCalendarExpanded: openWeeklyInsightWithCalendar
            )
            .onDisappear {
                openWeeklyInsightWithCalendar = false
            }
        }
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
                    actionTitle: "Create First Entry",
                    action: {
                        capturedRating = todayRating
                        showJournalSheet = true
                    },
                    showMascot: true
                )
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
            if entries.first(where: {
                calendar.isDate($0.date, inSameDayAs: expectedDate)
            }) != nil {
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
        allTrees.count
    }
    
    private func growthSummarySubtitle(for rating: Int) -> String {
        let avg = averageRating
        guard avg > 0 else {
            return "Every check-in helps your garden grow."
        }
        let diff = Double(rating) - avg
        let formattedAvg = String(format: "%.1f", avg)
        
        if diff >= 1.0 {
            return "Brighter than your recent days (avg \(formattedAvg))."
        } else if diff <= -1.0 {
            return "A bit below your usual (avg \(formattedAvg))—thanks for checking in."
        } else {
            return "About the same as your recent days (avg \(formattedAvg))."
        }
    }

    // MARK: - Helper Methods

    private func checkTodayEntry() {
        hasSubmittedToday = entries.contains { $0.isToday }
    }
    
    // MARK: - Quote of the Day Section
    
    private var quoteOfTheDaySection: some View {
        Group {
            if isLoadingQuote {
                QuoteCardLoading()
            } else if let quote = dailyQuote {
                QuoteCard(quote: quote, isWeekly: false)
            }
        }
        .onAppear {
            loadDailyQuote()
        }
    }
    
    private func loadDailyQuote() {
        Task {
            // Get last 2-3 entries for analysis
            let recentEntries = Array(entries.prefix(3))
            dailyQuote = await quoteService.getDailyQuote(
                recentEntries: recentEntries,
                modelContext: modelContext
            )
            isLoadingQuote = false
        }
    }

    // MARK: - Safe Space Section

    private var safeSpaceSection: some View {
        SafeSpaceCard {
            showSafeSpace = true
        }
        .slideInFromBottom(delay: 0.07)
    }
}

// MARK: - Safe Space Card

struct SafeSpaceCard: View {
    let action: () -> Void
    @State private var isPulsing = false

    var body: some View {
        Button(action: {
            Theme.Haptics.medium()
            action()
        }) {
            HStack(spacing: Spacing.md) {
                // Icon with pulse animation
                ZStack {
                    // Outer pulse circle
                    Circle()
                        .fill(Color.emotionCalm.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .scaleEffect(isPulsing ? 1.3 : 1.0)
                        .opacity(isPulsing ? 0.0 : 1.0)

                    // Inner circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.emotionCalm.opacity(0.8),
                                    Color.primaryGreen.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    // Lotus icon
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Need a Moment?")
                        .font(Typography.headline)
                        .foregroundColor(.textPrimary)

                    Text("Take a breath, find your calm")
                        .font(Typography.callout)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Arrow
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color.emotionCalm)
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cardBackground,
                                Color.emotionCalm.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.emotionCalm.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            startPulseAnimation()
        }
    }

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            isPulsing = true
        }
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
