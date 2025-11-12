//
//  Achievement.swift
//  pocket-garden
//
//  Gamification - Achievements and Badges System
//

import SwiftUI
import SwiftData

// MARK: - Achievement Model

@Model
final class Achievement {
    var id: String
    var title: String
    var achievementDescription: String
    var emoji: String
    var isUnlocked: Bool
    var unlockedDate: Date?
    var progress: Int
    var targetProgress: Int
    var category: String
    var rarity: AchievementRarity

    init(
        id: String,
        title: String,
        description: String,
        emoji: String,
        targetProgress: Int,
        category: String,
        rarity: AchievementRarity = .common
    ) {
        self.id = id
        self.title = title
        self.achievementDescription = description
        self.emoji = emoji
        self.isUnlocked = false
        self.progress = 0
        self.targetProgress = targetProgress
        self.category = category
        self.rarity = rarity
    }

    var progressPercentage: Double {
        guard targetProgress > 0 else { return 0 }
        return min(Double(progress) / Double(targetProgress), 1.0)
    }

    func unlock() {
        isUnlocked = true
        unlockedDate = Date()
        progress = targetProgress
    }
}

// MARK: - Achievement Rarity

enum AchievementRarity: String, Codable {
    case common
    case rare
    case epic
    case legendary

    var color: Color {
        switch self {
        case .common: return .primaryGreen
        case .rare: return .accentGold
        case .epic: return .emotionContent
        case .legendary: return .emotionJoy
        }
    }

    var name: String {
        rawValue.capitalized
    }
}

// MARK: - Achievement Definitions

extension Achievement {
    static func createDefaultAchievements() -> [Achievement] {
        [
            // Streak Achievements
            Achievement(
                id: "streak_3",
                title: "Getting Started",
                description: "Maintain a 3-day streak",
                emoji: "🌱",
                targetProgress: 3,
                category: "Streaks",
                rarity: .common
            ),
            Achievement(
                id: "streak_7",
                title: "Week Warrior",
                description: "Maintain a 7-day streak",
                emoji: "🔥",
                targetProgress: 7,
                category: "Streaks",
                rarity: .rare
            ),
            Achievement(
                id: "streak_30",
                title: "Monthly Master",
                description: "Maintain a 30-day streak",
                emoji: "⭐",
                targetProgress: 30,
                category: "Streaks",
                rarity: .epic
            ),
            Achievement(
                id: "streak_100",
                title: "Century Club",
                description: "Maintain a 100-day streak",
                emoji: "💎",
                targetProgress: 100,
                category: "Streaks",
                rarity: .legendary
            ),

            // Total Entries
            Achievement(
                id: "entries_10",
                title: "Budding Writer",
                description: "Create 10 journal entries",
                emoji: "📝",
                targetProgress: 10,
                category: "Entries",
                rarity: .common
            ),
            Achievement(
                id: "entries_50",
                title: "Journaling Pro",
                description: "Create 50 journal entries",
                emoji: "📚",
                targetProgress: 50,
                category: "Entries",
                rarity: .rare
            ),
            Achievement(
                id: "entries_100",
                title: "Memoir Master",
                description: "Create 100 journal entries",
                emoji: "🏆",
                targetProgress: 100,
                category: "Entries",
                rarity: .epic
            ),

            // Garden Growth
            Achievement(
                id: "trees_20",
                title: "Small Forest",
                description: "Grow 20 trees in your garden",
                emoji: "🌲",
                targetProgress: 20,
                category: "Garden",
                rarity: .rare
            ),
            Achievement(
                id: "trees_50",
                title: "Mighty Forest",
                description: "Grow 50 trees in your garden",
                emoji: "🌳",
                targetProgress: 50,
                category: "Garden",
                rarity: .epic
            ),
            Achievement(
                id: "bloom_10",
                title: "Master Gardener",
                description: "Grow 10 blooming trees",
                emoji: "🌸",
                targetProgress: 10,
                category: "Garden",
                rarity: .epic
            ),

            // Emotional Wellness
            Achievement(
                id: "positive_streak_5",
                title: "Positive Vibes",
                description: "Log 5 consecutive positive entries (8+)",
                emoji: "😊",
                targetProgress: 5,
                category: "Wellness",
                rarity: .rare
            ),
            Achievement(
                id: "growth_journey",
                title: "Growth Mindset",
                description: "Improve average rating by 2 points",
                emoji: "📈",
                targetProgress: 2,
                category: "Wellness",
                rarity: .epic
            ),

            // Special Achievements
            Achievement(
                id: "early_bird",
                title: "Early Bird",
                description: "Journal before 8 AM 10 times",
                emoji: "🌅",
                targetProgress: 10,
                category: "Special",
                rarity: .rare
            ),
            Achievement(
                id: "night_owl",
                title: "Night Owl",
                description: "Journal after 10 PM 10 times",
                emoji: "🌙",
                targetProgress: 10,
                category: "Special",
                rarity: .rare
            ),
            Achievement(
                id: "wordsmith",
                title: "Wordsmith",
                description: "Write a journal entry over 500 words",
                emoji: "✍️",
                targetProgress: 1,
                category: "Special",
                rarity: .epic
            ),
            Achievement(
                id: "shake_master",
                title: "Celebration Expert",
                description: "Trigger garden celebration 25 times",
                emoji: "🎉",
                targetProgress: 25,
                category: "Special",
                rarity: .rare
            )
        ]
    }
}

