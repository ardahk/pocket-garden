//
//  HomeView.swift
//  pocket-garden
//
//  Home Screen - Daily Check-in
//

import SwiftUI
import SwiftData
struct HomeView: View {
    @DevObserveInjection var inject: DevInjectionToken
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EmotionEntry.date, order: .reverse) private var entries: [EmotionEntry]
    @Query private var allTrees: [GrowingTree]
    @Query private var achievements: [Achievement]
    
    @ObservedObject private var achievementManager = AchievementManager.shared

    @Binding var selectedTab: Int
    @AppStorage("userFirstName") private var userFirstName = ""
    @AppStorage("hasPromptedForName") private var hasPromptedForName = false
    @State private var showNamePrompt = false
    @State private var enteredNameText = ""
    @State private var todayRating: Int = 7
    @State private var journalRating: JournalRating? = nil  // Use item-based sheet for reliable rating passing
    @State private var showExperimentalJournalSheet = false
    @State private var selectedEntry: EmotionEntry?
    @State private var showMoodRatingSheet = false
    @State private var anotherRating: Int = 7
    @State private var isFirstEntryOfSession = true
    @State private var showWeeklyInsightDetail = false
    @State private var openWeeklyInsightWithCalendar = false
    @State private var showMoodTrendChart = false
    
    // Achievements
    @State private var showAchievementsOverview = false
    
    // Quote of the day
    @State private var dailyQuote: Quote?
    @State private var isLoadingQuote = true
    private let quoteService = QuoteService()

    // Safe Space (moved to tab bar)
    // @State private var showSafeSpace = false
    
    // History (moved from tab bar to home header)
    @State private var showHistory = false

    var body: some View {
        ZStack {
            // Background gradient
            Color.peacefulGradient
                .ignoresSafeArea()

            // Vertical-only scrolling to avoid horizontal panning
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        // Header
                        headerSection
                            .padding(.top, Spacing.xl)
                        
                        // Quote of the Day
                        quoteOfTheDaySection

                        // Safe Space - Moved to tab bar
                        // safeSpaceSection

                        // Daily Challenge / Today summary
                        if !hasEntryToday {
                            dailyChallengeSection
                        } else {
                            todayEntryCard
                        }

                        // Stats & Insights (only show when user has entries)
                        if !entries.isEmpty {
                            statsSection
                            weeklyInsightSection
                        } else {
                            gettingStartedSection
                        }
                    }
                    .padding(.horizontal, Layout.screenPadding)
                    .padding(.bottom, Spacing.xxxl)
                    .frame(width: geometry.size.width)
                }
            }
            
            // Safe area background overlay at the top to cover status bar when scrolling
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.backgroundCream)
                        .frame(height: geo.safeAreaInsets.top)
                    Spacer()
                }
                .ignoresSafeArea()
            }
            .allowsHitTesting(false)
        }
        .navigationBarHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: .triggerJournalFromNotification)) { _ in
            // Trigger the journal flow when coming from forest
            anotherRating = todayRating
            showMoodRatingSheet = true
        }
        .sheet(item: $journalRating) { rating in
            VoiceJournalExperimentView(emotionRating: rating.value, onComplete: {
                // After journal is complete, switch to garden tab
                selectedTab = 1
            })
        }
        .sheet(isPresented: $showMoodRatingSheet) {
            NavigationStack {
                ZStack {
                    Color.peacefulGradient
                        .ignoresSafeArea()
                    VStack(spacing: Spacing.xl) {
                        VStack(spacing: Spacing.sm) {
                            Text(moodPromptTitle)
                                .font(Typography.title2)
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.center)
                            Text("Rate your emotional wellness")
                                .font(Typography.callout)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, Spacing.lg)

                        EmotionSlider(rating: $anotherRating)
                            .padding(.vertical, Spacing.lg)
                        
                        PrimaryButton("Continue to Journal", icon: "arrow.right") {
                            let selectedRating = anotherRating
                            showMoodRatingSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                journalRating = JournalRating(value: selectedRating)
                            }
                        }
                        .padding(.top, Spacing.md)
                        .shadow(color: Color.primaryGreen.opacity(0.3), radius: 15, x: 0, y: 5)
                    }
                    .padding(.horizontal, Layout.screenPadding)
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailViewRedesigned(entry: entry)
        }
        // Safe Space sheet - moved to tab bar
        // .sheet(isPresented: $showSafeSpace) {
        //     SafeSpaceView(modelContext: modelContext)
        //         .presentationDetents([.large])
        //         .presentationDragIndicator(.hidden)
        // }
        .sheet(isPresented: $showHistory) {
            NavigationStack {
                EntriesListViewRedesigned()
            }
        }
        .sheet(isPresented: $showMoodTrendChart) {
            MoodTrendChartView(entries: entries)
        }
        .sheet(isPresented: $showAchievementsOverview) {
            AchievementsOverviewView()
        }
        .sheet(isPresented: $showNamePrompt) {
            NamePromptSheet(enteredName: $enteredNameText) { savedName in
                userFirstName = savedName
                hasPromptedForName = true
                showNamePrompt = false
            } onSkip: {
                hasPromptedForName = true
                showNamePrompt = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if userFirstName.isEmpty && !hasPromptedForName {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showNamePrompt = true
                }
            }
        }
        .devEnableInjection()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(greeting)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text(currentDate)
                    .font(Typography.body)
                    .foregroundColor(.textSecondary.opacity(0.7))
            }
            
            Spacer()
            
            // History button
            Button(action: {
                showHistory = true
                Theme.Haptics.light()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.cardBackground)
                        .frame(width: 42, height: 42)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
                    
                    Image(systemName: "clock.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondaryTerracotta)
                }
            }
            .buttonStyle(.plain)
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
                hasCompletedToday: hasEntryToday
            ) {
                // Always route through mood rating before journaling
                // isFirstEntryOfSession stays true until first journal is completed
                anotherRating = todayRating
                showMoodRatingSheet = true
            }
        }
        .slideInFromBottom(delay: 0.05)
    }

    // (Daily rating card removed – mood rating now appears only when starting journaling)

    // MARK: - Today Entry Card
    
    /// Get the current growing tree (not fully grown)
    private var currentGrowingTree: GrowingTree? {
        allTrees.first(where: { !$0.isFullyGrown })
    }

    private var todayEntryCard: some View {
        Group {
            if let todayEntry = entries.first(where: { $0.isToday }) {
                let treeInfo = currentTreeGrowthInfo
                let entryCount = todayEntryCount
                Card {
                    VStack(spacing: Spacing.lg) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.successGreen)

                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Entry Saved")
                                    .font(Typography.headline)
                                    .foregroundColor(.textPrimary)

                                Text("Great job checking in!")
                                    .font(Typography.callout)
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()
                            
                            // Entry count badge
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                
                                Text("\(entryCount)")
                                    .font(.system(size: 13, weight: .semibold))
                                
                                Text(entryCount == 1 ? "entry" : "entries")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.primaryGreen, Color.primaryGreen.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color.primaryGreen.opacity(0.3), radius: 4, y: 2)
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

                                HStack(alignment: .top, spacing: Spacing.xs) {
                                    Text(treeInfo.emoji)
                                        .font(.system(size: 24))

                                    Text(treeInfo.title)
                                        .font(Typography.callout)
                                        .foregroundColor(.textPrimary)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.md)
                        .background(Color.backgroundCream.opacity(0.5))
                        .cornerRadius(CornerRadius.sm)

                        // Encouraging microcopy
                        Text("Multiple entries help track your day better")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.top, Spacing.xs)

                        // Enhanced button with pulse animation
                        AddAnotherEntryButton {
                            isFirstEntryOfSession = false
                            anotherRating = todayRating
                            showMoodRatingSheet = true
                            Theme.Haptics.light()
                        }
                        .padding(.top, Spacing.sm)
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
                    showHistory = true // Open history sheet
                    Theme.Haptics.light()
                }
            }
        }
        .slideInFromBottom(delay: 0.2)
    }

    // MARK: - Getting Started (Empty State)
    
    private var gettingStartedSection: some View {
        VStack(spacing: Spacing.lg) {
            // Why journaling matters card
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Text("🌱")
                        .font(.system(size: 22))
                    Text("Why Daily Check-ins Matter")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    benefitRow(icon: "brain.head.profile", text: "Builds emotional self-awareness over time")
                    benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Helps you spot patterns in how you feel")
                    benefitRow(icon: "leaf.fill", text: "Grows your personal garden as you reflect")
                    benefitRow(icon: "heart.fill", text: "Just 1 minute a day can improve wellbeing")
                }
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            )
            
            // Encouragement
            HStack(spacing: Spacing.sm) {
                Text("🐝")
                    .font(.system(size: 16))
                Text("Your progress and weekly insights will appear here after your first entry!")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, Spacing.sm)
        }
        .slideInFromBottom(delay: 0.3)
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primaryGreen)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
        }
    }
    
    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your Progress")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            // Use screen width to compute a consistent, equal-sized 3-up layout.
            // This avoids any GeometryReader sizing quirks that can make the middle card
            // *appear* smaller on some devices.
            let availableWidth = UIScreen.main.bounds.width - (Layout.screenPadding * 2)
            let cardWidth = max(0, (availableWidth - (Spacing.md * 2)) / 3)
            let cardHeight = cardWidth * 1.15

            HStack(spacing: Spacing.md) {
                StatCard(
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    icon: "flame.fill",
                    color: .accentGold
                )
                .frame(width: cardWidth, height: cardHeight)
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
                .frame(width: cardWidth, height: cardHeight)
                .onTapGesture {
                    showMoodTrendChart = true
                    Theme.Haptics.light()
                }

                ZStack(alignment: .topTrailing) {
                    StatCard(
                        value: "\(unlockedAchievementCount)",
                        label: "Badges",
                        icon: "trophy.fill",
                        color: .secondaryTerracotta
                    )
                    .frame(width: cardWidth, height: cardHeight)

                    if achievementManager.hasUnseenUnlock {
                        Circle()
                            .fill(Color.secondaryTerracotta)
                            .frame(width: 10, height: 10)
                            .offset(x: -4, y: 4)
                    }
                }
                .onTapGesture {
                    showAchievementsOverview = true
                    achievementManager.markAchievementsAsSeen()
                    Theme.Haptics.light()
                }
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
                    showHistory = true // Open history sheet
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
                        // First entry goes through mood rating sheet as well
                        // isFirstEntryOfSession stays true until first journal is completed
                        anotherRating = todayRating
                        showMoodRatingSheet = true
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
        let today = Date()
        
        // Check if there's an entry today
        let hasEntryToday = entries.contains { calendar.isDate($0.date, inSameDayAs: today) }
        
        // If no entry today, start checking from yesterday to show existing streak
        let startDay = hasEntryToday ? 0 : 1
        
        // Check enough days to cover all possible streak days
        let maxDaysToCheck = entries.count + 1
        
        for i in startDay..<maxDaysToCheck {
            let expectedDate = calendar.date(byAdding: .day, value: -i, to: today)!
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
    
    private var unlockedAchievementCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    private var moodPromptTitle: String {
        isFirstEntryOfSession ? "How are you feeling today?" : "How are you feeling now?"
    }
    
    /// Computed property that directly checks entries for today
    private var hasEntryToday: Bool {
        entries.contains { $0.isToday }
    }
    
    /// Count of entries made today
    private var todayEntryCount: Int {
        let calendar = Calendar.current
        let today = Date()
        return entries.filter { calendar.isDate($0.date, inSameDayAs: today) }.count
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

    // Safe Space section - moved to tab bar (kept for reference)
    // private var safeSpaceSection: some View {
    //     SafeSpaceCard {
    //         showSafeSpace = true
    //     }
    //     .slideInFromBottom(delay: 0.07)
    // }
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
                // Icon with pulse animation and soft glow
                ZStack {
                    // Soft glow around icon
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.emotionCalm.opacity(0.4),
                                    Color.emotionCalm.opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 45
                            )
                        )
                        .frame(width: 90, height: 90)
                    
                    // Outer pulse circle
                    Circle()
                        .fill(Color.emotionCalm.opacity(0.3))
                        .frame(width: 64, height: 64)
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
                        .frame(width: 60, height: 60)

                    // Moon/stars icon - increased size
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }

                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Sanctuary")
                        .font(Typography.headline)
                        .foregroundColor(.textPrimary)

                    Text("Take a breath, find your calm")
                        .font(Typography.callout)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Arrow
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 33))
                    .foregroundColor(Color.emotionCalm)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
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
                    .overlay(
                        SubtlePatternView()
                            .opacity(0.03)
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

// MARK: - Name Prompt Sheet

/// Friendly sheet shown to existing users who haven't provided their name yet.
struct NamePromptSheet: View {
    @Binding var enteredName: String
    let onSave: (String) -> Void
    let onSkip: () -> Void

    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image("panda_supportive")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)

            VStack(spacing: Spacing.md) {
                Text("Hey there!")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text("Bumblebee here! I'd love to know your name so I can make my feedback feel more personal.")
                    .font(Typography.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Spacing.lg)
            }

            TextField("Your first name", text: $enteredName)
                .font(.system(size: 18))
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.primaryGreen.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, Spacing.xl)
                .focused($isNameFieldFocused)

            VStack(spacing: Spacing.md) {
                PrimaryButton("Save", icon: "checkmark") {
                    let trimmed = enteredName
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: .whitespacesAndNewlines)
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                    guard !trimmed.isEmpty else { return }
                    Theme.Haptics.success()
                    onSave(trimmed)
                }
                .opacity(enteredName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1.0)
                .disabled(enteredName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, Spacing.xl)

                Button("Maybe Later") {
                    onSkip()
                }
                .font(Typography.callout)
                .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, Spacing.xl)
        .background(Color.backgroundCream.ignoresSafeArea())
        .onAppear {
            isNameFieldFocused = true
        }
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

