//
//  GrowingTree.swift
//  pocket-garden
//
//  Model for tracking a growing tree's progress
//

import Foundation
import SwiftData

@Model
final class GrowingTree {
    var id: UUID
    var plantedDate: Date
    var lastWateredDate: Date?
    var waterCount: Int
    var treeType: String
    var isFullyGrown: Bool
    var position: GrowingTreePosition
    
    init(
        id: UUID = UUID(),
        plantedDate: Date = Date(),
        lastWateredDate: Date? = nil,
        waterCount: Int = 0,
        treeType: String = "oak",
        isFullyGrown: Bool = false,
        position: GrowingTreePosition = GrowingTreePosition(x: 0, y: 0)
    ) {
        self.id = id
        self.plantedDate = plantedDate
        self.lastWateredDate = lastWateredDate
        self.waterCount = waterCount
        self.treeType = treeType
        self.isFullyGrown = isFullyGrown
        self.position = position
    }
    
    /// Days required to fully grow this tree type
    var daysToGrow: Int {
        switch treeType {
        case "oak": return 7
        case "pine": return 10
        case "cherry": return 14
        default: return 7
        }
    }
    
    /// Current growth stage (0-5)
    var growthStage: Int {
        let progress = min(waterCount, daysToGrow)
        let stagesCount = 6 // seed, sprout, sapling, young, mature, full
        return Int((Double(progress) / Double(daysToGrow)) * Double(stagesCount - 1))
    }
    
    /// Growth progress percentage (0-1)
    var growthProgress: Double {
        return min(Double(waterCount) / Double(daysToGrow), 1.0)
    }
    
    /// Can be watered today
    func canWaterToday() -> Bool {
        guard let lastWatered = lastWateredDate else { return true }
        return !Calendar.current.isDateInToday(lastWatered)
    }
    
    /// Water the tree
    func water() {
        guard canWaterToday() else { return }
        waterCount += 1
        lastWateredDate = Date()
        
        if waterCount >= daysToGrow {
            isFullyGrown = true
        }
    }
}

/// Position in the 2D forest grid
struct GrowingTreePosition: Codable, Sendable {
    var x: Double
    var y: Double
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// Tree type with visual characteristics
enum TreeType: String, CaseIterable {
    case oak = "oak"
    case pine = "pine"
    case cherry = "cherry"
    
    var name: String {
        switch self {
        case .oak: return "Oak Tree"
        case .pine: return "Pine Tree"
        case .cherry: return "Cherry Tree"
        }
    }
    
    var daysToGrow: Int {
        switch self {
        case .oak: return 7
        case .pine: return 10
        case .cherry: return 14
        }
    }
    
    var description: String {
        switch self {
        case .oak: return "Strong and steady, grows in 7 days"
        case .pine: return "Tall and resilient, grows in 10 days"
        case .cherry: return "Beautiful and patient, grows in 14 days"
        }
    }
    
    var emoji: String {
        switch self {
        case .oak: return "🌳"
        case .pine: return "🌲"
        case .cherry: return "🌸"
        }
    }
    
    /// Get emoji for growth stage
    func emojiForStage(_ stage: Int) -> String {
        switch stage {
        case 0: return "🌱" // seed
        case 1: return "🌿" // sprout
        case 2: return "🪴" // sapling
        case 3: return "🌳" // young tree
        case 4: return emoji // mature
        case 5: return emoji // fully grown
        default: return "🌱"
        }
    }
}