// MARK: - Achievement Service

@Observable
class AchievementService {
    var achievements: [Achievement] = []
    var recentlyUnlocked: Achievement?
    var showUnlockNotification = false

    func checkAchievements(entries: [EmotionEntry], currentStreak: Int) {
        // Check streak achievements
        checkStreakAchievements(currentStreak: currentStreak)

        // Check entry count achievements
        checkEntryAchievements(entryCount: entries.count)

        // Check tree achievements
        checkTreeAchievements(entries: entries)

        // Check wellness achievements
        checkWellnessAchievements(entries: entries)

        // Check special achievements
        checkSpecialAchievements(entries: entries)
    }

    private func checkStreakAchievements(currentStreak: Int) {
        updateAchievement(id: "streak_3", progress: currentStreak)
        updateAchievement(id: "streak_7", progress: currentStreak)
        updateAchievement(id: "streak_30", progress: currentStreak)
        updateAchievement(id: "streak_100", progress: currentStreak)
    }

    private func checkEntryAchievements(entryCount: Int) {
        updateAchievement(id: "entries_10", progress: entryCount)
        updateAchievement(id: "entries_50", progress: entryCount)
        updateAchievement(id: "entries_100", progress: entryCount)
    }

    private func checkTreeAchievements(entries: [EmotionEntry]) {
        let treeCount = entries.count
        let bloomCount = entries.filter { $0.treeStage == TreeStage.bloomingTree.rawValue }.count

        updateAchievement(id: "trees_20", progress: treeCount)
        updateAchievement(id: "trees_50", progress: treeCount)
        updateAchievement(id: "bloom_10", progress: bloomCount)
    }

    private func checkWellnessAchievements(entries: [EmotionEntry]) {
        // Check positive streak
        let sortedEntries = entries.sorted { $0.date > $1.date }
        var positiveStreak = 0
        for entry in sortedEntries {
            if entry.emotionRating >= 8 {
                positiveStreak += 1
            } else {
                break
            }
        }
        updateAchievement(id: "positive_streak_5", progress: positiveStreak)
    }

    private func checkSpecialAchievements(entries: [EmotionEntry]) {
        let calendar = Calendar.current

        // Early bird count (before 8 AM)
        let earlyCount = entries.filter { entry in
            let hour = calendar.component(.hour, from: entry.date)
            return hour < 8
        }.count
        updateAchievement(id: "early_bird", progress: earlyCount)

        // Night owl count (after 10 PM)
        let nightCount = entries.filter { entry in
            let hour = calendar.component(.hour, from: entry.date)
            return hour >= 22
        }.count
        updateAchievement(id: "night_owl", progress: nightCount)

        // Wordsmith (long transcription)
        let hasLongEntry = entries.contains { entry in
            (entry.transcription?.count ?? 0) > 500
        }
        if hasLongEntry {
            updateAchievement(id: "wordsmith", progress: 1)
        }
    }

    private func updateAchievement(id: String, progress: Int) {
        guard let achievement = achievements.first(where: { $0.id == id }) else { return }

        let wasUnlocked = achievement.isUnlocked
        achievement.progress = progress

        // Check if achievement should be unlocked
        if !wasUnlocked && progress >= achievement.targetProgress {
            achievement.unlock()
            notifyUnlock(achievement)
        }
    }

    func incrementShakeCelebration() {
        guard let achievement = achievements.first(where: { $0.id == "shake_master" }) else { return }
        let wasUnlocked = achievement.isUnlocked
        achievement.progress += 1

        if !wasUnlocked && achievement.progress >= achievement.targetProgress {
            achievement.unlock()
            notifyUnlock(achievement)
        }
    }

    private func notifyUnlock(_ achievement: Achievement) {
        Theme.Haptics.success()
        recentlyUnlocked = achievement
        showUnlockNotification = true
    }

    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var totalCount: Int {
        achievements.count
    }

    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }
}