// MARK: - Add Another Entry Button (Enhanced with Pulse Animation)

struct AddAnotherEntryButton: View {
    let action: () -> Void
    @State private var pulseScale: CGFloat = 1.0
    @State private var shadowOpacity: Double = 0.3
    
    var body: some View {
        Button(action: {
            Theme.Haptics.medium()
            action()
        }) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Add Another Entry")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56) // Standard button height
            .background(
                ZStack {
                    // Base gradient
                    LinearGradient(
                        colors: [Color.primaryGreen, Color.primaryGreen.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Pulsing glow overlay
                    LinearGradient(
                        colors: [
                            Color.white.opacity(shadowOpacity * 0.2),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(CornerRadius.md)
            .shadow(
                color: Color.primaryGreen.opacity(shadowOpacity),
                radius: 12 * pulseScale,
                y: 6
            )
            .scaleEffect(pulseScale)
        }
        .buttonStyle(.plain)
        .onAppear {
            // Slower, more subtle pulse animation
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.015
                shadowOpacity = 0.4
            }
        }
    }
}

// MARK: - Subtle Pattern View (for background texture)

struct SubtlePatternView: View {
    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 20
            let dotSize: CGFloat = 2
            
            ZStack {
                // Create a subtle dot pattern
                ForEach(0..<Int(geometry.size.width / spacing), id: \.self) { x in
                    ForEach(0..<Int(geometry.size.height / spacing), id: \.self) { y in
                        Circle()
                            .fill(Color.emotionCalm)
                            .frame(width: dotSize, height: dotSize)
                            .position(
                                x: CGFloat(x) * spacing + spacing / 2,
                                y: CGFloat(y) * spacing + spacing / 2
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Journal Rating Wrapper (for reliable sheet presentation)

struct JournalRating: Identifiable {
    let id = UUID()
    let value: Int
}
