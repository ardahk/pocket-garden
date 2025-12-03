//
//  WeeklyInsightDetailView.swift
//  pocket-garden
//
//  Weekly Insight Detail with Panda Motivation
//

import SwiftUI
import SwiftData

struct WeeklyInsightDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let entries: [EmotionEntry]
    var startWithCalendarExpanded: Bool = false
    
    @State private var weeklyQuote: Quote?
    @State private var isLoadingQuote = true
    private let quoteService = QuoteService()

    @State private var weeklyPandaMessage: String?
    @State private var isLoadingPandaMessage = false
    
    // Calendar state
    @State private var isCalendarExpanded = false
    @State private var selectedMonth = Date()
    
    // Navigation to entry detail
    @State private var selectedDateForEntry: Date?
    @State private var showEntryDetail = false
    
    private var weeklyInsight: WeeklyInsight {
        WeeklyInsight.generate(from: entries)
    }
    
    private var thisWeekEntries: [EmotionEntry] {
        let calendar = Calendar.current
        // Use the calendar's current week interval (e.g. Monday–Sunday) and
        // only include entries from the start of this week up to today.
        let today = Date()
        if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) {
            let startOfWeek = weekInterval.start
            return entries.filter { $0.date >= startOfWeek && $0.date <= today }
        } else {
            return entries
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peacefulGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Activity Calendar (replaces panda section)
                        activityCalendarSection
                        
                        // Quote of the Week
                        weeklyQuoteSection
                        
                        // Weekly stats overview
                        weeklyStatsSection
                        
                        // Detailed insights
                        insightsSection
                        
                        // Panda's personalized motivation for the week
                        motivationSection
                    }
                    .padding(.horizontal, Layout.screenPadding)
                    .padding(.bottom, Spacing.xxxl)
                }
            }
            .navigationTitle("Weekly Insight")
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
    
    // MARK: - Activity Calendar Section
    
    private var activityCalendarSection: some View {
        ActivityCalendarView(
            entries: entries,
            isExpanded: $isCalendarExpanded,
            selectedMonth: $selectedMonth,
            onDateTapped: { date in
                selectedDateForEntry = date
                showEntryDetail = true
            }
        )
        .fadeIn()
        .onAppear {
            if startWithCalendarExpanded {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3)) {
                    isCalendarExpanded = true
                }
            }
        }
        .sheet(isPresented: $showEntryDetail) {
            if let date = selectedDateForEntry {
                EntryDetailSheet(entries: entries, date: date)
            }
        }
    }
    
    // MARK: - Weekly Stats Section
    
    private var weeklyStatsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("This Week's Progress")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: Spacing.md) {
                StatCard(
                    value: "\(thisWeekEntries.count)",
                    label: "Check-ins",
                    icon: "checkmark.circle.fill",
                    color: .primaryGreen
                )
                
                StatCard(
                    value: String(format: "%.1f", weeklyAverageRating),
                    label: "Avg Rating",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .emotionContent
                )
                
                StatCard(
                    value: "\(consecutiveDays)",
                    label: "Days Active",
                    icon: "flame.fill",
                    color: .accentGold
                )
            }
        }
        .slideInFromBottom(delay: 0.1)
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Key Insights")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)
            
            Card {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    InsightRow(
                        icon: "chart.bar.fill",
                        title: "Emotional Trend",
                        value: trendText,
                        color: trendColor
                    )
                    
                    Divider()
                    
                    InsightRow(
                        icon: "face.smiling.fill",
                        title: "Most Common Mood",
                        value: mostCommonMood,
                        color: .emotionContent
                    )
                    
                    Divider()
                    
                    InsightRow(
                        icon: "calendar.badge.clock",
                        title: "Best Time",
                        value: bestTimeOfDay,
                        color: .accentGold
                    )
                }
            }
        }
        .slideInFromBottom(delay: 0.2)
    }
    
    // MARK: - Motivation Section
    
    private var motivationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Panda's message for your week so far")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)
            
            Card {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        GardenMascot(emotion: .supportive, size: 50)
                        
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            if isLoadingPandaMessage {
                                HStack(spacing: Spacing.sm) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Panda is reflecting on your week...")
                                        .font(Typography.body)
                                        .foregroundColor(.textSecondary)
                                }
                            } else {
                                Text(weeklyPandaMessage ?? pandaMotivation)
                                    .font(Typography.body)
                                    .foregroundColor(.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(pandaActionItem)
                                    .font(Typography.callout)
                                    .foregroundColor(.primaryGreen)
                                    .padding(.top, Spacing.xs)
                            }
                        }
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
        }
        .slideInFromBottom(delay: 0.3)
        .task {
            await loadWeeklyPandaMessage()
        }
    }
    
    // MARK: - Entries Section
    
    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("This Week's Entries")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)
            
            if thisWeekEntries.isEmpty {
                Card {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.textSecondary.opacity(0.5))
                        
                        Text("No entries this week yet")
                            .font(Typography.body)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.vertical, Spacing.lg)
                }
            } else {
                ForEach(thisWeekEntries) { entry in
                    WeeklyEntryRow(entry: entry)
                }
            }
        }
        .slideInFromBottom(delay: 0.4)
    }
    
    // MARK: - Computed Properties
    
    private var pandaEmotion: MascotEmotion {
        let avgRating = weeklyAverageRating
        if avgRating >= 8 { return .proud }
        if avgRating >= 6 { return .happy }
        if avgRating >= 4 { return .supportive }
        return .concerned
    }
    
    private var pandaGreeting: String {
        let avgRating = weeklyAverageRating
        if avgRating >= 8 { return "Amazing week! 🌟" }
        if avgRating >= 6 { return "Great progress! 💚" }
        if avgRating >= 4 { return "You're doing well!" }
        return "I'm here with you 🤗"
    }
    
    private var pandaSubtitle: String {
        if thisWeekEntries.count >= 5 {
            return "You've been so consistent this week!"
        } else if thisWeekEntries.count >= 3 {
            return "Nice momentum building!"
        } else if thisWeekEntries.count >= 1 {
            return "Every check-in matters!"
        } else {
            return "Let's start fresh this week!"
        }
    }
    
    private var pandaMotivation: String {
        let avgRating = weeklyAverageRating
        let count = thisWeekEntries.count
        
        if count == 0 {
            return "This week is a blank canvas! Each day is a chance to check in with yourself and grow. I believe in your journey. 🌱"
        }
        
        if avgRating >= 8 {
            return "Your energy this week has been incredible! You're finding what works for you and it shows. Keep nurturing these positive patterns—they're helping you flourish. 🌟"
        } else if avgRating >= 6 {
            return "You're building something beautiful this week. There's a steady rhythm to your growth, and I can see you're learning what supports your wellbeing. Trust the process! 💚"
        } else if avgRating >= 4 {
            return "This week has had its challenges, but you're still showing up. That takes real courage. Remember, growth isn't always linear—every step counts, even the small ones. 🌿"
        } else {
            return "I see you're going through a tough time. Thank you for trusting me with your feelings. You're not alone in this, and it's okay to have difficult weeks. Tomorrow brings new possibilities. 🤗"
        }
    }
    
    private var pandaActionItem: String {
        let avgRating = weeklyAverageRating
        
        if avgRating >= 8 {
            return "💡 Keep it up: Note what's working and do more of it!"
        } else if avgRating >= 6 {
            return "💡 Next step: Try one new self-care practice this week"
        } else if avgRating >= 4 {
            return "💡 Gentle reminder: Small wins matter—celebrate them!"
        } else {
            return "💡 Be kind to yourself: One breath at a time is enough"
        }
    }
    
    private var weeklyAverageRating: Double {
        guard !thisWeekEntries.isEmpty else { return 0 }
        let sum = thisWeekEntries.reduce(0) { $0 + $1.emotionRating }
        return Double(sum) / Double(thisWeekEntries.count)
    }
    
    private var consecutiveDays: Int {
        let calendar = Calendar.current
        var days = Set<Date>()
        
        for entry in thisWeekEntries {
            let day = calendar.startOfDay(for: entry.date)
            days.insert(day)
        }
        
        return days.count
    }
    
    private var trendText: String {
        switch weeklyInsight.moodTrend {
        case .improving:
            return "Improving 📈"
        case .stable:
            return "Stable ➡️"
        case .declining:
            return "Challenging 📉"
        }
    }
    
    private var trendColor: Color {
        weeklyInsight.moodTrend.color
    }
    
    private var mostCommonMood: String {
        guard !thisWeekEntries.isEmpty else { return "N/A" }
        
        let avgRating = weeklyAverageRating
        if avgRating >= 8 { return "Joyful 😊" }
        if avgRating >= 6 { return "Content 😌" }
        if avgRating >= 4 { return "Okay 😐" }
        return "Struggling 😔"
    }
    
    private var bestTimeOfDay: String {
        guard !thisWeekEntries.isEmpty else { return "N/A" }
        
        let calendar = Calendar.current
        let hours = thisWeekEntries.map { calendar.component(.hour, from: $0.date) }
        
        let morningCount = hours.filter { $0 < 12 }.count
        let afternoonCount = hours.filter { $0 >= 12 && $0 < 17 }.count
        let eveningCount = hours.filter { $0 >= 17 }.count
        
        let max = Swift.max(morningCount, afternoonCount, eveningCount)
        if max == morningCount { return "Morning 🌅" }
        if max == afternoonCount { return "Afternoon ☀️" }
        return "Evening 🌙"
    }
    
    // MARK: - Weekly Quote Section
    
    private var weeklyQuoteSection: some View {
        Group {
            if isLoadingQuote {
                QuoteCardLoading()
            } else if let quote = weeklyQuote {
                QuoteCard(quote: quote, isWeekly: true)
            }
        }
        .onAppear {
            loadWeeklyQuote()
        }
    }
    
    private func loadWeeklyQuote() {
        Task {
            weeklyQuote = await quoteService.getWeeklyQuote(
                weekEntries: thisWeekEntries,
                modelContext: modelContext
            )
            isLoadingQuote = false
        }
    }

    // MARK: - Weekly Panda Message

    private func loadWeeklyPandaMessage() async {
        guard !isLoadingPandaMessage else { return }
        isLoadingPandaMessage = true

        let entriesForWeek = thisWeekEntries
        let result = await PandaWeeklyFeedbackService.shared.generate(for: entriesForWeek)

        await MainActor.run {
            weeklyPandaMessage = result.text
            isLoadingPandaMessage = false
        }
    }
}

