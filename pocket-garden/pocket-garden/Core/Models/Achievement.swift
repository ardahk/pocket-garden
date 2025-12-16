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
    var symbolName: String
    /// Backing store for symbol rendering style
    var symbolStyleName: String
    /// Optional palette/multicolor values stored as named colors
    var symbolColorsHex: [String]?
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
        symbolName: String,
        symbolStyle: SymbolRenderingMode = .hierarchical,
        symbolColors: [String]? = nil,
        targetProgress: Int,
        category: String,
        rarity: AchievementRarity = .common
    ) {
        self.id = id
        self.title = title
        self.achievementDescription = description
        self.symbolName = symbolName
        self.symbolStyleName = Achievement.storeValue(for: symbolStyle)
        self.symbolColorsHex = symbolColors
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

    var symbolStyle: SymbolRenderingMode {
        Achievement.style(from: symbolStyleName)
    }

    var paletteColors: [Color]? {
        guard let hex = symbolColorsHex else { return nil }
        return hex.compactMap { Achievement.color(from: $0) }
    }

    var raritySortValue: Int {
        switch rarity {
        case .common: return 0
        case .rare: return 1
        case .epic: return 2
        case .legendary: return 3
        }
    }

    func unlock() {
        isUnlocked = true
        unlockedDate = Date()
        progress = targetProgress
    }
}

// MARK: - Achievement Rarity

enum AchievementRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary

    var color: Color {
        switch self {
        case .common: return .primaryGreen
        case .rare: return .accentGold
        case .epic: return .emotionContent
        case .legendary: return Color(red: 1.0, green: 0.4, blue: 0.6) // Rose gold
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .common:
            return [.primaryGreen.opacity(0.8), .primaryGreen]
        case .rare:
            return [Color(red: 1.0, green: 0.85, blue: 0.3), .accentGold]
        case .epic:
            return [Color(red: 0.6, green: 0.4, blue: 0.9), .emotionContent]
        case .legendary:
            return [
                Color(red: 1.0, green: 0.4, blue: 0.6),
                Color(red: 1.0, green: 0.6, blue: 0.3),
                Color(red: 1.0, green: 0.85, blue: 0.3)
            ]
        }
    }

    var name: String {
        rawValue.capitalized
    }
    
    var animationDuration: Double {
        switch self {
        case .common: return 0.5
        case .rare: return 1.0
        case .epic: return 1.5
        case .legendary: return 2.0
        }
    }
}

// MARK: - Achievement Category

enum AchievementCategory: String, CaseIterable {
    case streaks = "Streaks"
    case entries = "Entries"
    case garden = "Garden"
    case wellness = "Wellness"
    case special = "Special"
    
    var icon: String {
        switch self {
        case .streaks: return "flame.fill"
        case .entries: return "book.fill"
        case .garden: return "leaf.fill"
        case .wellness: return "heart.fill"
        case .special: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .streaks: return .accentGold
        case .entries: return .primaryGreen
        case .garden: return .emotionContent
        case .wellness: return .emotionCalm
        case .special: return .secondaryTerracotta
        }
    }
}

// MARK: - Achievement Definitions

