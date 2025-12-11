//
//  pocket_gardenApp.swift
//  pocket-garden
//
//  Created by Arda Hoke on 11/6/25.
//

import SwiftUI
import SwiftData
import UserNotifications

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
    @State private var shouldOpenJournal = false
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([EmotionEntry.self, GrowingTree.self, Quote.self, Achievement.self, CalmSession.self, WorryTreeEntry.self])
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
                } else {
                    OnboardingView()
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: hasCompletedOnboarding)
            .onAppear {
                setupNotificationHandler()
            }
            .onChange(of: scenePhase) { _, newPhase in
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
