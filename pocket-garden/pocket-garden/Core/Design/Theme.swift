//
//  Theme.swift
//  pocket-garden
//
//  Design System - Theme Manager
//

import SwiftUI

// MARK: - App Theme

class Theme {
    static let shared = Theme()

    private init() {}

    // MARK: - Color Palette

    struct Colors {
        static let primary = Color.primaryGreen
        static let secondary = Color.secondaryTerracotta
        static let background = Color.backgroundCream
        static let accent = Color.accentGold
        static let textPrimary = Color.textPrimary
        static let textSecondary = Color.textSecondary
    }

    // MARK: - Animation Durations

    struct Animation {
        /// Quick animation (0.2s)
        static let quick: Double = 0.2

        /// Standard animation (0.3s)
        static let standard: Double = 0.3

        /// Slow animation (0.5s)
        static let slow: Double = 0.5

        /// Spring animation preset
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)

        /// Gentle spring
        static let gentleSpring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)

        /// Bouncy spring
        static let bouncySpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)

        /// Smooth easing
        static let smooth = SwiftUI.Animation.easeInOut(duration: standard)
    }

    // MARK: - Haptic Feedback

    struct Haptics {
        /// Light impact feedback
        static func light() {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }

        /// Medium impact feedback
        static func medium() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }

        /// Heavy impact feedback
        static func heavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }

        /// Selection feedback
        static func selection() {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }

        /// Success notification
        static func success() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }

        /// Error notification
        static func error() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }

        /// Warning notification
        static func warning() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
}

// MARK: - Emotion Helpers

extension Theme {
    /// Get emoji for emotion rating (1-10)
    static func emoji(for rating: Int) -> String {
        switch rating {
        case 10: return "😊"
        case 9: return "😄"
        case 8: return "🙂"
        case 7: return "😌"
        case 6: return "😐"
        case 5: return "😶"
        case 4: return "😔"
        case 3: return "😞"
        case 2: return "😢"
        case 1: return "😭"
        default: return "🙂"
        }
    }

    /// Get emotion label for rating
    static func emotionLabel(for rating: Int) -> String {
        switch rating {
        case 9...10: return "Amazing"
        case 7...8: return "Great"
        case 5...6: return "Okay"
        case 3...4: return "Not Good"
        case 1...2: return "Difficult"
        default: return "Neutral"
        }
    }

    /// Get color for emotion rating
    static func color(for rating: Int) -> Color {
        return Color.emotionColor(for: rating)
    }
}