// MARK: - Supporting Views

struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)
                
                Text(value)
                    .font(Typography.body)
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
        }
    }
}

struct WeeklyEntryRow: View {
    let entry: EmotionEntry
    
    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: entry.date)
    }
    
    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: entry.date)
    }
    
    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                // Emoji
                Text(Theme.emoji(for: entry.emotionRating))
                    .font(.system(size: 32))
                
                // Day and time
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(dayLabel)
                        .font(Typography.body)
                        .foregroundColor(.textPrimary)
                    
                    Text(timeLabel)
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Rating
                VStack(spacing: Spacing.xs) {
                    Text("\(entry.emotionRating)")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primaryGreen)
                    
                    Text("/ 10")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}

// MARK: - Activity Calendar View

struct ActivityCalendarView: View {
    let entries: [EmotionEntry]
    @Binding var isExpanded: Bool
    @Binding var selectedMonth: Date
    var onDateTapped: ((Date) -> Void)? = nil
    
    @State private var animateFlames = false
    @State private var currentWeekDates: [Date] = []
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    // Flame gradient colors
    private let flameGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.6, blue: 0.2),  // Warm orange
            Color(red: 1.0, green: 0.4, blue: 0.1),  // Deep orange
            Color(red: 0.95, green: 0.3, blue: 0.1)  // Red-orange
        ],
        startPoint: .bottom,
        endPoint: .top
    )
    
    private let emptyDayColor = Color.gray.opacity(0.15)
    
    var body: some View {
        Card {
            VStack(spacing: 0) {
                // Blended header - shows week when collapsed, month nav when expanded
                if isExpanded {
                    // Full calendar mode - no week preview, just month view
                    fullCalendarSection
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    // Collapsed mode - show week preview
                    headerSection
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .padding(Spacing.lg)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isExpanded)
        }
        .onAppear {
            setupCurrentWeek()
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateFlames = true
            }
        }
    }
    
    // MARK: - Header Section (Current Week)
    
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // Title row with expand button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text(currentWeekLabel)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }
                
                Spacer()
                
                // Streak indicator
                if currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(flameGradient)
                            .scaleEffect(animateFlames ? 1.1 : 1.0)
                        
                        Text("\(currentStreak)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.accentGold.opacity(0.15))
                    )
                }
                
                // Expand/collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                    Theme.Haptics.light()
                }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.primaryGreen.opacity(0.8))
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
            }
            
            // Current week days
            HStack(spacing: 8) {
                ForEach(Array(currentWeekDates.enumerated()), id: \.offset) { index, date in
                    currentWeekDayView(date: date, dayIndex: index)
                }
            }
        }
    }
    
    private func currentWeekDayView(date: Date, dayIndex: Int) -> some View {
        let hasEntry = hasEntryOn(date: date)
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date()
        
        return Button(action: {
            if hasEntry {
                onDateTapped?(date)
                Theme.Haptics.light()
            }
        }) {
            VStack(spacing: 6) {
                // Day letter
                Text(daysOfWeek[dayIndex])
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                // Day circle with flame effect
                ZStack {
                    // Base circle
                    Circle()
                        .fill(hasEntry ? Color.clear : emptyDayColor)
                        .frame(width: 36, height: 36)
                    
                    if hasEntry {
                        // Flame ring effect
                        FlameRingView(isAnimating: animateFlames)
                            .frame(width: 36, height: 36)
                        
                        // Inner glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.accentGold.opacity(0.4),
                                        Color.accentGold.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 18
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        // Fire emoji or checkmark
                        Text("🔥")
                            .font(.system(size: 16))
                            .scaleEffect(animateFlames ? 1.05 : 0.95)
                    }
                    
                    // Today indicator ring
                    if isToday {
                        Circle()
                            .stroke(Color.primaryGreen, lineWidth: 2)
                            .frame(width: 38, height: 38)
                    }
                }
                .opacity(isFuture ? 0.4 : 1.0)
                
                // Date number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 12, weight: isToday ? .bold : .regular))
                    .foregroundColor(isToday ? .primaryGreen : .textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .disabled(!hasEntry)
    }
    
    // MARK: - Full Calendar Section
    
    private var fullCalendarSection: some View {
        VStack(spacing: Spacing.md) {
            // Month navigation with collapse button
            HStack {
                Button(action: { navigateMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryGreen)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.primaryGreen.opacity(0.1)))
                }
                
                Spacer()
                
                Text(monthYearLabel)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button(action: { navigateMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(canNavigateForward ? .primaryGreen : .textSecondary.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(canNavigateForward ? Color.primaryGreen.opacity(0.1) : Color.clear))
                }
                .disabled(!canNavigateForward)
                
                // Collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                    Theme.Haptics.light()
                }) {
                    Image(systemName: "chevron.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.primaryGreen.opacity(0.8))
                }
                .padding(.leading, 8)
            }
            
            // Day headers
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        calendarDayView(date: date)
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            
            // Monthly summary
            monthlySummary
        }
    }
    
    private func calendarDayView(date: Date) -> some View {
        let hasEntry = hasEntryOn(date: date)
        let isToday = calendar.isDateInToday(date)
        let isCurrentMonth = calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)
        let isFuture = date > Date()
        
        return Button(action: {
            if hasEntry {
                onDateTapped?(date)
                Theme.Haptics.light()
            }
        }) {
            ZStack {
                // Background
                if hasEntry {
                    // Flame effect for days with entries
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.accentGold.opacity(0.5),
                                    Color.orange.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .scaleEffect(animateFlames ? 1.1 : 1.0)
                    
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.orange, Color.accentGold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
                
                // Today ring
                if isToday {
                    Circle()
                        .stroke(Color.primaryGreen, lineWidth: 2.5)
                }
                
                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: hasEntry || isToday ? .semibold : .regular))
                    .foregroundColor(
                        !isCurrentMonth ? .textSecondary.opacity(0.3) :
                        isFuture ? .textSecondary.opacity(0.5) :
                        hasEntry ? .textPrimary :
                        isToday ? .primaryGreen :
                        .textSecondary
                    )
            }
            .frame(height: 40)
        }
        .buttonStyle(.plain)
        .disabled(!hasEntry)
    }
    
    private var monthlySummary: some View {
        let monthEntries = entriesInMonth(selectedMonth)
        let activeDays = Set(monthEntries.map { calendar.startOfDay(for: $0.date) }).count
        let totalDays = daysPassedInMonth(selectedMonth)
        
        return HStack(spacing: Spacing.lg) {
            VStack(spacing: 4) {
                Text("\(monthEntries.count)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primaryGreen)
                Text("Check-ins")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }
            
            Divider()
                .frame(height: 30)
            
            VStack(spacing: 4) {
                Text("\(activeDays)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(flameGradient)
                Text("Active Days")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }
            
            Divider()
                .frame(height: 30)
            
            VStack(spacing: 4) {
                Text(totalDays > 0 ? "\(Int(Double(activeDays) / Double(totalDays) * 100))%" : "—")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.accentGold)
                Text("Consistency")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.top, Spacing.sm)
    }
    
    // MARK: - Helper Functions
    
    private func setupCurrentWeek() {
        let today = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else { return }
        
        var dates: [Date] = []
        var current = weekInterval.start
        
        while current < weekInterval.end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        
        currentWeekDates = dates
    }
    
    private var currentWeekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        guard let first = currentWeekDates.first, let last = currentWeekDates.last else {
            return "This Week"
        }
        
        return "\(formatter.string(from: first)) – \(formatter.string(from: last))"
    }
    
    private var monthYearLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    private var currentStreak: Int {
        let sortedDates = Set(entries.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)
        guard !sortedDates.isEmpty else { return 0 }
        
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        // If no entry today, start from yesterday
        if !sortedDates.contains(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }
        
        for date in sortedDates {
            if date == checkDate {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else if date < checkDate {
                break
            }
        }
        
        return streak
    }
    
    private var canNavigateForward: Bool {
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        let selectedMonthNum = calendar.component(.month, from: selectedMonth)
        let selectedYear = calendar.component(.year, from: selectedMonth)
        
        return selectedYear < currentYear || (selectedYear == currentYear && selectedMonthNum < currentMonth)
    }
    
    private func navigateMonth(by value: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if let newMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
                selectedMonth = newMonth
            }
        }
        Theme.Haptics.light()
    }
    
    private func hasEntryOn(date: Date) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        return entries.contains { calendar.startOfDay(for: $0.date) == dayStart }
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }
        
        var days: [Date?] = []
        
        // Add empty cells for days before the first of the month
        let emptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        for _ in 0..<emptyDays {
            days.append(nil)
        }
        
        // Add all days in the month
        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? monthInterval.end
        }
        
        return days
    }
    
    private func entriesInMonth(_ month: Date) -> [EmotionEntry] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        return entries.filter { $0.date >= monthInterval.start && $0.date < monthInterval.end }
    }
    
    private func daysPassedInMonth(_ month: Date) -> Int {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return 0 }
        let today = Date()
        
        if today < monthInterval.start {
            return 0
        } else if today >= monthInterval.end {
            return calendar.component(.day, from: calendar.date(byAdding: .day, value: -1, to: monthInterval.end) ?? monthInterval.end)
        } else {
            return calendar.component(.day, from: today)
        }
    }
}

