//
//  AchievementViews.swift
//  pocket-garden
//
//  UI Components for Achievements and Gamification
//

import SwiftUI

// MARK: - Achievement Unlock Notification

struct AchievementUnlockView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0
    @State private var rotation: Double = -10
    @State private var showSparkles = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.xl) {
                // Sparkles effect
                if showSparkles {
                    SparklesView(sparkleCount: 20)
                }

                // Achievement badge
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    achievement.rarity.color.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    // Badge circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    achievement.rarity.color.opacity(0.8),
                                    achievement.rarity.color
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        )
                        .shadow(color: achievement.rarity.color.opacity(0.5), radius: 20)

                    // Emoji
                    Text(achievement.emoji)
                        .font(.system(size: 60))
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))

                // Achievement info card
                Card {
                    VStack(spacing: Spacing.md) {
                        // Rarity badge
                        Text(achievement.rarity.name.uppercased())
                            .font(Typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(achievement.rarity.color)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(achievement.rarity.color.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)

                        Text("Achievement Unlocked!")
                            .font(Typography.title3)
                            .foregroundColor(.textPrimary)

                        Text(achievement.title)
                            .font(Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryGreen)

                        Text(achievement.achievementDescription)
                            .font(Typography.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, Layout.screenPadding)

                // Dismiss button
                PrimaryButton("Awesome!", icon: "checkmark") {
                    dismiss()
                }
                .padding(.horizontal, Layout.screenPadding)
            }

            Spacer()
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea())
        .onAppear {
            Theme.Haptics.success()

            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    showSparkles = true
                }
            }
        }
    }

    private func dismiss() {
        Theme.Haptics.light()
        withAnimation {
            scale = 0.8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        Card {
            HStack(spacing: Spacing.md) {
                // Badge
                ZStack {
                    Circle()
                        .fill(
                            achievement.isUnlocked ?
                            LinearGradient(
                                colors: [achievement.rarity.color.opacity(0.3), achievement.rarity.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Text(achievement.emoji)
                        .font(.system(size: 32))
                        .grayscale(achievement.isUnlocked ? 0 : 0.99)
                        .opacity(achievement.isUnlocked ? 1.0 : 0.3)
                }

                // Info
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(achievement.title)
                            .font(Typography.headline)
                            .foregroundColor(achievement.isUnlocked ? .textPrimary : .textSecondary)

                        if achievement.isUnlocked {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.successGreen)
                        }
                    }

                    Text(achievement.achievementDescription)
                        .font(Typography.callout)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)

                    // Progress bar
                    if !achievement.isUnlocked {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    Capsule()
                                        .fill(Color.gray.opacity(0.2))

                                    // Progress
                                    Capsule()
                                        .fill(achievement.rarity.color)
                                        .frame(width: geometry.size.width * achievement.progressPercentage)
                                }
                            }
                            .frame(height: 6)

                            Text("\(achievement.progress)/\(achievement.targetProgress)")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                        }
                    } else if let date = achievement.unlockedDate {
                        Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(Typography.caption)
                            .foregroundColor(.successGreen)
                    }
                }

                Spacer()
            }
            .padding(Spacing.sm)
        }
    }
}

// MARK: - Achievements Overview

struct AchievementsOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    let achievements: [Achievement]

    private var categories: [String] {
        Array(Set(achievements.map { $0.category })).sorted()
    }

    var body: some View {
        ZStack {
            Color.peacefulGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header stats
                    headerSection

                    // Achievements by category
                    ForEach(categories, id: \.self) { category in
                        categorySection(category: category)
                    }
                }
                .padding(Layout.screenPadding)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headerSection: some View {
        Card {
            VStack(spacing: Spacing.lg) {
                Text("🏆")
                    .font(.system(size: 60))

                VStack(spacing: Spacing.xs) {
                    Text("\(unlockedCount) of \(totalCount)")
                        .font(Typography.title)
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
            }
            .padding(Spacing.md)
        }
    }

    private func categorySection(category: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(category)
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            ForEach(achievements.filter { $0.category == category }) { achievement in
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
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(challenge.category.color)
                        .cornerRadius(CornerRadius.sm)
                    }
                    .pressAnimation()
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
                        label: "Avg Rating",
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
        emoji: "🔥",
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
        emoji: "🌱",
        targetProgress: 3,
        category: "Streaks",
        rarity: .common
    )
    unlocked.unlock()
    
    let inProgress = Achievement(
        id: "streak_7",
        title: "Week Warrior",
        description: "Maintain a 7-day streak",
        emoji: "🔥",
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
