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
    case worryTree = "Worry Tree"
    case butterflyHug = "Butterfly Hug"
    case nameAndSoothe = "Name & Soothe"
    case lovingKindness = "Loving Kindness"
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

    static let worryTree = CalmActivity(
        title: "Worry Tree",
        icon: "arrow.up.bin.fill",
        duration: 5,
        description: "Guide your worries to a solution",
        color: .orange.opacity(0.7),
        type: .worryTree
    )

    static let butterflyHug = CalmActivity(
        title: "Butterfly Hug",
        icon: "hands.clap.fill",
        duration: 2,
        description: "Bilateral stimulation for calm",
        color: .indigo.opacity(0.7),
        type: .butterflyHug
    )

    static let visualization = CalmActivity(
        title: "Safe Place",
        icon: "mountain.2.fill",
        duration: 4,
        description: "Visualize your peaceful sanctuary",
        color: .teal.opacity(0.7),
        type: .visualization
    )

    static let nameAndSoothe = CalmActivity(
        title: "Name & Soothe",
        icon: "sparkles",
        duration: 3,
        description: "Label your feelings and respond with kindness",
        color: .mint.opacity(0.7),
        type: .nameAndSoothe
    )

    static let allActivities: [CalmActivity] = [
        breathingExercise,
        groundingTechnique,
        bodyScan,
        gentleAffirmations,
        worryTree,
        butterflyHug,
        visualization,
        nameAndSoothe
    ]
}
