import SwiftUI
import SwiftData

struct SafeSpaceView: View {
    @DevObserveInjection var inject: DevInjectionToken

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel: SafeSpaceViewModel
    @State private var selectedActivity: CalmActivity?
    /// Breathing pattern to use when a deep-link launches a breathing activity.
    @State private var deepLinkBreathingPattern: BreathingPattern? = nil
    @ObservedObject private var pendingDeepLink = PendingDeepLink.shared
    /// The currently selected tab in MainTabView.
    @Binding private var selectedTab: Int
    @AppStorage("userFirstName") private var userFirstName = ""

    @Query(sort: \EmotionEntry.date, order: .reverse) private var recentEntries: [EmotionEntry]

    private let isEmbedded: Bool
    private static let sanctuaryTabIndex = 2

    init(modelContext: ModelContext? = nil, isEmbedded: Bool = false,
         selectedTab: Binding<Int> = .constant(SafeSpaceView.sanctuaryTabIndex)) {
        _viewModel = State(initialValue: SafeSpaceViewModel(modelContext: modelContext))
        self.isEmbedded = isEmbedded
        self._selectedTab = selectedTab
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.backgroundCream,
                        Color.emotionCalm.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                        // Drag indicator (only for sheet presentation)
                        if !isEmbedded {
                            Capsule()
                                .fill(Color.textSecondary.opacity(0.35))
                                .frame(width: 40, height: 5)
                                .padding(.top, 4)
                        }

                        // Compact top block: recommendation + progress in one card
                        topInsightSection

                        // Ambient sounds
                        ambientSoundsSection

                        // Quick practices Grid
                        quickPracticesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar {
                if !isEmbedded {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.cleanup()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .onAppear {
                viewModel.startSession(fromEmergency: true)
                viewModel.refreshProgressSnapshot()
                consumePendingDeepLinkIfNeeded(for: selectedTab)
            }
            .onDisappear {
                viewModel.cleanup()
            }
            .onChange(of: scenePhase) { _, newPhase in
                viewModel.handleScenePhaseChange(newPhase)
            }
            // Handle tab switches for audio state.
            .onChange(of: selectedTab) { _, newTab in
                if newTab != SafeSpaceView.sanctuaryTabIndex {
                    viewModel.handleTabDeselected()
                    if NotificationPromptCoordinator.shared.hasDeferredRequest,
                       selectedActivity == nil {
                        NotificationPromptCoordinator.shared.cancelDeferredRequest()
                    }
                } else {
                    consumePendingDeepLinkIfNeeded(for: newTab)
                }
            }
            .onChange(of: pendingDeepLink.pendingLink) { _, _ in
                consumePendingDeepLinkIfNeeded(for: selectedTab)
            }
            .sheet(item: $selectedActivity) { activity in
                activitySheet(for: activity)
            }
        }
        .devEnableInjection()
    }

    // MARK: - Ambient Sounds Section

    private var topInsightSection: some View {
        let recommendation = recommendedCombo
        let stats = sanctuaryStats
        return VStack(alignment: .leading, spacing: 12) {
            Text("Recommended For You")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.primaryGreen)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)

                        Text(recommendation.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                Button {
                    launchCombo(activity: recommendation.activity, sound: recommendation.sound)
                } label: {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: recommendation.sound.icon)
                        Text("Start \(recommendation.sound.rawValue) + \(recommendation.activity.shortDisplayTitle)")
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primaryGreen)
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, 4)

