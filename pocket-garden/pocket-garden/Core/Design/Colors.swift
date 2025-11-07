//
//  Colors.swift
//  pocket-garden
//
//  Design System - Color Palette
//

import SwiftUI

extension Color {
    // MARK: - Primary Colors (Natural Growth Theme)

    /// Soft sage green - Primary brand color
    static let primaryGreen = Color(hex: "A8C69F")

    /// Warm terracotta - Secondary brand color
    static let secondaryTerracotta = Color(hex: "E5A888")

    /// Cream white - Background color
    static let backgroundCream = Color(hex: "FAF8F3")

    /// Golden yellow - Accent color
    static let accentGold = Color(hex: "F4D06F")

    // MARK: - Emotion-Based Colors

    /// Joy & Happiness (8-10 rating)
    static let emotionJoy = Color(hex: "FFD93D")

    /// Contentment (6-7 rating)
    static let emotionContent = Color(hex: "A8E6CF")

    /// Neutral (5 rating)
    static let emotionNeutral = Color(hex: "C8D6E5")

    /// Melancholy (3-4 rating)
    static let emotionMelancholy = Color(hex: "B4A5D5")

    /// Sadness (1-2 rating)
    static let emotionSad = Color(hex: "8FA2C0")

    /// Calm & Peace (mindfulness, meditation)
    static let emotionCalm = Color(hex: "B8E6E1")

    /// Anxious & Stressed (worry, tension)
    static let emotionAnxious = Color(hex: "F8C4B4")

    // MARK: - UI Colors

    /// Card background with slight tint
    static let cardBackground = Color.white.opacity(0.95)

    /// Subtle shadow color
    static let shadowColor = Color.black.opacity(0.08)

    /// Border color for inputs
    static let borderColor = Color.gray.opacity(0.2)

    /// Text primary
    static let textPrimary = Color(hex: "2D3436")

    /// Text secondary
    static let textSecondary = Color(hex: "636E72")

    /// Success green
    static let successGreen = Color(hex: "00B894")

    /// Error red
    static let errorRed = Color(hex: "FF7675")

    // MARK: - Gradient Colors

    /// Peaceful gradient for backgrounds
    static let peacefulGradient = LinearGradient(
        colors: [Color.backgroundCream, Color.primaryGreen.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Energy gradient for positive emotions
    static let energyGradient = LinearGradient(
        colors: [Color.emotionJoy.opacity(0.3), Color.accentGold.opacity(0.2)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Calm gradient for lower emotions
    static let calmGradient = LinearGradient(
        colors: [Color.emotionSad.opacity(0.2), Color.emotionMelancholy.opacity(0.1)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Helper Functions

    /// Get color based on emotion rating (1-10)
    static func emotionColor(for rating: Int) -> Color {
        switch rating {
        case 9...10:
            return emotionJoy
        case 7...8:
            return emotionContent
        case 5...6:
            return emotionNeutral
        case 3...4:
            return emotionMelancholy
        case 1...2:
            return emotionSad
        default:
            return emotionNeutral
        }
    }

    /// Get gradient for emotion rating
    static func emotionGradient(for rating: Int) -> LinearGradient {
        let baseColor = emotionColor(for: rating)
        return LinearGradient(
            colors: [baseColor.opacity(0.6), baseColor.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