extension Achievement {
    static func createDefaultAchievements() -> [Achievement] {
        [
            // MARK: First Entry (onboarding milestone)
            Achievement(
                id: "entry_1",
                title: "First Step",
                description: "Create your first journal entry",
                symbolName: "sparkles",
                symbolStyle: .hierarchical,
                targetProgress: 1,
                category: "Entries",
                rarity: .common
            ),

            // MARK: Streak Achievements
            Achievement(
                id: "streak_3",
                title: "Getting Started",
                description: "Maintain a 3-day streak",
                symbolName: "leaf.fill",
                symbolStyle: .hierarchical,
                targetProgress: 3,
                category: "Streaks",
                rarity: .common
            ),
            Achievement(
                id: "streak_7",
                title: "Week Warrior",
                description: "Maintain a 7-day streak",
                symbolName: "flame.fill",
                symbolStyle: .hierarchical,
                targetProgress: 7,
                category: "Streaks",
                rarity: .common
            ),
            Achievement(
                id: "streak_30",
                title: "Monthly Master",
                description: "Maintain a 30-day streak",
                symbolName: "star.fill",
                symbolStyle: .palette,
                symbolColors: ["gold", "violet"],
                targetProgress: 30,
                category: "Streaks",
                rarity: .legendary
            ),
            Achievement(
                id: "streak_100",
                title: "Century Club",
                description: "Maintain a 100-day streak",
                symbolName: "crown.fill",
                symbolStyle: .palette,
                symbolColors: ["gold", "rose", "amber"],
                targetProgress: 100,
                category: "Streaks",
                rarity: .legendary
            ),

            Achievement(
                id: "streak_14",
                title: "Two-Week Wonder",
                description: "Maintain a 14-day streak",
                symbolName: "calendar.badge.clock",
                symbolStyle: .hierarchical,
                targetProgress: 14,
                category: "Streaks",
                rarity: .epic
            ),

            // MARK: Total Entries
            Achievement(
                id: "entries_10",
                title: "Budding Writer",
                description: "Create 10 journal entries",
                symbolName: "pencil.circle.fill",
                symbolStyle: .hierarchical,
                targetProgress: 10,
                category: "Entries",
                rarity: .common
            ),
            Achievement(
                id: "entries_50",
                title: "Journaling Pro",
                description: "Create 50 journal entries",
                symbolName: "book.closed.fill",
                symbolStyle: .hierarchical,
                targetProgress: 50,
                category: "Entries",
                rarity: .epic
            ),
            Achievement(
                id: "entries_100",
                title: "Memoir Master",
                description: "Create 100 journal entries",
                symbolName: "trophy.fill",
                symbolStyle: .palette,
                symbolColors: ["gold", "amber"],
                targetProgress: 100,
                category: "Entries",
                rarity: .epic
            ),
            Achievement(
                id: "entries_25",
                title: "Habit Builder",
                description: "Create 25 journal entries",
                symbolName: "pencil.and.outline",
                symbolStyle: .hierarchical,
                targetProgress: 25,
                category: "Entries",
                rarity: .common
            ),
            Achievement(
                id: "entries_200",
                title: "Life Chronicler",
                description: "Create 200 journal entries",
                symbolName: "books.vertical.fill",
                symbolStyle: .palette,
                symbolColors: ["mint", "emerald"],
                targetProgress: 200,
                category: "Entries",
                rarity: .legendary
            ),

            // MARK: Garden Growth
            Achievement(
                id: "trees_5",
                title: "Budding Gardener",
                description: "Grow 5 trees in your garden",
                symbolName: "leaf.circle.fill",
                symbolStyle: .hierarchical,
                targetProgress: 5,
                category: "Garden",
                rarity: .common
            ),
            Achievement(
                id: "trees_20",
                title: "Small Forest",
                description: "Grow 20 trees in your garden",
                symbolName: "tree.fill",
                symbolStyle: .hierarchical,
                targetProgress: 20,
                category: "Garden",
                rarity: .common
            ),
            Achievement(
                id: "trees_50",
                title: "Mighty Forest",
                description: "Grow 50 trees in your garden",
                symbolName: "sparkles",
                symbolStyle: .palette,
                symbolColors: ["mint", "emerald"],
                targetProgress: 50,
                category: "Garden",
                rarity: .epic
            ),
            Achievement(
                id: "bloom_10",
                title: "Master Gardener",
                description: "Grow 10 cherry blossom trees",
                symbolName: "camera.macro",
                symbolStyle: .palette,
                symbolColors: ["pink", "rose"],
                targetProgress: 10,
                category: "Garden",
                rarity: .epic
            ),
            Achievement(
                id: "garden_10",
                title: "Garden Glow-Up",
                description: "Grow 10 trees in your garden",
                symbolName: "sparkle.magnifyingglass",
                symbolStyle: .palette,
                symbolColors: ["mint", "gold"],
                targetProgress: 10,
                category: "Garden",
                rarity: .rare
            ),

            // MARK: Emotional Wellness
            Achievement(
                id: "positive_streak_5",
                title: "Positive Vibes",
                description: "Log 5 consecutive positive entries (8+)",
                symbolName: "face.smiling.fill",
                symbolStyle: .palette,
                symbolColors: ["gold", "mint"],
                targetProgress: 5,
                category: "Wellness",
                rarity: .rare
            ),
            Achievement(
                id: "growth_journey",
                title: "Growth Mindset",
                description: "Improve average rating by 2 points",
                symbolName: "chart.line.uptrend.xyaxis",
                symbolStyle: .hierarchical,
                targetProgress: 2,
                category: "Wellness",
                rarity: .legendary
            ),
            Achievement(
                id: "reflection_7",
                title: "Thoughtful Week",
                description: "Journal 7 days in a row",
                symbolName: "brain.head.profile",
                symbolStyle: .hierarchical,
                targetProgress: 7,
                category: "Wellness",
                rarity: .common
            ),
            Achievement(
                id: "mindful_moments",
                title: "Mindful Moments",
                description: "Journal 5 times in a single week",
                symbolName: "calendar.badge.checkmark",
                symbolStyle: .hierarchical,
                targetProgress: 5,
                category: "Wellness",
                rarity: .common
            ),

            // MARK: Special Achievements
            Achievement(
                id: "early_bird",
                title: "Early Bird",
                description: "Journal before 8 AM 10 times",
                symbolName: "sunrise.fill",
                symbolStyle: .palette,
                symbolColors: ["amber", "rose"],
                targetProgress: 10,
                category: "Special",
                rarity: .rare
            ),
            Achievement(
                id: "night_owl",
                title: "Night Owl",
                description: "Journal after 10 PM 10 times",
                symbolName: "moon.stars.fill",
                symbolStyle: .palette,
                symbolColors: ["indigo", "violet"],
                targetProgress: 10,
                category: "Special",
                rarity: .rare
            ),
            Achievement(
                id: "wordsmith",
                title: "Wordsmith",
                description: "Write a journal entry over 500 characters",
                symbolName: "text.book.closed.fill",
                symbolStyle: .hierarchical,
                targetProgress: 1,
                category: "Special",
                rarity: .epic
            ),
            Achievement(
                id: "shake_master",
                title: "Celebration Expert",
                description: "Trigger garden celebration 25 times",
                symbolName: "party.popper.fill",
                symbolStyle: .palette,
                symbolColors: ["gold", "mint", "rose"],
                targetProgress: 25,
                category: "Special",
                rarity: .rare
            ),
            Achievement(
                id: "comeback_kid",
                title: "Comeback Kid",
                description: "Restart a streak after missing a day",
                symbolName: "arrow.uturn.backward.circle.fill",
                symbolStyle: .hierarchical,
                targetProgress: 1,
                category: "Special",
                rarity: .common
            )
        ]
    }
}

// MARK: - Helpers

extension Achievement {
    private static func storeValue(for mode: SymbolRenderingMode) -> String {
        // SymbolRenderingMode is not Equatable; use description to persist
        return String(describing: mode).lowercased()
    }

    private static func style(from name: String) -> SymbolRenderingMode {
        switch name.lowercased() {
        case "palette": return .palette
        case "multicolor": return .multicolor
        case "monochrome": return .monochrome
        default: return .hierarchical
        }
    }

    private static func color(from name: String) -> Color? {
        switch name.lowercased() {
        case "gold": return Color(red: 1.0, green: 0.85, blue: 0.3)
        case "amber": return Color(red: 1.0, green: 0.75, blue: 0.25)
        case "rose": return Color(red: 1.0, green: 0.4, blue: 0.6)
        case "violet": return Color(red: 0.6, green: 0.4, blue: 0.9)
        case "mint": return Color(red: 0.6, green: 0.9, blue: 0.7)
        case "emerald": return Color(red: 0.2, green: 0.6, blue: 0.4)
        case "pink": return Color(red: 1.0, green: 0.65, blue: 0.75)
        case "indigo": return Color(red: 0.35, green: 0.35, blue: 0.8)
        default:
            return nil
        }
    }
}
