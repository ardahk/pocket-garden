//
//  pocket_gardenApp.swift
//  pocket-garden
//
//  Created by Arda Hoke on 11/6/25.
//

import SwiftUI
import SwiftData
import UserNotifications

// MARK: - App Lifecycle Manager

@Observable
class AppLifecycleManager {
    static let shared = AppLifecycleManager()
    
    weak var activeAmbientService: AmbientSoundService?
    private var wasPlayingBeforeInactive: Bool = false
    private var soundBeforeInactive: AmbientSoundType?
    
    private init() {}
    
    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // Immediately stop all ambient music when app goes to background (no fade)
            activeAmbientService?.stopImmediate()
            wasPlayingBeforeInactive = false
            soundBeforeInactive = nil
        case .inactive:
            // Store state and immediately stop when app becomes inactive
            wasPlayingBeforeInactive = activeAmbientService?.isPlaying ?? false
            soundBeforeInactive = activeAmbientService?.currentSound
            activeAmbientService?.stopImmediate()
        case .active:
            // Resume with fade-in if music was playing before inactive
            if wasPlayingBeforeInactive, let sound = soundBeforeInactive {
                activeAmbientService?.play(sound) // Fades in automatically
            }
            wasPlayingBeforeInactive = false
            soundBeforeInactive = nil
        @unknown default:
            break
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        return true
    }
}

@main
struct pocket_gardenApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    // TODO: Interactive tour - disabled for now, may revisit later
    // @AppStorage("hasSeenAppTour") private var hasSeenAppTour = false
    // @State private var showTourPrompt = false
    // @State private var showTour = false
    // @State private var tourSelectedTab: Int? = nil
    @State private var shouldOpenJournal = false
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var achievementManager = AchievementManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([EmotionEntry.self, GrowingTree.self, Quote.self, Achievement.self, CalmSession.self, WorryTreeEntry.self])
        // Use default SwiftData location to preserve existing user data
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    MainTabView(openJournalFromNotification: $shouldOpenJournal)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    
                    // TODO: Interactive tour - disabled for now, may revisit later
                    // To re-enable: uncomment tour state vars above, add tourSelectedTab binding
                    // to MainTabView, and uncomment the tour prompt + overlay blocks below.
                    //
                    // if showTourPrompt {
                    //     AppTourPromptView(onAccept: { ... }, onDecline: { ... })
                    // }
                    // if showTour {
                    //     AppTourOverlay(tourSelectedTab: $tourSelectedTab) { ... }
                    // }
                } else {
                    OnboardingView()
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                // Global achievement unlock overlay
                if achievementManager.showUnlockAnimation,
                   let achievement = achievementManager.recentlyUnlockedAchievement {
                    AchievementUnlockView(achievement: achievement) {
                        achievementManager.dismissUnlockAnimation()
                    }
                    .transition(.opacity)
                    .zIndex(1000)
                }
            }
            .floatingCoinOverlay() // Floating achievement coin after dismissal
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: hasCompletedOnboarding)
            .onAppear {
                setupNotificationHandler()
                initializeAndBackfillAchievements()
            }
            .onChange(of: scenePhase) { _, newPhase in
                // Handle global app lifecycle for ambient music
                AppLifecycleManager.shared.handleScenePhase(newPhase)
                
                if newPhase == .active {
                    rescheduleNotificationsOnLaunch()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func setupNotificationHandler() {
        NotificationDelegate.shared.onNotificationTapped = {
            // Trigger journal opening when notification is tapped
            shouldOpenJournal = true
        }
    }
    
    @MainActor
    private func initializeAndBackfillAchievements() {
        let context = sharedModelContainer.mainContext
        AchievementManager.shared.initializeAchievements(modelContext: context)
        
        // Backfill progress for existing users - runs after initialization
        backfillAchievementProgress(context: context)
    }
    
    @MainActor
    private func backfillAchievementProgress(context: ModelContext) {
        // Fetch all entries and trees
        let entryDescriptor = FetchDescriptor<EmotionEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let treeDescriptor = FetchDescriptor<GrowingTree>()
        
        guard let entries = try? context.fetch(entryDescriptor),
              let trees = try? context.fetch(treeDescriptor) else { return }
        
        // Only backfill if user has data
        guard !entries.isEmpty || !trees.isEmpty else { return }
        
        // Calculate current streak
        let streak = calculateCurrentStreak(context: context)
        
        // Run full achievement check to backfill progress
        AchievementManager.shared.checkAndUpdateAchievements(
            entries: entries,
            trees: trees,
            currentStreak: streak,
            modelContext: context
        )
    }
    
    @MainActor
    private func rescheduleNotificationsOnLaunch() {
        let context = sharedModelContainer.mainContext
        
        // Check for today's entry
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let predicate = #Predicate<EmotionEntry> { entry in
            entry.date >= today && entry.date < tomorrow
        }
        
        let descriptor = FetchDescriptor<EmotionEntry>(predicate: predicate)
        let hasEntryToday = (try? context.fetchCount(descriptor)) ?? 0 > 0
        
        // Calculate streak
        let streak = calculateCurrentStreak(context: context)
        
        // Get current tree info
        let treeDescriptor = FetchDescriptor<GrowingTree>(
            predicate: #Predicate { !$0.isFullyGrown },
            sortBy: [SortDescriptor(\.plantedDate, order: .reverse)]
        )
        let currentTree = try? context.fetch(treeDescriptor).first
        
        Task {
            await NotificationService.shared.scheduleNotifications(
                currentStreak: streak,
                hasEntryToday: hasEntryToday,
                currentTreeType: currentTree?.treeType,
                treeProgress: currentTree?.growthProgress
            )
        }
    }
    
    @MainActor
    private func calculateCurrentStreak(context: ModelContext) -> Int {
        var streak = 0
        let calendar = Calendar.current
        let today = Date()
        
        let descriptor = FetchDescriptor<EmotionEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let entries = try? context.fetch(descriptor) else { return 0 }
        
        let hasEntryToday = entries.contains { calendar.isDate($0.date, inSameDayAs: today) }
        let startDay = hasEntryToday ? 0 : 1
        let maxDaysToCheck = entries.count + 1
        
        for i in startDay..<maxDaysToCheck {
            guard let expectedDate = calendar.date(byAdding: .day, value: -i, to: today) else { break }
            if entries.first(where: { calendar.isDate($0.date, inSameDayAs: expectedDate) }) != nil {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
}
