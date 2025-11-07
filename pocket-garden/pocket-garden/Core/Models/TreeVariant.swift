//
//  TreeVariant.swift
//  pocket-garden
//
//  Rare Tree Variants and Special Trees - Make the garden more exciting!
//

import SwiftUI
import Foundation

// MARK: - Tree Variant

enum TreeVariant: String, Codable, CaseIterable {
    // Common variants (60%)
    case oak = "Oak"
    case maple = "Maple"
    case birch = "Birch"

    // Uncommon variants (25%)
    case cherry = "Cherry Blossom"
    case willow = "Willow"
    case pine = "Pine"

    // Rare variants (10%)
    case sakura = "Sakura"
    case rainbow = "Rainbow Tree"
    case golden = "Golden Tree"

    // Epic variants (4%)
    case crystal = "Crystal Tree"
    case aurora = "Aurora Tree"

    // Legendary variants (1%)
    case cosmic = "Cosmic Tree"
    case phoenix = "Phoenix Tree"

    var rarity: TreeRarity {
        switch self {
        case .oak, .maple, .birch:
            return .common
        case .cherry, .willow, .pine:
            return .uncommon
        case .sakura, .rainbow, .golden:
            return .rare
        case .crystal, .aurora:
            return .epic
        case .cosmic, .phoenix:
            return .legendary
        }
    }

    var emoji: String {
        switch self {
        case .oak: return "🌳"
        case .maple: return "🍁"
        case .birch: return "🌲"
        case .cherry: return "🌸"
        case .willow: return "🌿"
        case .pine: return "🌲"
        case .sakura: return "🌸"
        case .rainbow: return "🌈"
        case .golden: return "✨"
        case .crystal: return "💎"
        case .aurora: return "🌌"
        case .cosmic: return "🌟"
        case .phoenix: return "🔥"
        }
    }

    var description: String {
        switch self {
        case .oak: return "A sturdy and reliable oak tree"
        case .maple: return "A vibrant maple with colorful leaves"
        case .birch: return "A graceful birch tree"
        case .cherry: return "A beautiful cherry blossom tree"
        case .willow: return "A flowing willow tree"
        case .pine: return "An evergreen pine tree"
        case .sakura: return "A rare and elegant sakura tree"
        case .rainbow: return "A magical tree with rainbow colors"
        case .golden: return "A shimmering golden tree"
        case .crystal: return "A crystalline tree that sparkles"
        case .aurora: return "A mystical tree with aurora lights"
        case .cosmic: return "A legendary cosmic tree from the stars"
        case .phoenix: return "A legendary phoenix tree that burns with eternal flame"
        }
    }

    var primaryColor: Color {
        switch self {
        case .oak: return Color(hex: "8B7355")
        case .maple: return Color(hex: "D2691E")
        case .birch: return Color(hex: "F5DEB3")
        case .cherry: return Color(hex: "FFB7C5")
        case .willow: return Color(hex: "98D8C8")
        case .pine: return Color(hex: "2F5233")
        case .sakura: return Color(hex: "FFB7D5")
        case .rainbow: return Color(hex: "FF6B9D")
        case .golden: return Color(hex: "FFD700")
        case .crystal: return Color(hex: "B4E7F0")
        case .aurora: return Color(hex: "A8E6CF")
        case .cosmic: return Color(hex: "9B59B6")
        case .phoenix: return Color(hex: "FF4500")
        }
    }

    var secondaryColor: Color {
        switch self {
        case .oak: return Color(hex: "228B22")
        case .maple: return Color(hex: "FF6347")
        case .birch: return Color(hex: "90EE90")
        case .cherry: return Color(hex: "FFB7C5")
        case .willow: return Color(hex: "7FCDCD")
        case .pine: return Color(hex: "228B22")
        case .sakura: return Color(hex: "FFDDF4")
        case .rainbow: return Color(hex: "FFD93D")
        case .golden: return Color(hex: "FFA500")
        case .crystal: return Color(hex: "E0F7FA")
        case .aurora: return Color(hex: "B4E7F0")
        case .cosmic: return Color(hex: "8E44AD")
        case .phoenix: return Color(hex: "FFA500")
        }
    }

