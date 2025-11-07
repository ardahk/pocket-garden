//
//  Typography.swift
//  pocket-garden
//
//  Design System - Typography & Text Styles
//

import SwiftUI

// MARK: - Typography System

struct Typography {

    // MARK: - Font Families

    enum FontFamily: String {
        case rounded = "SFProRounded"
        case standard = "SFPro"

        var name: String {
            switch self {
            case .rounded:
                return "SF Pro Rounded"
            case .standard:
                return "SF Pro"
            }
        }
    }

    // MARK: - Text Styles

    /// Large title for main headings (34pt, Bold, Rounded)
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)

    /// Title for section headers (28pt, Bold, Rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)

    /// Title 2 for sub-sections (22pt, Semibold, Rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)

    /// Title 3 for cards (20pt, Semibold, Rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)

    /// Headline for emphasis (17pt, Semibold)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)

    /// Body text for regular content (17pt, Regular)
    static let body = Font.system(size: 17, weight: .regular, design: .default)

    /// Body emphasis for highlighted content (17pt, Medium)
    static let bodyEmphasized = Font.system(size: 17, weight: .medium, design: .default)

    /// Callout for secondary content (16pt, Regular)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)

    /// Subheadline for labels (15pt, Regular)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)

    /// Footnote for captions (13pt, Regular)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)

    /// Caption for smallest text (12pt, Regular)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    /// Caption emphasized (12pt, Medium)
    static let captionEmphasized = Font.system(size: 12, weight: .medium, design: .default)

    // MARK: - Special Styles

    /// Display text for hero sections (40pt, Bold, Rounded)
    static let display = Font.system(size: 40, weight: .bold, design: .rounded)

    /// Button text (17pt, Semibold, Rounded)
    static let button = Font.system(size: 17, weight: .semibold, design: .rounded)

    /// Small button text (15pt, Semibold, Rounded)
    static let buttonSmall = Font.system(size: 15, weight: .semibold, design: .rounded)

    /// Number display for ratings (48pt, Bold, Rounded)
    static let numberDisplay = Font.system(size: 48, weight: .bold, design: .rounded)
}

// MARK: - View Extensions for Typography

extension View {
    /// Apply large title style
    func largeTitleStyle() -> some View {
        self.font(Typography.largeTitle)
            .foregroundColor(.textPrimary)
    }

    /// Apply title style
    func titleStyle() -> some View {
        self.font(Typography.title)
            .foregroundColor(.textPrimary)
    }

    /// Apply title 2 style
    func title2Style() -> some View {
        self.font(Typography.title2)
            .foregroundColor(.textPrimary)
    }

    /// Apply title 3 style
    func title3Style() -> some View {
        self.font(Typography.title3)
            .foregroundColor(.textPrimary)
    }

    /// Apply body style
    func bodyStyle() -> some View {
        self.font(Typography.body)
            .foregroundColor(.textPrimary)
    }

    /// Apply secondary text style
    func secondaryTextStyle() -> some View {
        self.font(Typography.callout)
            .foregroundColor(.textSecondary)
    }

    /// Apply caption style
    func captionStyle() -> some View {
        self.font(Typography.caption)
            .foregroundColor(.textSecondary)
    }
}

// MARK: - Text Modifiers

struct EmphasisTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.bodyEmphasized)
            .foregroundColor(.primaryGreen)
    }
}

struct NumberDisplayModifier: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(Typography.numberDisplay)
            .foregroundColor(color)
            .fontWeight(.bold)
    }
}

extension View {
    /// Emphasize text with color
    func emphasized() -> some View {
        self.modifier(EmphasisTextModifier())
    }

    /// Display as large number
    func numberDisplay(color: Color = .primaryGreen) -> some View {
        self.modifier(NumberDisplayModifier(color: color))
    }
}
