//
//  ForestGardenView.swift
//  pocket-garden
//
//  Forest Garden Visualization
//

import SwiftUI
import SwiftData

struct ForestGardenView: View {
    @Query(sort: \EmotionEntry.date) private var entries: [EmotionEntry]

    var body: some View {
        ZStack {
            // Background
            skyGradient
                .ignoresSafeArea()

            if entries.isEmpty {
                emptyStateView
            } else {
                forestContentView
            }
        }
        .navigationTitle("Your Garden")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sky Gradient

    private var skyGradient: some View {
        LinearGradient(
            colors: weatherColors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var weatherColors: [Color] {
        // Determine weather based on recent ratings
        let recentRatings = entries.suffix(7).map { $0.emotionRating }
        let weather = ForestWeather.from(recentRatings: Array(recentRatings))
        return weather.skyGradient
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 80))
                .foregroundColor(.primaryGreen.opacity(0.3))

            VStack(spacing: Spacing.sm) {
                Text("Your Garden Awaits")
                    .font(Typography.title)
                    .foregroundColor(.textPrimary)

                Text("Start journaling to grow your first tree")
                    .font(Typography.callout)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Text("Forest visualization will be implemented in Part 3")
                .font(Typography.caption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.lg)
        }
        .padding(Layout.screenPadding)
    }

    // MARK: - Forest Content (Placeholder)

    private var forestContentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 40) {
                ForEach(entries) { entry in
                    VStack(spacing: Spacing.md) {
                        // Tree emoji placeholder
                        Text(TreeStage(rawValue: entry.treeStage)?.emoji ?? "🌱")
                            .font(.system(size: 60))

                        // Date label
                        Text(entry.formattedDate)
                            .font(Typography.caption)
                            .foregroundColor(.textPrimary)

                        // Rating
                        Text("\(entry.emotionRating)/10")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(Spacing.md)
                    .background(Color.cardBackground.opacity(0.8))
                    .cornerRadius(CornerRadius.md)
                    .cardShadow()
                    .onTapGesture {
                        Theme.Haptics.light()
                        // Navigate to entry detail
                    }
                }
            }
            .padding(.horizontal, Layout.screenPadding)
            .padding(.vertical, Spacing.xxxl)
        }
    }
}

// MARK: - Preview

#Preview("Empty Garden") {
    NavigationStack {
        ForestGardenView()
    }
    .modelContainer(for: EmotionEntry.self, inMemory: true)
}

#Preview("Garden with Trees") {
    let container = try! ModelContainer(
        for: EmotionEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let entries = EmotionEntry.sampleEntries()
    for entry in entries {
        container.mainContext.insert(entry)
    }

    return NavigationStack {
        ForestGardenView()
    }
    .modelContainer(container)
}
