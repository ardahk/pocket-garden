//
//  AchievementManager.swift
//  pocket-garden
//
//  Manages achievement tracking, persistence, and unlock notifications
//

import Foundation
import SwiftUI
import SwiftData
internal import Combine

// MARK: - Achievement Manager

@MainActor
class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published var recentlyUnlockedAchievement: Achievement?
    @Published var showUnlockAnimation = false
    @Published var hasUnseenUnlock = false
    
    /// Callback triggered when achievement popup is dismissed
    var onAchievementDismissed: (() -> Void)?
    
    private init() {}
    
    // MARK: - Initialization
    
    /// Seeds / updates default achievements.
    ///
    /// Important: This MUST be resilient to app updates.
    /// If we ship new achievements later, existing users should automatically get the new ones
    /// without losing progress on achievements they've already started/unlocked.
    /// Also removes achievements that are no longer in the defaults list.
    func initializeAchievements(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Achievement>()
        
        do {
            let existingAchievements = try modelContext.fetch(descriptor)

            let defaults = Achievement.createDefaultAchievements()
            let defaultIds = Set(defaults.map { $0.id })
            let existingById = Dictionary(uniqueKeysWithValues: existingAchievements.map { ($0.id, $0) })

            var inserted = 0
            var updated = 0
            var removed = 0

            // Add or update achievements from defaults
            for def in defaults {
                if let existing = existingById[def.id] {
                    // Update display metadata (safe) but preserve user progress/unlock state.
                    // This keeps titles/descriptions/icons consistent if we tweak copy later.
                    if existing.title != def.title { existing.title = def.title; updated += 1 }
                    if existing.achievementDescription != def.achievementDescription { existing.achievementDescription = def.achievementDescription; updated += 1 }
                    if existing.symbolName != def.symbolName { existing.symbolName = def.symbolName; updated += 1 }
                    if existing.symbolStyleName != def.symbolStyleName { existing.symbolStyleName = def.symbolStyleName; updated += 1 }
                    if existing.symbolColorsHex != def.symbolColorsHex { existing.symbolColorsHex = def.symbolColorsHex; updated += 1 }
                    if existing.targetProgress != def.targetProgress { existing.targetProgress = def.targetProgress; updated += 1 }
                    if existing.category != def.category { existing.category = def.category; updated += 1 }
                    if existing.rarity != def.rarity { existing.rarity = def.rarity; updated += 1 }
                } else {
                    modelContext.insert(def)
                    inserted += 1
                }
            }
            
            // Remove achievements that are no longer in defaults
            for existing in existingAchievements {
                if !defaultIds.contains(existing.id) {
                    modelContext.delete(existing)
                    removed += 1
                }
            }

            if inserted > 0 || updated > 0 || removed > 0 {
                try modelContext.save()
            }

        } catch {
        }
    }
    
    // MARK: - Achievement Checking
    
    /// Main method to check and update all achievements
    func checkAndUpdateAchievements(
        entries: [EmotionEntry],
        trees: [GrowingTree],
        currentStreak: Int,
        modelContext: ModelContext
    ) {
        let descriptor = FetchDescriptor<Achievement>()
        
        do {
            let achievements = try modelContext.fetch(descriptor)
            
            // Check each category
            checkStreakAchievements(achievements: achievements, currentStreak: currentStreak, modelContext: modelContext)
            checkEntryAchievements(achievements: achievements, entryCount: entries.count, modelContext: modelContext)
            checkTreeAchievements(achievements: achievements, trees: trees, modelContext: modelContext)
            checkWellnessAchievements(achievements: achievements, entries: entries, modelContext: modelContext)
            checkSpecialAchievements(achievements: achievements, entries: entries, modelContext: modelContext)
            
            try modelContext.save()
        } catch {
        }
    }
    
    // MARK: - Category Checks
    
    private func checkStreakAchievements(achievements: [Achievement], currentStreak: Int, modelContext: ModelContext) {
        updateProgress(achievements: achievements, id: "streak_3", progress: currentStreak, modelContext: modelContext)
        updateProgress(achievements: achievements, id: "streak_7", progress: currentStreak, modelContext: modelContext)
        updateProgress(achievements: achievements, id: "streak_14", progress: currentStreak, modelContext: modelContext)
        updateProgress(achievements: achievements, id: "streak_30", progress: currentStreak, modelContext: modelContext)
        updateProgress(achievements: achievements, id: "streak_100", progress: currentStreak, modelContext: modelContext)
    }
    
    private func checkEntryAchievements(achievements: [Achievement], entryCount: Int, modelContext: ModelContext) {
        updateProgress(achievements: achievements, id: "entry_1", progress: entryCount, modelContext: modelContext)
        updateProgress(achievements: achievements, id: "entries_10", progress: entryCount, modelContext: modelContext)
        updateProgress(achievements: achievements, id: "entries_25", progress: entryCount, modelContext: modelContext)
        updateProgress(achievements: achievements, id: "entries_50", progress: entryCount, modelContext: modelContext)
        updateProgress(achievements: achievements, id: "entries_100", progress: entryCount, modelContext: modelContext)
        updateProgress(achievements: achievements, id: "entries_200", progress: entryCount, modelContext: modelContext)
    }
    
    private func checkTreeAchievements(achievements: [Achievement], trees: [GrowingTree], modelContext: ModelContext) {
        // Count fully grown trees
        let fullyGrownCount = trees.filter { $0.isFullyGrown }.count
        
        // Count blooming trees (cherry trees that are fully grown)
        let bloomingCount = trees.filter { $0.isFullyGrown && $0.treeType == "cherry" }.count
        
        updateProgress(achievements: achievements, id: "trees_5", progress: fullyGrownCount, modelContext: modelContext)
        updateProgress(achievements: achievements, id: "garden_10", progress: fullyGrownCount, modelContext: modelContext)
        updateProgress(achievements: achievements, id: "trees_20", progress: fullyGrownCount, modelContext: modelContext)
        updateProgress(achievements: achievements, id: "trees_50", progress: fullyGrownCount, modelContext: modelContext)
        updateProgress(achievements: achievements, id: "bloom_10", progress: bloomingCount, modelContext: modelContext)
    }
    
    private func checkWellnessAchievements(achievements: [Achievement], entries: [EmotionEntry], modelContext: ModelContext) {
        let calendar = Calendar.current
        let sortedEntries = entries.sorted { $0.date > $1.date }
        
        // Check positive streak (consecutive entries with rating >= 8)
        var positiveStreak = 0
        for entry in sortedEntries {
            if entry.emotionRating >= 8 {
                positiveStreak += 1
            } else {
                break
            }
        }
        updateProgress(achievements: achievements, id: "positive_streak_5", progress: positiveStreak, modelContext: modelContext)
        
        // Check reflection_7: Journal 7 consecutive days
        // This is different from streak - we check actual consecutive calendar days with entries
        var consecutiveDays = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        // Check if there's an entry today first
        let hasEntryToday = sortedEntries.contains { calendar.isDate($0.date, inSameDayAs: currentDate) }
        if !hasEntryToday {
            // Start checking from yesterday
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        for _ in 0..<100 { // Max check 100 days back
            let dayHasEntry = sortedEntries.contains { calendar.isDate($0.date, inSameDayAs: currentDate) }
            if dayHasEntry {
                consecutiveDays += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        updateProgress(achievements: achievements, id: "reflection_7", progress: consecutiveDays, modelContext: modelContext)
        
        // Check mindful_moments: Journal 5 times in a single week
        // Find the maximum number of entries in any 7-day period
        let maxEntriesInWeek = calculateMaxEntriesInWeek(entries: sortedEntries, calendar: calendar)
        updateProgress(achievements: achievements, id: "mindful_moments", progress: maxEntriesInWeek, modelContext: modelContext)
        
        // Check growth journey (improvement in average rating)
        if entries.count >= 14 {
            let recentEntries = Array(sortedEntries.prefix(7))
            let olderEntries = Array(sortedEntries.dropFirst(7).prefix(7))
            
            let recentAvg = Double(recentEntries.reduce(0) { $0 + $1.emotionRating }) / Double(recentEntries.count)
            let olderAvg = Double(olderEntries.reduce(0) { $0 + $1.emotionRating }) / Double(olderEntries.count)
            
            let improvement = Int(recentAvg - olderAvg)
            if improvement > 0 {
                updateProgress(achievements: achievements, id: "growth_journey", progress: improvement, modelContext: modelContext)
            }
        }
    }
    
    /// Calculates the maximum number of entries in any rolling 7-day window
    private func calculateMaxEntriesInWeek(entries: [EmotionEntry], calendar: Calendar) -> Int {
        guard !entries.isEmpty else { return 0 }
        
        var maxCount = 0
        let sortedEntries = entries.sorted { $0.date > $1.date }
        
        // Check each possible 7-day window starting from today going back
        for daysBack in 0..<365 { // Check up to a year back
            guard let windowStart = calendar.date(byAdding: .day, value: -daysBack - 6, to: Date()),
                  let windowEnd = calendar.date(byAdding: .day, value: -daysBack, to: Date()) else {
                continue
            }
            
            let entriesInWindow = sortedEntries.filter { entry in
                entry.date >= windowStart && entry.date <= windowEnd
            }.count
            
            maxCount = max(maxCount, entriesInWindow)
            
            // Early exit if we found 5 (target reached)
            if maxCount >= 5 { break }
        }
        
        return maxCount
    }
    
    private func checkSpecialAchievements(achievements: [Achievement], entries: [EmotionEntry], modelContext: ModelContext) {
        let calendar = Calendar.current
        
        // Early bird count (before 8 AM)
        let earlyCount = entries.filter { entry in
            let hour = calendar.component(.hour, from: entry.date)
            return hour < 8
        }.count
        updateProgress(achievements: achievements, id: "early_bird", progress: earlyCount, modelContext: modelContext)
        
        // Night owl count (after 10 PM)
        let nightCount = entries.filter { entry in
            let hour = calendar.component(.hour, from: entry.date)
            return hour >= 22
        }.count
        updateProgress(achievements: achievements, id: "night_owl", progress: nightCount, modelContext: modelContext)
        
        // Wordsmith (long transcription - over 500 characters)
        let hasLongEntry = entries.contains { entry in
            (entry.transcription?.count ?? 0) > 500
        }
        if hasLongEntry {
            updateProgress(achievements: achievements, id: "wordsmith", progress: 1, modelContext: modelContext)
        }
        
        // Comeback Kid: Restart a streak after missing a day
        // We detect this by finding a gap in journaling days followed by a new entry
        checkComebackKid(achievements: achievements, entries: entries, calendar: calendar, modelContext: modelContext)
    }
    
    /// Checks if user has ever restarted a streak after missing at least one day
    private func checkComebackKid(achievements: [Achievement], entries: [EmotionEntry], calendar: Calendar, modelContext: ModelContext) {
        guard entries.count >= 2 else { return }
        
        // Get unique journaling days sorted by date (newest first)
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        let sortedDays = uniqueDays.sorted(by: >)
        
        // Look for a gap of at least 1 day between consecutive journaling days
        // If we find a gap AND there's an entry after the gap, user "came back"
        for i in 0..<(sortedDays.count - 1) {
            let newerDay = sortedDays[i]
            let olderDay = sortedDays[i + 1]
            
            // Calculate days between
            if let daysBetween = calendar.dateComponents([.day], from: olderDay, to: newerDay).day,
               daysBetween >= 2 { // Gap of 2+ means they missed at least 1 day
                // Found a comeback! User journaled, missed day(s), then journaled again
                updateProgress(achievements: achievements, id: "comeback_kid", progress: 1, modelContext: modelContext)
                return // Only need to find one instance
            }
        }
    }
    
    /// Increment shake celebration count
    func incrementShakeCelebration(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Achievement>()
        
        do {
            let achievements = try modelContext.fetch(descriptor)
            guard let achievement = achievements.first(where: { $0.id == "shake_master" }) else { return }
            
            if !achievement.isUnlocked {
                achievement.progress += 1
                
                if achievement.progress >= achievement.targetProgress {
                    unlockAchievement(achievement, modelContext: modelContext)
                }
                
                try modelContext.save()
            }
        } catch {
        }
    }
    
    // MARK: - Progress Updates
    
    private func updateProgress(achievements: [Achievement], id: String, progress: Int, modelContext: ModelContext) {
        guard let achievement = achievements.first(where: { $0.id == id }) else { return }
        
        // Critical check - skip if already unlocked
        if achievement.isUnlocked { return }
        
        // Update progress
        achievement.progress = max(achievement.progress, progress)
        
        // Check if should unlock
        if achievement.progress >= achievement.targetProgress {
            unlockAchievement(achievement, modelContext: modelContext)
        }
    }
    
    private func unlockAchievement(_ achievement: Achievement, modelContext: ModelContext) {
        // Double-check it's not already unlocked
        guard !achievement.isUnlocked else { return }
        
        achievement.isUnlocked = true
        achievement.unlockedDate = Date()
        achievement.progress = achievement.targetProgress
        
        // Trigger celebration
        Theme.Haptics.success()
        
        // Show unlock animation and badge
        recentlyUnlockedAchievement = achievement
        showUnlockAnimation = true
        hasUnseenUnlock = true
        
}
    
    // MARK: - Helpers
    
    func dismissUnlockAnimation() {
        // Show floating coin before clearing the achievement
        if let achievement = recentlyUnlockedAchievement {
            FloatingCoinManager.shared.showCoin(for: achievement)
        }
        
        showUnlockAnimation = false
        recentlyUnlockedAchievement = nil
        
        // Trigger the callback if it exists
        onAchievementDismissed?()
        onAchievementDismissed = nil // Clear the callback after use
    }
    
    func markAchievementsAsSeen() {
        hasUnseenUnlock = false
    }
    
    /// Get achievement statistics
    func getStats(from achievements: [Achievement]) -> (unlocked: Int, total: Int, percentage: Double) {
        let unlocked = achievements.filter { $0.isUnlocked }.count
        let total = achievements.count
        let percentage = total > 0 ? Double(unlocked) / Double(total) : 0
        return (unlocked, total, percentage)
    }
}

// MARK: - Notification for Achievement Checks

extension Notification.Name {
    static let checkAchievements = Notification.Name("checkAchievements")
}