                HStack(spacing: 10) {
                    ProgressChip(title: "This Week", value: "\(stats.sessionsThisWeek)")
                    ProgressChip(title: "Most Used", value: stats.mostUsedActivity)
                    ProgressChip(title: "Today", value: "\(stats.completedToday)")
                }
            }
            .padding(14)
            .background(Color.cardBackground)
            .cornerRadius(16)
        }
        .padding(.top, isEmbedded ? 8 : 0)
    }

    private var ambientSoundsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Soundscape")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AmbientSoundType.allCases) { soundType in
                        SoundBubble(
                            soundType: soundType,
                            isSelected: viewModel.selectedAmbientSound == soundType
                        ) {
                            viewModel.toggleAmbientSound(soundType)
                        }
                    }
                }
                .padding(.vertical, 4) // Space for shadows
            }
        }
    }

    // MARK: - Quick Practices Section

    private var quickPracticesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Practices")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(CalmActivity.activeActivities) { activity in
                    PracticeGridCard(activity: activity) {
                        selectedActivity = activity
                        viewModel.startActivity(activity)
                    }
                }
            }
        }
    }

    // MARK: - Activity Sheet
    //
    // ⚠️  When adding a new Sanctuary activity:
    //   1. Add its ActivityType case in CalmActivity.swift.
    //   2. Add a `case .yourType:` here that presents the correct view.
    //   3. Add matching entries in `allSanctuaryDeepLinks` in GardenMascot.swift.
    //   4. Add the activity name + description to `sanctuaryItems` in GardenMascot.swift.
    //   See the full checklist at the top of `allSanctuaryDeepLinks`.

    @ViewBuilder
    private func activitySheet(for activity: CalmActivity) -> some View {
        switch activity.type {
        case .breathing:
            BreathingExerciseView(
                pattern: deepLinkBreathingPattern ?? .boxBreathing,
                duration: activity.duration
            ) {
                completeActivityAndHandleDeferredNotification(activity, shouldResetBreathingPattern: true)
            }

        case .grounding:
            GroundingTechniqueView {
                completeActivityAndHandleDeferredNotification(activity, shouldResetBreathingPattern: true)
            }

        case .bodyScan:
            BodyScanView {
                completeActivityAndHandleDeferredNotification(activity)
            }

        case .affirmations:
            AffirmationsView(duration: activity.duration) {
                completeActivityAndHandleDeferredNotification(activity)
            }
            
        case .worryTree:
            WorryTreeView {
                completeActivityAndHandleDeferredNotification(activity)
            }
            
        case .visualization:
            SafePlaceView(duration: activity.duration) {
                completeActivityAndHandleDeferredNotification(activity)
            }
        
        case .nameAndSoothe:
            ThreeGoodMomentsView(duration: activity.duration) {
                completeActivityAndHandleDeferredNotification(activity)
            }

        case .lovingKindness:
            PlaceholderActivityView(activity: activity) {
                completeActivityAndHandleDeferredNotification(activity)
            }
        }
    }

    private func consumePendingDeepLinkIfNeeded(for tab: Int) {
        guard tab == SafeSpaceView.sanctuaryTabIndex else { return }
        guard selectedActivity == nil else { return }
        guard let deepLink = pendingDeepLink.pendingLink else { return }
        guard let activity = CalmActivity.activeActivities.first(where: { $0.type == deepLink.activityType }) else {
            pendingDeepLink.pendingLink = nil
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            guard self.selectedTab == SafeSpaceView.sanctuaryTabIndex else { return }
            guard self.selectedActivity == nil else { return }
            guard self.pendingDeepLink.pendingLink == deepLink else { return }

            self.pendingDeepLink.pendingLink = nil
            self.deepLinkBreathingPattern = deepLink.breathingPattern
            withAnimation(.easeInOut(duration: 0.25)) {
                self.selectedActivity = activity
            }
            self.viewModel.startActivity(activity)
        }
    }

    private func completeActivityAndHandleDeferredNotification(
        _ activity: CalmActivity,
        shouldResetBreathingPattern: Bool = false
    ) {
        if shouldResetBreathingPattern {
            deepLinkBreathingPattern = nil
        }

        viewModel.completeActivity(activity)
        selectedActivity = nil
        Task { @MainActor in
            await NotificationPromptCoordinator.shared.requestIfDeferredAfterSanctuaryCompletion()
        }
    }

    private func launchCombo(activity: CalmActivity, sound: AmbientSoundType) {
        viewModel.setAmbientSound(sound)
        selectedActivity = activity
        viewModel.startActivity(activity)
    }

    private var recommendedCombo: SanctuaryComboRecommendation {
        let latestRating = recentEntries.first?.emotionRating ?? 6
        let name = userFirstName.trimmingCharacters(in: .whitespacesAndNewlines)

        if latestRating <= 3 {
            return SanctuaryComboRecommendation(
                title: "Settle your nervous system first",
                subtitle: name.isEmpty ? "Start with Grounding + Rain" : "\(name), try Grounding + Rain",
                reason: "Recent check-ins look heavy. This combo is the fastest way to create safety and reduce overwhelm.",
                activity: CalmActivity.groundingTechnique,
                sound: .rain
            )
        }

        if latestRating <= 6 {
            return SanctuaryComboRecommendation(
                title: "Release body tension",
                subtitle: name.isEmpty ? "Try Muscle Relaxation + Nature" : "\(name), try Muscle Relaxation + Nature",
                reason: "Mid-range stress often sits in the body. Pairing movement-based release with nature audio helps downshift.",
                activity: CalmActivity.bodyScan,
                sound: .nature
            )
        }

        return SanctuaryComboRecommendation(
            title: "Protect your momentum",
            subtitle: name.isEmpty ? "Use Three Good Moments + Lofi" : "\(name), use Three Good Moments + Lofi",
            reason: "Your recent mood trend is stronger. This combo helps lock in emotional gains and resilience.",
            activity: CalmActivity.nameAndSoothe,
            sound: .lofi
        )
    }

    private var sanctuaryStats: SanctuaryProgressStats {
        let activityNameByRaw = Dictionary(
            uniqueKeysWithValues: CalmActivity.allActivities.map { ($0.type.rawValue, $0.title) }
        )
        let topRawActivity = viewModel.progressSnapshot.mostUsedActivityRaw
        let mostUsedActivity = topRawActivity
            .flatMap { raw in
                activityNameByRaw[raw].flatMap { title in
                    CalmActivity.allActivities.first(where: { $0.title == title })?.shortDisplayTitle
                }
            } ?? "Start"

        return SanctuaryProgressStats(
            sessionsThisWeek: viewModel.progressSnapshot.completedThisWeek,
            mostUsedActivity: mostUsedActivity,
            completedToday: viewModel.progressSnapshot.completedToday
        )
    }
}

