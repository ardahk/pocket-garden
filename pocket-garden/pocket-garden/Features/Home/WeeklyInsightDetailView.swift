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
    
    @State private var weeklyQuote: Quote?
    @State private var isLoadingQuote = true
    private let quoteService = QuoteService()
    
    private var weeklyInsight: WeeklyInsight {
        WeeklyInsight.generate(from: entries)
    }
    
    private var thisWeekEntries: [EmotionEntry] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return entries.filter { $0.date >= weekAgo }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peacefulGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Panda mascot with greeting
                        pandaSection
                        
                        // Quote of the Week
                        weeklyQuoteSection
                        
                        // Weekly stats overview
                        weeklyStatsSection
                        
                        // Detailed insights
                        insightsSection
                        
                        // Panda's personalized motivation
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
    
    // MARK: - Panda Section
    
    private var pandaSection: some View {
        Card {
            VStack(spacing: Spacing.lg) {
                GardenMascot(emotion: pandaEmotion, size: 100)
                    .scaleEffect(1.0)
                
                Text(pandaGreeting)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(pandaSubtitle)
                    .font(Typography.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, Spacing.md)
        }
        .fadeIn()
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
            Text("Panda's Message")
                .font(Typography.headline)
                .foregroundColor(.textPrimary)
            
            Card {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(alignment: .top, spacing: Spacing.md) {
                        GardenMascot(emotion: .supportive, size: 50)
                        
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(pandaMotivation)
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
                .padding(.vertical, Spacing.sm)
            }
        }
        .slideInFromBottom(delay: 0.3)
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
