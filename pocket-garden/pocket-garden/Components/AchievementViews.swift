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
    @State private var badgeRotation: Double = -30
    @State private var contentOpacity: Double = 0
    @State private var showCelebration = false
    @State private var backgroundOpacity: Double = 0
    @State private var lightBurstScale: CGFloat = 0
    @State private var lightBurstOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var descOffset: CGFloat = 20
    @State private var buttonOffset: CGFloat = 30
    @State private var iconPulse: CGFloat = 1.0
    @State private var showConfetti = false
    @State private var outerRingRotation: Double = 0
    @State private var outerRingPulse: CGFloat = 1.0
    @State private var outerRingOpacity: Double = 0
    @State private var viewSlideUp: CGFloat = UIScreen.main.bounds.height

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black
                .opacity(backgroundOpacity * 0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Light burst behind badge
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            achievement.rarity.color.opacity(0.6),
                            achievement.rarity.color.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .scaleEffect(lightBurstScale)
                .opacity(lightBurstOpacity)
                .offset(y: -60)
            
            // Confetti particles
            if showConfetti {
                AchievementConfettiView(
                    particleCount: achievement.rarity == .legendary ? 70 : (achievement.rarity == .epic ? 50 : 35),
                    colors: achievement.rarity.gradientColors + [.accentGold, .primaryGreen]
                )
            }
            
            // Celebration effects
            if showCelebration {
                if achievement.rarity == .legendary {
                    FloatingStars(count: 15)
                } else if achievement.rarity == .epic {
                    FloatingStars(count: 8)
                }
            }

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Achievement badge with enhanced animation
                ZStack {
                    // Animated outer ring — rotating gradient border
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: achievement.rarity.gradientColors + [achievement.rarity.gradientColors.first ?? .clear],
                                center: .center
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(outerRingRotation))
                        .scaleEffect(outerRingPulse)
                        .opacity(outerRingOpacity)
                        .shadow(color: achievement.rarity.color.opacity(0.4), radius: 12)
                        .blur(radius: 0.5) // Slight blur for smooth gradient effect
                    
                    ZStack {
                        // Outer ring with glow
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: achievement.rarity.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                            .shadow(color: achievement.rarity.color.opacity(0.6), radius: 30)
                            .shadow(color: achievement.rarity.color.opacity(0.3), radius: 15)
                        
                        // Inner circle
                        Circle()
                            .fill(Color.cardBackground)
                            .frame(width: 116, height: 116)

                        // SF Symbol with shimmer + pulse
                        Image(systemName: achievement.symbolName)
                            .font(.system(size: 52, weight: .semibold))
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(achievement.rarity.color)
                            .scaleEffect(iconPulse)
                            .shimmer(isActive: true)
                    }
                }
                .scaleEffect(badgeScale)
                .rotationEffect(.degrees(badgeRotation))
                .rotation3DEffect(
                    .degrees(badgeRotation * 2),
                    axis: (x: 0.1, y: 1.0, z: 0.0)
                )

                // Achievement info card with staggered reveal
                VStack(spacing: Spacing.lg) {
                    // Rarity badge
                    Text(achievement.rarity.name.uppercased())
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(achievement.rarity.color)
                        .tracking(2)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            Capsule()
                                .fill(achievement.rarity.color.opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .stroke(achievement.rarity.color.opacity(0.3), lineWidth: 1)
                                )
                        )
                    
                    Text("Achievement Unlocked!")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.textSecondary)
                        .offset(y: titleOffset)

                    Text(achievement.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .offset(y: titleOffset)

                    Text(unlockMessage)
                        .font(Typography.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.md)
                        .offset(y: descOffset)
                }
                .padding(Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.xl)
                        .fill(Color.cardBackground)
                        .shadow(color: Color.black.opacity(0.15), radius: 20, y: 10)
                )
                .padding(.horizontal, Layout.screenPadding)
                .opacity(contentOpacity)

                // Button with slide-up
                Button(action: dismiss) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "sparkles")
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
                    .shadow(color: achievement.rarity.color.opacity(0.5), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .opacity(contentOpacity)
                .offset(y: buttonOffset)
                .padding(.horizontal, Layout.screenPadding)

                Spacer()
            }
        }
        .offset(y: viewSlideUp)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Slide entire view up from bottom
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            viewSlideUp = 0
        }
        
        // Background fade in
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 1.0
        }
        
        // Light burst flash
        withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
            lightBurstScale = 1.0
            lightBurstOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
            lightBurstOpacity = 0.3
        }
        
        // Badge slam-in with bounce
        withAnimation(.spring(response: 0.5, dampingFraction: 0.45).delay(0.25)) {
            badgeScale = 1.0
            badgeRotation = 0
        }
        
        // Outer ring appears and starts spinning after badge lands
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) {
                outerRingOpacity = 1.0
            }
            // Smooth continuous rotation
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                outerRingRotation = 360
            }
            // Gentle breathing pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                outerRingPulse = 1.05
            }
        }
        
        // Icon pulse after landing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                iconPulse = 1.06
            }
        }
        
        // Confetti burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showConfetti = true
            Theme.Haptics.success()
        }
        
        // Celebration effects (stars)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showCelebration = true
        }
        
        // Content staggered slide-up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.65)) {
            contentOpacity = 1.0
            titleOffset = 0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.75)) {
            descOffset = 0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.85)) {
            buttonOffset = 0
        }
    }

    private func dismiss() {
        Theme.Haptics.light()
        
        withAnimation(.easeIn(duration: 0.25)) {
            badgeScale = 1.15
        }
        withAnimation(.easeIn(duration: 0.2).delay(0.05)) {
            badgeScale = 0
            backgroundOpacity = 0
            contentOpacity = 0
            lightBurstOpacity = 0
            outerRingOpacity = 0
        }
        withAnimation(.easeIn(duration: 0.3).delay(0.05)) {
            viewSlideUp = UIScreen.main.bounds.height
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onDismiss()
        }
    }

    private var unlockMessage: String {
        let raw = achievement.achievementDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return "You unlocked this achievement." }

        let words = raw.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard let firstWord = words.first else { return "You unlocked this achievement." }

        let remainder = words.count > 1 ? " " + words[1] : ""
        let normalizedFirstWord = firstWord.lowercased()

        let pastTenseLead: String
        switch normalizedFirstWord {
        case "create": pastTenseLead = "created"
        case "maintain": pastTenseLead = "maintained"
        case "grow": pastTenseLead = "grown"
        case "log": pastTenseLead = "logged"
        case "improve": pastTenseLead = "improved"
        case "journal": pastTenseLead = "journaled"
        case "write": pastTenseLead = "written"
        case "trigger": pastTenseLead = "triggered"
        case "restart": pastTenseLead = "restarted"
        default: pastTenseLead = normalizedFirstWord
        }

        return "You have \(pastTenseLead)\(remainder)."
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
