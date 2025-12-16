//
//  AchievementViews.swift
//  pocket-garden
//
//  UI Components for Achievements and Gamification
//

import SwiftUI
import SwiftData

// MARK: - Achievement Unlock Notification (Duolingo-Style)

struct AchievementUnlockView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var badgeScale: CGFloat = 0
    @State private var badgeRotation: Double = -15
    @State private var contentOpacity: Double = 0
    @State private var showCelebration = false
    @State private var backgroundOpacity: Double = 0

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black
                .opacity(backgroundOpacity * 0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Celebration effects (no pulse rings - removed per user request)
            if showCelebration {
                // Extra stars for legendary
                if achievement.rarity == .legendary {
                    FloatingStars(count: 12)
                }
            }

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Achievement badge
                ZStack {
                    // Badge with SF Symbol
                    ZStack {
                        // Outer ring
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: achievement.rarity.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 130, height: 130)
                            .shadow(color: achievement.rarity.color.opacity(0.5), radius: 20)
                        
                        // Inner circle
                        Circle()
                            .fill(Color.cardBackground)
                            .frame(width: 110, height: 110)

                        // SF Symbol with shimmer effect (same as achievements page)
                        Image(systemName: achievement.symbolName)
                            .font(.system(size: 50, weight: .semibold))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(achievement.rarity.color)
                            .shimmer(isActive: true)
                    }
                }
                .scaleEffect(badgeScale)
                .rotationEffect(.degrees(badgeRotation))
                .rotation3DEffect(
                    .degrees(badgeRotation * 2),
                    axis: (x: 0.0, y: 1.0, z: 0.0)
                )

                // Achievement info card
                VStack(spacing: Spacing.lg) {
                    // Rarity badge
                    Text(achievement.rarity.name.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(achievement.rarity.color)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            Capsule()
                                .fill(achievement.rarity.color.opacity(0.15))
                        )
                    
                    Text("Achievement Unlocked!")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)

                    Text(achievement.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(achievement.achievementDescription)
                        .font(Typography.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.md)
                }
                .padding(Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.xl)
                        .fill(Color.cardBackground)
                        .shadow(color: Color.black.opacity(0.15), radius: 20, y: 10)
                )
                .padding(.horizontal, Layout.screenPadding)
                .opacity(contentOpacity)

                // Buttons
                VStack(spacing: Spacing.sm) {
                    Button(action: dismiss) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                            Text("Awesome!")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: achievement.rarity.gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(CornerRadius.lg)
                        .shadow(color: achievement.rarity.color.opacity(0.4), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                    .opacity(contentOpacity)
                }
                .padding(.horizontal, Layout.screenPadding)

                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        _ = achievement.rarity.animationDuration
        
        // Background fade in
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 1.0
        }
        
        // Badge animation with elastic bounce
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1)) {
            badgeScale = 1.0
            badgeRotation = 0
        }
        
        // Celebration effects
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showCelebration = true
            Theme.Haptics.success()
        }
        
        // Content fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            contentOpacity = 1.0
        }
    }

    private func dismiss() {
        Theme.Haptics.light()
        
        withAnimation(.easeIn(duration: 0.2)) {
            badgeScale = 0.8
            backgroundOpacity = 0
            contentOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement
    
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Badge
            AchievementSymbolView(
                symbolName: achievement.symbolName,
                symbolStyle: achievement.symbolStyle,
                paletteColors: achievement.paletteColors,
                rarity: achievement.rarity,
                isUnlocked: achievement.isUnlocked,
                size: 64
            )
            .shimmer(isActive: achievement.isUnlocked)

            // Info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(achievement.title)
                        .font(Typography.headline)
                        .foregroundColor(achievement.isUnlocked ? .textPrimary : .textSecondary)

                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.successGreen)
                    }
                    
                    Spacer()
                    
                    // Rarity indicator
                    Text(achievement.rarity.name)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(achievement.rarity.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(achievement.rarity.color.opacity(0.15))
                        )
                }

                Text(achievement.achievementDescription)
                    .font(Typography.callout)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)

                // Progress bar or unlock date
                if !achievement.isUnlocked {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                Capsule()
                                    .fill(Color.gray.opacity(0.2))

                                // Progress
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: achievement.rarity.gradientColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * achievement.progressPercentage)
                            }
                        }
                        .frame(height: 6)

                        Text("\(achievement.progress)/\(achievement.targetProgress)")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                } else if let date = achievement.unlockedDate {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(Typography.caption)
                    }
                    .foregroundColor(.successGreen)
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.cardBackground)
                .shadow(
                    color: achievement.isUnlocked ? achievement.rarity.color.opacity(0.1) : Color.black.opacity(0.05),
                    radius: achievement.isUnlocked ? 8 : 4,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    achievement.isUnlocked ? achievement.rarity.color.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Achievements Overview

struct AchievementsOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Achievement.category) private var achievements: [Achievement]
    
    
    private var sortedAchievements: [Achievement] {
        // Sort unlocked first, then by progress
        achievements.sorted { a, b in
            if a.isUnlocked != b.isUnlocked {
                return a.isUnlocked
            }
            return a.progressPercentage > b.progressPercentage
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.peacefulGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header stats
                        headerSection

                        // Achievements list
                        achievementsList
                    }
                    .padding(Layout.screenPadding)
                    .padding(.bottom, Spacing.xxxl)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
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

    private var headerSection: some View {
        Card {
            VStack(spacing: Spacing.lg) {
                // Trophy icon with glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.accentGold.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.85, blue: 0.3), .accentGold],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                VStack(spacing: Spacing.xs) {
                    Text("\(unlockedCount) of \(totalCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)

                    Text("Achievements Unlocked")
                        .font(Typography.callout)
                        .foregroundColor(.textSecondary)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.primaryGreen, Color.accentGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * completionPercentage)
                    }
                }
                .frame(height: 12)

                Text("\(Int(completionPercentage * 100))% Complete")
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)
                
                // Rarity breakdown
                HStack(spacing: Spacing.lg) {
                    ForEach(AchievementRarity.allCases, id: \.self) { rarity in
                        let count = achievements.filter { $0.rarity == rarity && $0.isUnlocked }.count
                        let total = achievements.filter { $0.rarity == rarity }.count
                        
                        VStack(spacing: 2) {
                            Circle()
                                .fill(rarity.color)
                                .frame(width: 12, height: 12)
                            Text("\(count)/\(total)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(.top, Spacing.sm)
            }
            .padding(Spacing.lg)
        }
    }
    
    
    private var achievementsList: some View {
        VStack(spacing: Spacing.md) {
            ForEach(sortedAchievements) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
    }

    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    private var totalCount: Int {
        achievements.count
    }

    private var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }

    // Quick Tip removed per UX request (keep this screen focused and clean).
}


// MARK: - Daily Challenge Card

struct DailyChallengeCard: View {
    let challenge: DailyChallenge
    let hasCompletedToday: Bool
    let onTap: () -> Void

    var body: some View {
        Card {
            VStack(spacing: Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: challenge.category.icon)
                                .font(.system(size: 12))
                                .foregroundColor(challenge.category.color)

                            Text(challenge.category.rawValue.uppercased())
                                .font(Typography.caption)
                                .foregroundColor(challenge.category.color)
                        }

                        Text("Today's Challenge")
                            .font(Typography.title3)
                            .foregroundColor(.textPrimary)
                    }

                    Spacer()

                    Text(challenge.emoji)
                        .font(.system(size: 40))
                }

                Text(challenge.prompt)
                    .font(Typography.body)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if hasCompletedToday {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.successGreen)
                        Text("Challenge Completed!")
                            .font(Typography.callout)
                            .foregroundColor(.successGreen)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.successGreen.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
                } else {
                    Button(action: onTap) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Start Journaling")
                        }
                        .font(Typography.callout.bold())
                        .foregroundColor(Color(light: "FFFFFF", dark: "2A2A2E"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(challenge.category.color)
                        .cornerRadius(CornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.md)
        }
    }
}

