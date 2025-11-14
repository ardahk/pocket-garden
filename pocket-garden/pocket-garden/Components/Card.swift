//
//  Card.swift
//  pocket-garden
//
//  Reusable Card Components
//

import SwiftUI

// MARK: - Basic Card

struct Card<Content: View>: View {
    let content: Content
    var padding: CGFloat = Layout.cardPadding
    var backgroundColor: Color = .cardBackground

    init(
        padding: CGFloat = Layout.cardPadding,
        backgroundColor: Color = .cardBackground,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Emotion Entry Card

struct EmotionEntryCard: View {
    let entry: EmotionEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header: Date and Rating
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(entry.dayOfWeek)
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)

                        Text(entry.formattedDate)
                            .font(Typography.headline)
                            .foregroundColor(.textPrimary)
                    }

                    Spacer()

                    // Emotion indicator
                    VStack(spacing: Spacing.xs) {
                        Text(Theme.emoji(for: entry.emotionRating))
                            .font(.system(size: 32))

                        Text("\(entry.emotionRating)/10")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                // Transcription preview (if exists)
                if let transcription = entry.transcription, !transcription.isEmpty {
                    Text(transcription)
                        .font(Typography.callout)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // Tags (if exist)
                if let tags = entry.tags, !tags.isEmpty {
                    HStack(spacing: Spacing.sm) {
                        ForEach(tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(Typography.caption)
                                .foregroundColor(.primaryGreen)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical,Spacing.xs)
                                .background(Color.primaryGreen.opacity(0.1))
                                .cornerRadius(CornerRadius.sm)
                        }
                    }
                }

                // Tree stage indicator
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.primaryGreen)

                    Text(TreeStage(rawValue: entry.treeStage)?.name ?? "Growing")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)

                    Spacer()

                    // AI feedback indicator
                    if entry.hasAIFeedback {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                                .foregroundColor(.accentGold)

                            Text("Feedback")
                                .font(Typography.caption)
                                .foregroundColor(.accentGold)
                        }
                    }
                }
            }
            .padding(Layout.cardPadding)
            .background(
                LinearGradient(
                    colors: [
                        Color.emotionColor(for: entry.emotionRating).opacity(0.05),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(CornerRadius.md)
            .cardShadow()
        }
        .pressAnimation()
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    var iconColor: Color = .primaryGreen

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }

            // Text content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.headline)
                    .foregroundColor(.textPrimary)

                Text(description)
                    .font(Typography.callout)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(Layout.cardPadding)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.md)
        .cardShadow()
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    var color: Color = .primaryGreen

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)

            Text(value)
                .font(Typography.title)
                .foregroundColor(.textPrimary)

            Text(label)
                .font(Typography.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(
            LinearGradient(
                colors: [color.opacity(0.1), color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.md)
        .cardShadow()
    }
}

// MARK: - Empty State Card

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let description: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var showMascot: Bool = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            if showMascot {
                // Sleeping panda for empty states
                GardenMascot(emotion: .sleeping, size: 100)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.primaryGreen.opacity(0.3))
            }

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(Typography.title3)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(Typography.callout)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Typography.button)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(Color.primaryGreen)
                        .cornerRadius(CornerRadius.md)
                }
                .pressAnimation()
            }
        }
        .padding(Spacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .cardShadow()
    }
}

// MARK: - Previews

#Preview("Cards") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            Card {
                Text("Basic Card Content")
                    .font(Typography.body)
            }

            EmotionEntryCard(entry: .sample()) {
                print("Card tapped")
            }

            InfoCard(
                icon: "info.circle.fill",
                title: "Daily Check-in",
                description: "Record your emotions daily to grow your garden"
            )

            HStack(spacing: Spacing.md) {
                StatCard(
                    value: "12",
                    label: "Day Streak",
                    icon: "flame.fill",
                    color: .accentGold
                )

                StatCard(
                    value: "7.5",
                    label: "Avg Rating",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .primaryGreen
                )
            }

            EmptyStateCard(
                icon: "leaf.fill",
                title: "Start Your Garden",
                description: "Begin your emotional wellness journey by recording your first entry",
                actionTitle: "Get Started"
            ) {
                print("Action tapped")
            }
        }
        .padding()
        .background(Color.backgroundCream)
    }
}
