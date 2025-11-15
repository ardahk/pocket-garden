import Foundation
import SwiftUI

struct CalmActivity: Identifiable, Hashable {
    let id: UUID
    let title: String
    let icon: String
    let duration: Int // minutes
    let description: String
    let color: Color
    let type: ActivityType

    init(
        id: UUID = UUID(),
        title: String,
        icon: String,
        duration: Int,
        description: String,
        color: Color,
        type: ActivityType
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.duration = duration
        self.description = description
        self.color = color
        self.type = type
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case breathing = "Breathing"
    case grounding = "Grounding"
    case bodyScan = "Body Scan"
    case affirmations = "Affirmations"
    case visualization = "Visualization"
    case colorBreathing = "Color Breathing"
    case worryTree = "Worry Tree"
    case butterflyHug = "Butterfly Hug"
}

// Predefined activities for Phase 1
extension CalmActivity {
    static let breathingExercise = CalmActivity(
        title: "Breathing Exercise",
        icon: "wind",
        duration: 2,
        description: "Guided breathing to calm your mind",
        color: .blue.opacity(0.7),
        type: .breathing
    )

    static let groundingTechnique = CalmActivity(
        title: "Grounding Technique",
        icon: "leaf.fill",
        duration: 3,
        description: "5-4-3-2-1 sensory awareness",
        color: .green.opacity(0.7),
        type: .grounding
    )

    static let bodyScan = CalmActivity(
        title: "Body Scan",
        icon: "figure.mind.and.body",
        duration: 3,
        description: "Progressive muscle relaxation",
        color: .purple.opacity(0.7),
        type: .bodyScan
    )

    static let gentleAffirmations = CalmActivity(
        title: "Gentle Affirmations",
        icon: "heart.fill",
        duration: 2,
        description: "Positive self-compassion messages",
        color: .pink.opacity(0.7),
        type: .affirmations
    )

    static let allActivities: [CalmActivity] = [
        breathingExercise,
        bodyScan,
        groundingTechnique,
        gentleAffirmations
    ]
}
