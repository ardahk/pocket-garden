//
//  ExpandableForestView.swift
//  pocket-garden
//
//  Minecraft-style expandable garden that grows with entries
//

import SwiftUI
import SwiftData

struct ExpandableForestView: View {
    @Query(sort: \EmotionEntry.date) private var entries: [EmotionEntry]
    @Environment(\.modelContext) private var modelContext

    @State private var cameraOffset: CGSize = .zero
    @State private var currentOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var selectedEntry: EmotionEntry?
    @State private var showCelebration = false
    @State private var showButterflies = false
    @State private var showAchievements = false

    // Achievement tracking
    @State private var achievementService = AchievementService()
    @State private var shakeCelebrationCount = UserDefaults.standard.integer(forKey: "shakeCelebrationCount")

    // Grid configuration
    private let treeSize: CGFloat = 80
    private let treeSpacing: CGFloat = 20
    private let treesPerRow = 5

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundLayer(size: geometry.size)

                // Scrollable garden grid
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    gardenGrid
                        .frame(
                            width: gridWidth,
                            height: gridHeight
                        )
                        .padding(50)
                }
                .scrollIndicators(.never)

                // Overlay UI
                VStack {
                    Spacer()
                    miniMapOverlay
                        .padding()
                }
            }
        }
        .navigationTitle("Your Garden")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Spacing.sm) {
                    Button(action: {
                        withAnimation {
                            showButterflies.toggle()
                        }
                    }) {
                        Image(systemName: showButterflies ? "sparkles.rectangle.stack.fill" : "sparkles.rectangle.stack")
                            .foregroundColor(.primaryGreen)
                    }

                    Button(action: {
                        showAchievements = true
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.accentGold)

                            if achievementService.unlockedCount > 0 {
                                Circle()
                                    .fill(Color.emotionJoy)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailView(entry: entry)
        }
        .sheet(isPresented: $showAchievements) {
            NavigationStack {
                AchievementsOverviewView(achievements: achievementService.achievements)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showAchievements = false
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $achievementService.showUnlockNotification) {
            if let achievement = achievementService.recentlyUnlocked {
                AchievementUnlockView(achievement: achievement) {
                    achievementService.showUnlockNotification = false
                }
            }
        }
        .onShake {
            triggerCelebration()
        }
        .onAppear {
            initializeAchievements()
            checkAchievements()
        }
    }

    // MARK: - Background Layer

    private func backgroundLayer(size: CGSize) -> some View {
        ZStack {
            // Sky gradient
            LinearGradient(
                colors: [
                    Color(hex: "87CEEB"),
                    Color(hex: "98D8E8")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Clouds
            GeometryReader { geo in
                ForEach(0..<5, id: \.self) { index in
                    CloudShape()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 80, height: 40)
                        .offset(
                            x: CGFloat(index) * 120 - 50,
                            y: CGFloat(index % 2) * 40 + 20
                        )
                }
            }

            // Butterflies overlay
            if showButterflies {
                ButterfliesView(butterflyCount: 5)
                    .transition(.opacity)
            }

            // Celebration overlay
            if showCelebration {
                ZStack {
                    ConfettiView(pieceCount: 40)
                    SparklesView(sparkleCount: 25)
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Garden Grid

    private var gardenGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(treeSize + treeSpacing), spacing: treeSpacing), count: treesPerRow),
            spacing: treeSpacing
        ) {
            if entries.isEmpty {
                emptyGardenPlot
            } else {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    gardenPlot(for: entry, index: index)
                }
            }
        }
    }

    private var emptyGardenPlot: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.primaryGreen.opacity(0.3))

            Text("Start\nJournaling")
                .font(Typography.caption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: treeSize, height: treeSize * 1.5)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.cardBackground.opacity(0.5))
                .shadow(color: .shadowColor, radius: 4)
        )
    }

    private func gardenPlot(for entry: EmotionEntry, index: Int) -> some View {
        VStack(spacing: 4) {
            // Tree
            TreeView(entry: entry)
                .frame(width: treeSize, height: treeSize * 1.5)
                .onTapGesture {
                    selectedEntry = entry
                    Theme.Haptics.light()
                }
                .scaleEffect(selectedEntry?.id == entry.id ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedEntry?.id)

            // Date label
            Text(entry.date, format: .dateTime.month().day())
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.textSecondary)
        }
        .transition(.scale.combined(with: .opacity))
        .animation(
            .spring(response: 0.6, dampingFraction: 0.7)
                .delay(Double(index) * 0.05),
            value: entries.count
        )
    }

    // MARK: - Mini Map Overlay

    private var miniMapOverlay: some View {
        HStack(spacing: Spacing.lg) {
            // Stats card
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("\(entries.count)")
                        .font(Typography.title3)
                        .foregroundColor(.textPrimary)
                    Text("Trees")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("\(currentStreak)")
                        .font(Typography.title3)
                        .foregroundColor(.textPrimary)
                    Text("Day Streak")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(weatherEmoji)
                        .font(.system(size: 24))
                    Text("Mood")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.cardBackground)
                    .shadow(color: .shadowColor, radius: 8)
            )
        }
    }

    // MARK: - Computed Properties

    private var gridWidth: CGFloat {
        let columns = CGFloat(max(treesPerRow, (entries.count + treesPerRow - 1) / treesPerRow * treesPerRow))
        return columns * (treeSize + treeSpacing)
    }

    private var gridHeight: CGFloat {
        let rows = CGFloat(max(3, (entries.count + treesPerRow - 1) / treesPerRow))
        return rows * (treeSize * 1.5 + treeSpacing)
    }

    private var currentStreak: Int {
        guard !entries.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedEntries = entries.sorted { $0.date > $1.date }

        var streak = 0
        var lastDate = Date()

        for entry in sortedEntries {
            let daysDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: entry.date), to: calendar.startOfDay(for: lastDate)).day ?? 0

            if daysDiff <= 1 {
                streak += 1
                lastDate = entry.date
            } else {
                break
            }
        }

        return streak
    }

    private var weatherEmoji: String {
        guard !entries.isEmpty else { return "☀️" }

        let recentEntries = entries.suffix(7)
        let avgRating = Double(recentEntries.reduce(0) { $0 + $1.emotionRating }) / Double(recentEntries.count)

        switch avgRating {
        case 8...:
            return "☀️"
        case 6..<8:
            return "⛅"
        case 4..<6:
            return "☁️"
        default:
            return "🌧️"
        }
    }

    // MARK: - Actions

    private func triggerCelebration() {
        Theme.Haptics.success()

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showCelebration = true
        }

        // Track shake celebration for achievement
        shakeCelebrationCount += 1
        UserDefaults.standard.set(shakeCelebrationCount, forKey: "shakeCelebrationCount")
        achievementService.incrementShakeCelebration()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showCelebration = false
            }
        }
    }

    private func initializeAchievements() {
        if achievementService.achievements.isEmpty {
            achievementService.achievements = Achievement.createDefaultAchievements()
        }
    }

    private func checkAchievements() {
        achievementService.checkAchievements(
            entries: entries,
            currentStreak: currentStreak
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExpandableForestView()
    }
    .modelContainer(for: EmotionEntry.self, inMemory: true)
}

#Preview("With Entries") {
    let container = try! ModelContainer(
        for: EmotionEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let entries = EmotionEntry.sampleEntries()
    for entry in entries {
        container.mainContext.insert(entry)
    }

    return NavigationStack {
        ExpandableForestView()
    }
    .modelContainer(container)
}
