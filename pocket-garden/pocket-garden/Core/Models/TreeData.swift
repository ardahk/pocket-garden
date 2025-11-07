//
//  TreeData.swift
//  pocket-garden
//
//  Model - Tree Visualization Data
//

import Foundation
import SwiftUI

// MARK: - Tree Stage

enum TreeStage: Int, CaseIterable, Identifiable {
    case seed = 1
    case sprout = 2
    case youngTree = 3
    case matureTree = 4
    case bloomingTree = 5

    var id: Int { rawValue }

    /// Display name for the stage
    var name: String {
        switch self {
        case .seed: return "Seed"
        case .sprout: return "Sprout"
        case .youngTree: return "Young Tree"
        case .matureTree: return "Mature Tree"
        case .bloomingTree: return "Blooming Tree"
        }
    }

    /// Emoji representation
    var emoji: String {
        switch self {
        case .seed: return "🌱"
        case .sprout: return "🌿"
        case .youngTree: return "🌳"
        case .matureTree: return "🌲"
        case .bloomingTree: return "🌸"
        }
    }

    /// Description of the stage
    var description: String {
        switch self {
        case .seed:
            return "Just planted, full of potential"
        case .sprout:
            return "Starting to grow and break through"
        case .youngTree:
            return "Developing strength and roots"
        case .matureTree:
            return "Standing tall and strong"
        case .bloomingTree:
            return "Flourishing with beauty and wisdom"
        }
    }

    /// Relative height multiplier (0.0 - 1.0)
    var heightMultiplier: CGFloat {
        switch self {
        case .seed: return 0.2
        case .sprout: return 0.4
        case .youngTree: return 0.6
        case .matureTree: return 0.85
        case .bloomingTree: return 1.0
        }
    }

    /// Number of blossoms/decorations
    func blossomCount(emotionRating: Int) -> Int {
        guard self == .bloomingTree else { return 0 }

        switch emotionRating {
        case 9...10: return 8
        case 7...8: return 5
        case 5...6: return 3
        default: return 1
        }
    }

    /// Get stage from entry count
    static func from(entryCount: Int) -> TreeStage {
        switch entryCount {
        case 1...2: return .seed
        case 3...5: return .sprout
        case 6...10: return .youngTree
        case 11...20: return .matureTree
        default: return .bloomingTree
        }
    }
}

// MARK: - Forest Weather

enum ForestWeather: CaseIterable {
    case sunny
    case partlyCloudy
    case cloudy
    case rainy

    /// Display name
    var name: String {
        switch self {
        case .sunny: return "Sunny"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .rainy: return "Rainy"
        }
    }

    /// Emoji representation
    var emoji: String {
        switch self {
        case .sunny: return "☀️"
        case .partlyCloudy: return "⛅"
        case .cloudy: return "☁️"
        case .rainy: return "🌧️"
        }
    }

    /// Sky gradient colors
    var skyGradient: [Color] {
        switch self {
        case .sunny:
            return [Color(hex: "87CEEB"), Color(hex: "E0F6FF")]
        case .partlyCloudy:
            return [Color(hex: "B0C4DE"), Color(hex: "E6F0F5")]
        case .cloudy:
            return [Color(hex: "8B9DC3"), Color(hex: "C9D6E8")]
        case .rainy:
            return [Color(hex: "778899"), Color(hex: "B0C4DE")]
        }
    }

    /// Determine weather based on recent emotion ratings
    static func from(recentRatings: [Int]) -> ForestWeather {
        guard !recentRatings.isEmpty else { return .partlyCloudy }

        let average = Double(recentRatings.reduce(0, +)) / Double(recentRatings.count)

        switch average {
        case 8...10: return .sunny
        case 6..<8: return .partlyCloudy
        case 4..<6: return .cloudy
        default: return .rainy
        }
    }
}

// MARK: - Tree Position

struct TreePosition {
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat // Depth perception (0.7 - 1.0)

    /// Create organic, non-grid positioning
    static func generatePositions(count: Int, containerWidth: CGFloat) -> [TreePosition] {
        var positions: [TreePosition] = []
        let spacing: CGFloat = 120

        for i in 0..<count {
            // Base position with spacing
            let baseX = CGFloat(i) * spacing + 60

            // Add some organic variation
            let xVariation = CGFloat.random(in: -20...20)
            let yVariation = CGFloat.random(in: -30...30)
            let scale = CGFloat.random(in: 0.8...1.0)

            let position = TreePosition(
                x: baseX + xVariation,
                y: yVariation,
                scale: scale
            )
            positions.append(position)
        }

        return positions
    }
}
