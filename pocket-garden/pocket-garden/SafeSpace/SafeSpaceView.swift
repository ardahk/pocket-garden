import SwiftUI
import SwiftData
import Inject

struct SafeSpaceView: View {
    @ObserveInjection var inject

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
                    VStack(spacing: 20) {
                        // Drag indicator (only for sheet presentation)
                        if !isEmbedded {
                            Capsule()
                                .fill(Color.textSecondary.opacity(0.35))
                                .frame(width: 40, height: 5)
                                .padding(.top, 8)
                        }

                        // Header
                        VStack(spacing: 6) {
                            Text("Sanctuary")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color.textPrimary)

                            Text("A quiet place to pause and reset")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding(.top, isEmbedded ? 16 : 8)

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
        .enableInjection()
    }

    // MARK: - Ambient Sounds Section

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
            
        case .butterflyHug:
            ButterflyHugView(duration: activity.duration) {
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
