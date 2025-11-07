//
//  ForestGardenView.swift
//  pocket-garden
//
//  Interactive Forest Garden Visualization - Part 3 Implementation
//

import SwiftUI
import SwiftData

struct ForestGardenView: View {
    @Query(sort: \EmotionEntry.date) private var entries: [EmotionEntry]
    @Environment(\.modelContext) private var modelContext

    @State private var scrollOffset: CGFloat = 0
    @State private var selectedEntry: EmotionEntry?
    @State private var showCelebration = false
    @State private var showButterflies = false
    @GestureState private var dragOffset: CGFloat = 0

    private let treeSpacing: CGFloat = 140
    private let treeSize = CGSize(width: 120, height: 200)

    var body: some View {
        ZStack {
            // Parallax background
            ForestBackgroundView(
                weather: currentWeather,
                scrollOffset: scrollOffset
            )

            if entries.isEmpty {
                emptyStateView
            } else {
                forestScrollView
            }

            // Particle effects
            if showButterflies {
                ButterfliesView(butterflyCount: 5)
                    .transition(.opacity)
            }

            if showCelebration {
                celebrationView
            }

            // Stats overlay
            statsOverlay
        }
        .navigationTitle("Your Garden")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        showButterflies.toggle()
                    }
                }) {
                    Image(systemName: showButterflies ? "sparkles.rectangle.stack.fill" : "sparkles.rectangle.stack")
                        .foregroundColor(.primaryGreen)
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailView(entry: entry)
        }
        .onShake {
            triggerCelebration()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.xxxl) {
            Spacer()

            VStack(spacing: Spacing.xl) {
                // Animated seed
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.primaryGreen.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Text("🌱")
                        .font(.system(size: 80))
                }
                .fadeIn()

                VStack(spacing: Spacing.sm) {
                    Text("Your Garden Awaits")
                        .font(Typography.title)
                        .foregroundColor(.textPrimary)

                    Text("Start your emotional wellness journey by creating your first journal entry. Watch your garden grow!")
                        .font(Typography.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                .fadeIn(delay: 0.2)
            }

            Spacer()
        }
        .padding(Layout.screenPadding)
    }

    // MARK: - Forest Scroll View

    private var forestScrollView: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: treeSpacing) {
                    // Left spacer
                    Color.clear
                        .frame(width: geometry.size.width / 2 - treeSize.width / 2)

                    // Trees
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        TreeView(
                            entry: entry,
                            size: treeSize
                        ) {
                            selectedEntry = entry
                        }
                        .id(entry.id)
                    }

                    // Right spacer
                    Color.clear
                        .frame(width: geometry.size.width / 2 - treeSize.width / 2)
                }
                .background(
                    GeometryReader { scrollGeo in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: scrollGeo.frame(in: .named("scroll")).minX
                            )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
        }
    }

    // MARK: - Stats Overlay

    private var statsOverlay: some View {
        VStack {
            HStack(spacing: Spacing.md) {
                // Tree count
                statsCard(
                    icon: "leaf.fill",
                    value: "\(entries.count)",
                    label: entries.count == 1 ? "Tree" : "Trees",
                    color: .primaryGreen
                )

                // Weather indicator
                statsCard(
                    icon: "cloud.sun.fill",
                    value: currentWeather.emoji,
                    label: currentWeather.name,
                    color: .accentGold
                )

                // Streak
                statsCard(
                    icon: "flame.fill",
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    color: .emotionJoy
                )
            }
            .padding(Spacing.md)
            .background(
                Capsule()
                    .fill(Color.cardBackground.opacity(0.95))
                    .cardShadow()
            )
            .padding(.horizontal, Layout.screenPadding)
            .padding(.top, Spacing.sm)

            Spacer()
        }
    }

    private func statsCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(Typography.headline)
                .foregroundColor(.textPrimary)

            Text(label)
                .font(Typography.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Celebration View

    private var celebrationView: some View {
        ZStack {
            ConfettiView(particleCount: 40)

            SparklesView(sparkleCount: 25)

            FloatingLeavesView(leafCount: 12)
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    // MARK: - Helper Properties

    private var currentWeather: ForestWeather {
        let recentRatings = entries.suffix(7).map { $0.emotionRating }
        return ForestWeather.from(recentRatings: Array(recentRatings))
    }

    private var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        let sortedEntries = entries.sorted { $0.date > $1.date }

        for i in 0..<sortedEntries.count {
            let expectedDate = calendar.date(byAdding: .day, value: -i, to: Date())!
            if let entry = sortedEntries.first(where: {
                calendar.isDate($0.date, inSameDayAs: expectedDate)
            }) {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Actions

    private func triggerCelebration() {
        Theme.Haptics.success()

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showCelebration = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showCelebration = false
            }
        }
    }
}

// MARK: - Scroll Offset Preference

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Shake Gesture

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(DeviceShakeViewModifier(action: action))
    }
}

struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
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

#Preview("Celebration") {
    struct CelebrationDemo: View {
        @State private var showCelebration = true

        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "87CEEB"), Color(hex: "E0F6FF")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if showCelebration {
                    ZStack {
                        ConfettiView(particleCount: 40)
                        SparklesView(sparkleCount: 25)
                        FloatingLeavesView(leafCount: 12)
                    }
                }

                VStack {
                    Spacer()

                    PrimaryButton("Celebrate!") {
                        showCelebration.toggle()
                    }
                    .padding()
                }
            }
        }
    }

    return CelebrationDemo()
}