private struct SanctuaryComboRecommendation {
    let title: String
    let subtitle: String
    let reason: String
    let activity: CalmActivity
    let sound: AmbientSoundType
}

private struct SanctuaryProgressStats {
    let sessionsThisWeek: Int
    let mostUsedActivity: String
    let completedToday: Int
}

// MARK: - Components

struct SoundBubble: View {
    let soundType: AmbientSoundType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.primaryGreen : Color.white)
                        .frame(width: 60, height: 60)
                    
                    if isSelected {
                        Circle()
                            .stroke(Color.primaryGreen.opacity(0.3), lineWidth: 4)
                            .frame(width: 68, height: 68)
                    }

                    Image(systemName: soundType.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? .white : Color.textSecondary)
                }
                
                Text(soundType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? Color.primaryGreen : Color.textSecondary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(width: 80)
    }
}

struct PracticeGridCard: View {
    let activity: CalmActivity
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(activity.color.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: activity.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(activity.color)
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("\(activity.duration) min")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(16)
            .frame(height: 130, alignment: .topLeading) // Fixed height for grid
            .background(Color.cardBackground)
            .cornerRadius(20)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ProgressChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

struct PlaceholderActivityView: View {
    let activity: CalmActivity
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(activity.color.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: activity.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(activity.color)
            }
            
            VStack(spacing: 8) {
                Text(activity.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(activity.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: onComplete) {
                Text("Complete")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryGreen)
                    .cornerRadius(16)
            }
            .padding()
        }
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    SafeSpaceView()
        .modelContainer(for: [CalmSession.self, EmotionEntry.self])
}