    static func determineVariant(
        emotionRating: Int,
        date: Date,
        isStreak: Bool,
        streakCount: Int,
        totalEntries: Int
    ) -> TreeVariant {
        // Special legendary conditions
        if streakCount >= 100 && emotionRating >= 9 {
            return .cosmic
        }

        if streakCount >= 50 && emotionRating >= 9 && isWeekend(date) {
            return .phoenix
        }

        // Epic conditions
        if streakCount >= 30 && emotionRating >= 9 {
            return Bool.random() ? .crystal : .aurora
        }

        if emotionRating == 10 && isStreak && streakCount >= 7 {
            return Bool.random() ? .crystal : .aurora
        }

        // Rare conditions
        if emotionRating >= 9 && isStreak && streakCount >= 5 {
            return [TreeVariant.sakura, .rainbow, .golden].randomElement()!
        }

        if emotionRating == 10 {
            return [TreeVariant.sakura, .rainbow, .golden].randomElement()!
        }

        if totalEntries > 0 && totalEntries % 25 == 0 {
            return .golden
        }

        // Uncommon conditions
        if emotionRating >= 8 && isStreak {
            return [TreeVariant.cherry, .willow, .pine].randomElement()!
        }

        if isWeekend(date) && emotionRating >= 7 {
            return [TreeVariant.cherry, .willow, .pine].randomElement()!
        }

        // Common trees (default with weighted randomness)
        let commonWeights: [(TreeVariant, Int)] = [
            (.oak, 40),
            (.maple, 35),
            (.birch, 25)
        ]

        let totalWeight = commonWeights.reduce(0) { $0 + $1.1 }
        let random = Int.random(in: 0..<totalWeight)

        var cumulative = 0
        for (variant, weight) in commonWeights {
            cumulative += weight
            if random < cumulative {
                return variant
            }
        }

        return .oak
    }

    private static func isWeekend(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // Sunday or Saturday
    }
}

// MARK: - Tree Rarity

enum TreeRarity: String, Codable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    var color: Color {
        switch self {
        case .common: return .primaryGreen
        case .uncommon: return Color(hex: "4CAF50")
        case .rare: return Color(hex: "2196F3")
        case .epic: return Color(hex: "9C27B0")
        case .legendary: return Color(hex: "FF9800")
        }
    }

    var badgeColor: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return Color(hex: "4CAF50")
        case .rare: return Color(hex: "2196F3")
        case .epic: return Color(hex: "9C27B0")
        case .legendary: return Color(hex: "FFD700")
        }
    }

    var name: String {
        rawValue.capitalized
    }

    var emoji: String {
        switch self {
        case .common: return "🌱"
        case .uncommon: return "🌿"
        case .rare: return "✨"
        case .epic: return "💎"
        case .legendary: return "👑"
        }
    }
}

// MARK: - Extension for EmotionEntry

extension EmotionEntry {
    var treeVariant: TreeVariant {
        // Determine tree variant based on multiple factors
        let calendar = Calendar.current
        let allEntries = 1 // This should be injected from context
        let isInStreak = true // This should be calculated from context

        return TreeVariant.determineVariant(
            emotionRating: emotionRating,
            date: date,
            isStreak: isInStreak,
            streakCount: 1, // Should be calculated
            totalEntries: allEntries
        )
    }

    func determinedTreeVariant(totalEntries: Int, streakCount: Int, isInStreak: Bool) -> TreeVariant {
        return TreeVariant.determineVariant(
            emotionRating: emotionRating,
            date: date,
            isStreak: isInStreak,
            streakCount: streakCount,
            totalEntries: totalEntries
        )
    }
}

// MARK: - Tree Collection Stats

struct TreeCollection {
    let entries: [EmotionEntry]
    let totalEntries: Int
    let streakCount: Int

    var variantCounts: [TreeVariant: Int] {
        var counts: [TreeVariant: Int] = [:]

        for (index, entry) in entries.enumerated() {
            let isInStreak = index < streakCount
            let variant = entry.determinedTreeVariant(
                totalEntries: totalEntries,
                streakCount: streakCount,
                isInStreak: isInStreak
            )
            counts[variant, default: 0] += 1
        }

        return counts
    }

    var rarityCounts: [TreeRarity: Int] {
        var counts: [TreeRarity: Int] = [:]

        for variant in variantCounts.keys {
            let count = variantCounts[variant] ?? 0
            counts[variant.rarity, default: 0] += count
        }

        return counts
    }

    var rarest: TreeVariant? {
        variantCounts
            .filter { $0.value > 0 }
            .max { lhs, rhs in
                // Compare by rarity value
                let rarityOrder: [TreeRarity: Int] = [
                    .common: 1,
                    .uncommon: 2,
                    .rare: 3,
                    .epic: 4,
                    .legendary: 5
                ]

                let lhsValue = rarityOrder[lhs.key.rarity] ?? 0
                let rhsValue = rarityOrder[rhs.key.rarity] ?? 0

                return lhsValue < rhsValue
            }?
            .key
    }

    var collectionCompletion: Double {
        let uniqueVariants = Set(variantCounts.keys).count
        let totalVariants = TreeVariant.allCases.count
        return Double(uniqueVariants) / Double(totalVariants)
    }
}