// MARK: - Weekly Insight Card

struct WeeklyInsightCard: View {
    let insight: WeeklyInsight

    var body: some View {
        Card {
            VStack(spacing: Spacing.lg) {
                HStack {
                    Text("📊 Weekly Insight")
                        .font(Typography.title3)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Text(insight.moodTrend.emoji)
                        .font(.system(size: 28))
                }

                // Stats grid
                HStack(spacing: Spacing.md) {
                    insightStat(
                        value: "\(insight.totalEntries)",
                        label: "Entries",
                        color: .primaryGreen
                    )

                    Divider()
                        .frame(height: 40)

                    insightStat(
                        value: String(format: "%.1f", insight.averageRating),
                        label: "Avg Mood",
                        color: .accentGold
                    )

                    Divider()
                        .frame(height: 40)

                    insightStat(
                        value: insight.dominantEmotion,
                        label: "Mood",
                        color: .emotionContent
                    )
                }

                // Encouragement
                Text(insight.encouragement)
                    .font(Typography.callout)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.sm)
            }
            .padding(Spacing.md)
        }
    }

    private func insightStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(Typography.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("Achievement Unlock") {
    let achievement = Achievement(
        id: "streak_7",
        title: "Week Warrior",
        description: "Maintain a 7-day streak",
        symbolName: "flame.fill",
        targetProgress: 7,
        category: "Streaks",
        rarity: .rare
    )
    achievement.unlock()

    return AchievementUnlockView(achievement: achievement) {
        print("Dismissed")
    }
}

#Preview("Achievement Card") {
    let unlocked = Achievement(
        id: "streak_3",
        title: "Getting Started",
        description: "Maintain a 3-day streak",
        symbolName: "leaf.fill",
        targetProgress: 3,
        category: "Streaks",
        rarity: .common
    )
    unlocked.unlock()
    
    let inProgress = Achievement(
        id: "streak_7",
        title: "Week Warrior",
        description: "Maintain a 7-day streak",
        symbolName: "flame.fill",
        targetProgress: 7,
        category: "Streaks",
        rarity: .rare
    )
    inProgress.progress = 4
    
    return VStack(spacing: Spacing.md) {
        AchievementCard(achievement: unlocked)
        AchievementCard(achievement: inProgress)
    }
    .padding()
    .background(Color.backgroundCream)
}

#Preview("Daily Challenge") {
    let challenge = DailyChallenge.todaysChallenge()

    return VStack(spacing: Spacing.md) {
        DailyChallengeCard(challenge: challenge, hasCompletedToday: false) {
            print("Start journaling")
        }

        DailyChallengeCard(challenge: challenge, hasCompletedToday: true) {
            print("Already completed")
        }
    }
    .padding()
    .background(Color.backgroundCream)
}

#Preview("Weekly Insight") {
    let entries = EmotionEntry.sampleEntries()
    let insight = WeeklyInsight.generate(from: entries)

    return WeeklyInsightCard(insight: insight)
        .padding()
        .background(Color.backgroundCream)
}
