import Foundation

struct BreathingPattern: Identifiable, Hashable {
    let id: UUID
    let name: String
    let shortName: String // For compact UI like segmented controls
    let inhale: Int // seconds
    let hold1: Int // seconds (after inhale)
    let exhale: Int // seconds
    let hold2: Int // seconds (after exhale)
    let description: String
    let totalCycleTime: Int // Total time for one complete cycle

    init(
        id: UUID = UUID(),
        name: String,
        shortName: String? = nil,
        inhale: Int,
        hold1: Int = 0,
        exhale: Int,
        hold2: Int = 0,
        description: String
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName ?? name
        self.inhale = inhale
        self.hold1 = hold1
        self.exhale = exhale
        self.hold2 = hold2
        self.description = description
        self.totalCycleTime = inhale + hold1 + exhale + hold2
    }
}

// Predefined breathing patterns
extension BreathingPattern {
    static let boxBreathing = BreathingPattern(
        name: "Box Breathing",
        shortName: "Box",
        inhale: 4,
        hold1: 4,
        exhale: 4,
        hold2: 4,
        description: "Equal 4-count sides; great for steadying anxiety and grounding quickly"
    )

    static let relaxingBreath = BreathingPattern(
        name: "4-7-8 Breath",
        shortName: "4-7-8",
        inhale: 4,
        hold1: 7,
        exhale: 8,
        description: "Long exhale to wind down and prepare for sleep"
    )

    static let coherentBreathing = BreathingPattern(
        name: "Coherent Breathing",
        shortName: "Coherent",
        inhale: 5,
        hold1: 0,
        exhale: 5,
        hold2: 0,
        description: "Smooth 5–5 rhythm; balances energy and eases stress"
    )

    static let calmingBreath = BreathingPattern(
        name: "Calming Breath",
        shortName: "Calm",
        inhale: 3,
        hold1: 3,
        exhale: 6,
        hold2: 0,
        description: "Short inhale, long exhale; releases tension quickly"
    )

    static let allPatterns: [BreathingPattern] = [
        boxBreathing,
        relaxingBreath,
        coherentBreathing,
        calmingBreath
    ]
}
