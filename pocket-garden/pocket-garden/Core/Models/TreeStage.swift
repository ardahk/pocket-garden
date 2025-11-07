//
//  TreeStage.swift
//  pocket-garden
//
//  Tree Growth Stages for Forest Visualization
//

import Foundation

// MARK: - Tree Stage

enum TreeStage: Int, Codable, CaseIterable {
    case seed = 1
    case sprout = 2
    case youngTree = 3
    case matureTree = 4
    case blooming = 5

    var name: String {
        switch self {
        case .seed: return "Seed"
        case .sprout: return "Sprout"
        case .youngTree: return "Young Tree"
        case .matureTree: return "Mature Tree"
        case .blooming: return "Blooming"
        }
    }

    var emoji: String {
        switch self {
        case .seed: return "🌱"
        case .sprout: return "🌿"
        case .youngTree: return "🌳"
        case .matureTree: return "🌲"
        case .blooming: return "🌸"
        }
    }

    var description: String {
        switch self {
        case .seed: return "Just planted - your journey begins"
        case .sprout: return "Starting to grow"
        case .youngTree: return "Building strength"
        case .matureTree: return "Standing tall"
        case .blooming: return "Full of life and beauty"
        }
    }

    /// Calculate tree stage based on total entry count
    static func stage(for entryCount: Int) -> TreeStage {
        switch entryCount {
        case 1...2:
            return .seed
        case 3...5:
            return .sprout
        case 6...10:
            return .youngTree
        case 11...20:
            return .matureTree
        default:
            return .blooming
        }
    }

    /// Get stage from raw value safely
    static func from(rawValue: Int) -> TreeStage {
        TreeStage(rawValue: rawValue) ?? .seed
    }
}
