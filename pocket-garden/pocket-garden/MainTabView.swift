//
//  MainTabView.swift
//  pocket-garden
//
//  Main Navigation - Tab Bar
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var pendingSanctuaryNavigationTask: Task<Void, Never>?
    @StateObject private var achievementManager = AchievementManager.shared
    @Binding var openJournalFromNotification: Bool
    @Binding var tourSelectedTab: Int?
    private let sanctuaryTransitionDelay: Duration = .seconds(5)
    private let postAchievementPause: Duration = .seconds(2)

    init(openJournalFromNotification: Binding<Bool> = .constant(false), tourSelectedTab: Binding<Int?> = .constant(nil)) {
        self._openJournalFromNotification = openJournalFromNotification
        self._tourSelectedTab = tourSelectedTab
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
                    .accessibilityLabel("Home tab")
            }
            .tag(0)

            // Forest Tab
            NavigationStack {
                ForestGardenViewRedesigned()
            }
            .tabItem {
                Label("Garden", systemImage: "leaf.fill")
                    .accessibilityLabel("Garden tab")
            }
            .tag(1)

            SafeSpaceView(modelContext: nil, isEmbedded: true, selectedTab: $selectedTab)
            .tabItem {
                Label("Sanctuary", systemImage: "moon.stars.fill")
                    .accessibilityLabel("Sanctuary tab")
            }
            .tag(2)
        }
        .accentColor(.primaryGreen)
        .onReceive(NotificationCenter.default.publisher(for: .showJournalFromForest)) { _ in
            selectedTab = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .triggerJournalFromNotification, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToSanctuaryActivity)) { _ in
            scheduleSanctuaryNavigation(after: .zero)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToGardenThenSanctuary)) { _ in
            withAnimation(.easeInOut(duration: 0.45)) {
                selectedTab = 1
            }
            scheduleSanctuaryNavigationFallback()
        }
        .onChange(of: openJournalFromNotification) { _, newValue in
            if newValue {
                // Navigate to home tab and trigger journal
                selectedTab = 0
                openJournalFromNotification = false
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    NotificationCenter.default.post(name: .triggerJournalFromNotification, object: nil)
                }
            }
        }
        .onChange(of: tourSelectedTab) { _, newValue in
            if let tab = newValue {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = tab
                }
            }
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.backgroundCream)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .onDisappear {
            pendingSanctuaryNavigationTask?.cancel()
            pendingSanctuaryNavigationTask = nil
        }
    }

    private func scheduleSanctuaryNavigationFallback() {
        scheduleSanctuaryNavigation(after: sanctuaryTransitionDelay)
    }

    private func scheduleSanctuaryNavigation(after delay: Duration) {
        pendingSanctuaryNavigationTask?.cancel()
        pendingSanctuaryNavigationTask = Task { @MainActor in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }

            var waitedForAchievementDismissal = false
            while achievementManager.showUnlockAnimation {
                waitedForAchievementDismissal = true
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
            }

            if waitedForAchievementDismissal {
                try? await Task.sleep(for: postAchievementPause)
                guard !Task.isCancelled else { return }
            }

            withAnimation(.easeInOut(duration: 0.5)) {
                selectedTab = 2
            }
            pendingSanctuaryNavigationTask = nil
        }
    }
}

// MARK: - Additional Notification Extension

extension Notification.Name {
    static let triggerJournalFromNotification = Notification.Name("triggerJournalFromNotification")
    static let navigateToSanctuaryActivity = Notification.Name("navigateToSanctuaryActivity")
    static let showBeeAnimationInGarden = Notification.Name("showBeeAnimationInGarden")
    static let navigateToGardenThenSanctuary = Notification.Name("navigateToGardenThenSanctuary")
}

#Preview {
    MainTabView()
        .modelContainer(for: EmotionEntry.self, inMemory: true)
}