// MARK: - Flame Ring View

struct FlameRingView: View {
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.orange.opacity(0.8),
                            Color.accentGold.opacity(0.6),
                            Color.red.opacity(0.4),
                            Color.orange.opacity(0.8)
                        ],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .blur(radius: 2)
                .scaleEffect(isAnimating ? 1.15 : 1.0)
                .opacity(isAnimating ? 0.6 : 0.8)
            
            // Inner ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.orange,
                            Color.accentGold,
                            Color.orange
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
        }
    }
}

// MARK: - Entry Detail Sheet

struct EntryDetailSheet: View {
    let entries: [EmotionEntry]
    let date: Date
    @Environment(\.dismiss) private var dismiss
    
    private let calendar = Calendar.current
    
    private var entriesOnDate: [EmotionEntry] {
        let dayStart = calendar.startOfDay(for: date)
        return entries.filter { calendar.startOfDay(for: $0.date) == dayStart }
            .sorted { $0.date > $1.date }
    }
    
    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peacefulGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        if entriesOnDate.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(entriesOnDate) { entry in
                                entryCard(entry)
                            }
                        }
                    }
                    .padding(.horizontal, Layout.screenPadding)
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationTitle(dateLabel)
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
    
    private var emptyStateView: some View {
        Card {
            VStack(spacing: Spacing.md) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundColor(.textSecondary.opacity(0.5))
                
                Text("No entries on this day")
                    .font(Typography.body)
                    .foregroundColor(.textSecondary)
            }
            .padding(.vertical, Spacing.xl)
        }
    }
    
    private func entryCard(_ entry: EmotionEntry) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header with emoji and time
                HStack {
                    Text(Theme.emoji(for: entry.emotionRating))
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rating: \(entry.emotionRating)/10")
                            .font(Typography.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text(timeLabel(for: entry.date))
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // Transcription if available
                if let transcription = entry.cleanedTranscription ?? entry.transcription,
                   !transcription.isEmpty {
                    Divider()
                    
                    Text(transcription)
                        .font(Typography.body)
                        .foregroundColor(.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Spacing.sm)
        }
    }
    
    private func timeLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
