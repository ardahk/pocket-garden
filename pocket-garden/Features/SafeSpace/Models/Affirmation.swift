import Foundation

struct Affirmation: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let category: AffirmationCategory

    init(id: UUID = UUID(), text: String, category: AffirmationCategory) {
        self.id = id
        self.text = text
        self.category = category
    }
}

enum AffirmationCategory: String, Codable, CaseIterable {
    case safety = "Safety"
    case strength = "Strength"
    case peace = "Peace"
    case selfCompassion = "Self-Compassion"
    case present = "Present Moment"
    case resilience = "Resilience"
}

// Predefined affirmations for Phase 1
extension Affirmation {
    static let defaultAffirmations: [Affirmation] = [
        // Safety
        Affirmation(text: "I am safe right now, in this moment", category: .safety),
        Affirmation(text: "This feeling will pass, like clouds in the sky", category: .safety),
        Affirmation(text: "I am exactly where I need to be", category: .safety),
        Affirmation(text: "I am grounded and secure", category: .safety),

        // Strength
        Affirmation(text: "I am stronger than my anxiety", category: .strength),
        Affirmation(text: "I have overcome challenges before, and I will again", category: .strength),
        Affirmation(text: "My resilience grows with each breath", category: .strength),
        Affirmation(text: "I trust in my ability to handle whatever comes", category: .strength),

        // Peace
        Affirmation(text: "I deserve peace and calm", category: .peace),
        Affirmation(text: "With each breath, I release tension", category: .peace),
        Affirmation(text: "I choose peace over worry", category: .peace),
        Affirmation(text: "Calm is always available to me", category: .peace),

        // Self-Compassion
        Affirmation(text: "I am worthy of love and kindness", category: .selfCompassion),
        Affirmation(text: "I treat myself with gentleness", category: .selfCompassion),
        Affirmation(text: "It's okay to not be okay sometimes", category: .selfCompassion),
        Affirmation(text: "I am doing the best I can, and that is enough", category: .selfCompassion),

        // Present Moment
        Affirmation(text: "I am here, right now, and that is all that matters", category: .present),
        Affirmation(text: "This moment is a fresh start", category: .present),
        Affirmation(text: "I release what I cannot control", category: .present),
        Affirmation(text: "The present moment is where my power lives", category: .present),

        // Resilience
        Affirmation(text: "I am growing through what I'm going through", category: .resilience),
        Affirmation(text: "Every challenge makes me wiser", category: .resilience),
        Affirmation(text: "I bend but I do not break", category: .resilience),
        Affirmation(text: "My courage is greater than my fear", category: .resilience)
    ]
}
