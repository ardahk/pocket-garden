//
//  Spacing.swift
//  pocket-garden
//
//  Design System - Spacing & Layout
//

import SwiftUI

// MARK: - Spacing System

struct Spacing {
    /// Extra small spacing (4pt)
    static let xs: CGFloat = 4

    /// Small spacing (8pt)
    static let sm: CGFloat = 8

    /// Medium spacing (12pt)
    static let md: CGFloat = 12

    /// Large spacing (16pt)
    static let lg: CGFloat = 16

    /// Extra large spacing (20pt)
    static let xl: CGFloat = 20

    /// 2X large spacing (24pt)
    static let xxl: CGFloat = 24

    /// 3X large spacing (32pt)
    static let xxxl: CGFloat = 32

    /// Huge spacing (40pt)
    static let huge: CGFloat = 40

    /// Massive spacing (48pt)
    static let massive: CGFloat = 48
}

// MARK: - Corner Radius

struct CornerRadius {
    /// Small radius for buttons and small elements (8pt)
    static let sm: CGFloat = 8

    /// Medium radius for cards (12pt)
    static let md: CGFloat = 12

    /// Large radius for major containers (16pt)
    static let lg: CGFloat = 16

    /// Extra large radius for sheets (20pt)
    static let xl: CGFloat = 20

    /// Circular (999pt)
    static let circular: CGFloat = 999
}

// MARK: - Shadow

struct ShadowStyle {
    /// Subtle shadow for cards
    static let card = Shadow(
        color: Color.shadowColor,
        radius: 8,
        x: 0,
        y: 2
    )

    /// Medium shadow for elevated elements
    static let elevated = Shadow(
        color: Color.shadowColor,
        radius: 12,
        x: 0,
        y: 4
    )

    /// Strong shadow for modals
    static let modal = Shadow(
        color: Color.black.opacity(0.15),
        radius: 20,
        x: 0,
        y: 8
    )

    /// Soft glow effect
    static let glow = Shadow(
        color: Color.primaryGreen.opacity(0.3),
        radius: 16,
        x: 0,
        y: 0
    )
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions for Spacing

extension View {
    /// Apply card shadow
    func cardShadow() -> some View {
        self.shadow(
            color: ShadowStyle.card.color,
            radius: ShadowStyle.card.radius,
            x: ShadowStyle.card.x,
            y: ShadowStyle.card.y
        )
    }

    /// Apply elevated shadow
    func elevatedShadow() -> some View {
        self.shadow(
            color: ShadowStyle.elevated.color,
            radius: ShadowStyle.elevated.radius,
            x: ShadowStyle.elevated.x,
            y: ShadowStyle.elevated.y
        )
    }

    /// Apply modal shadow
    func modalShadow() -> some View {
        self.shadow(
            color: ShadowStyle.modal.color,
            radius: ShadowStyle.modal.radius,
            x: ShadowStyle.modal.x,
            y: ShadowStyle.modal.y
        )
    }

    /// Apply glow effect
    func glowEffect() -> some View {
        self.shadow(
            color: ShadowStyle.glow.color,
            radius: ShadowStyle.glow.radius,
            x: ShadowStyle.glow.x,
            y: ShadowStyle.glow.y
        )
    }

    /// Apply card styling (background + shadow + corner radius)
    func cardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.md)
            .cardShadow()
    }
}

// MARK: - Layout Constants

struct Layout {
    /// Standard screen padding
    static let screenPadding: CGFloat = Spacing.lg

    /// Card padding
    static let cardPadding: CGFloat = Spacing.lg

    /// Button height
    static let buttonHeight: CGFloat = 56

    /// Small button height
    static let buttonHeightSmall: CGFloat = 44

    /// Minimum touch target size
    static let minTouchTarget: CGFloat = 44

    /// Maximum content width for readability
    static let maxContentWidth: CGFloat = 600
}
