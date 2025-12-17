//
//  NotificationService.swift
//  pocket-garden
//
//  Gentle Garden Push Notifications Service
//  Handles scheduling, permissions, and message generation
//

import Foundation
import UserNotifications
import SwiftData
internal import Combine

// MARK: - Notification Preferences

struct NotificationPreferences: Codable {
    var notificationsEnabled: Bool
    var morningEnabled: Bool
    var eveningEnabled: Bool
    var morningHour: Int
    var morningMinute: Int
    var eveningHour: Int
    var eveningMinute: Int
    
    static let `default` = NotificationPreferences(
        notificationsEnabled: true,
        morningEnabled: true,
        eveningEnabled: true,
        morningHour: 9,
        morningMinute: 0,
        eveningHour: 20,
        eveningMinute: 0
    )
    
    var morningTime: Date {
        get {
            Calendar.current.date(from: DateComponents(hour: morningHour, minute: morningMinute)) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            morningHour = components.hour ?? 9
            morningMinute = components.minute ?? 0
        }
    }
    
    var eveningTime: Date {
        get {
            Calendar.current.date(from: DateComponents(hour: eveningHour, minute: eveningMinute)) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            eveningHour = components.hour ?? 20
            eveningMinute = components.minute ?? 0
        }
    }
}

// MARK: - Notification Service

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var preferences: NotificationPreferences {
        didSet {
            savePreferences()
        }
    }
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let center = UNUserNotificationCenter.current()
    private let preferencesKey = "notificationPreferences"
    
    // Notification identifiers
    private let morningNotificationID = "garden.morning.reminder"
    private let eveningNotificationID = "garden.evening.reminder"
    
    // MARK: - Initialization
    
    private init() {
        self.preferences = Self.loadPreferences()
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Persistence
    
    private static func loadPreferences() -> NotificationPreferences {
        guard let data = UserDefaults.standard.data(forKey: "notificationPreferences"),
              let preferences = try? JSONDecoder().decode(NotificationPreferences.self, from: data) else {
            return .default
        }
        return preferences
    }
    
    private func savePreferences() {
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: preferencesKey)
        }
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            
            if granted {
                await registerNotificationCategories()
                await scheduleNotifications()
            }
            
            return granted
        } catch {
            print("❌ Notification authorization error: \(error)")
            return false
        }
    }
    
    private func registerNotificationCategories() async {
        let journalAction = UNNotificationAction(
            identifier: "JOURNAL_NOW",
            title: "Journal Now",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Remind Later",
            options: []
        )
        
        let gardenCategory = UNNotificationCategory(
            identifier: "GARDEN_REMINDER",
            actions: [journalAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([gardenCategory])
    }
    
    // MARK: - Scheduling
    
    func scheduleNotifications(
        currentStreak: Int = 0,
        hasEntryToday: Bool = false,
        currentTreeType: String? = nil,
        treeProgress: Double? = nil
    ) async {
        // Cancel existing notifications first
        center.removePendingNotificationRequests(withIdentifiers: [morningNotificationID, eveningNotificationID])
        
        guard preferences.notificationsEnabled else { return }
        guard authorizationStatus == .authorized else { return }
        
        // Schedule morning notification
        if preferences.morningEnabled {
            await scheduleMorningNotification(
                currentStreak: currentStreak,
                currentTreeType: currentTreeType
            )
        }
        
        // Schedule evening notification (only if no entry today)
        if preferences.eveningEnabled && !hasEntryToday {
            await scheduleEveningNotification(
                currentStreak: currentStreak,
                currentTreeType: currentTreeType,
                treeProgress: treeProgress
            )
        }
    }
    
    private func scheduleMorningNotification(
        currentStreak: Int,
        currentTreeType: String?
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Pocket Forest 🌱"
        content.body = MorningMessages.randomMessage(
            streak: currentStreak,
            treeType: currentTreeType
        )
        content.sound = .default
        content.categoryIdentifier = "GARDEN_REMINDER"
        
        var dateComponents = DateComponents()
        dateComponents.hour = preferences.morningHour
        dateComponents.minute = preferences.morningMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: morningNotificationID, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            print("✅ Morning notification scheduled for \(preferences.morningHour):\(String(format: "%02d", preferences.morningMinute))")
        } catch {
            print("❌ Failed to schedule morning notification: \(error)")
        }
    }
    
    private func scheduleEveningNotification(
        currentStreak: Int,
        currentTreeType: String?,
        treeProgress: Double?
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "Pocket Forest 🌙"
        content.body = EveningMessages.randomMessage(
            streak: currentStreak,
            treeType: currentTreeType,
            treeProgress: treeProgress
        )
        content.sound = .default
        content.categoryIdentifier = "GARDEN_REMINDER"
        
        var dateComponents = DateComponents()
        dateComponents.hour = preferences.eveningHour
        dateComponents.minute = preferences.eveningMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: eveningNotificationID, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            print("✅ Evening notification scheduled for \(preferences.eveningHour):\(String(format: "%02d", preferences.eveningMinute))")
        } catch {
            print("❌ Failed to schedule evening notification: \(error)")
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        print("🔕 All notifications cancelled")
    }
    
    func cancelEveningNotification() {
        center.removePendingNotificationRequests(withIdentifiers: [eveningNotificationID])
        print("🔕 Evening notification cancelled (user journaled today)")
    }
    
    // MARK: - Snooze
    
    func snoozeNotification(minutes: Int = 30) async {
        let content = UNMutableNotificationContent()
        content.title = "Pocket Forest 🌿"
        content.body = "Your garden is still waiting for you. Just a few words?"
        content.sound = .default
        content.categoryIdentifier = "GARDEN_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "garden.snooze", content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            print("✅ Snooze notification scheduled for \(minutes) minutes")
        } catch {
            print("❌ Failed to schedule snooze notification: \(error)")
        }
    }
}

// MARK: - Morning Messages

private enum MorningMessages {
    static let general = [
        "Good morning! ☀️ Your garden is bathed in sunlight. Ready to plant today's seeds?",
        "A new day, a new chance to grow 🌱 Time for reflection?",
        "The morning dew has settled on your garden. How are you feeling today?",
        "Rise and shine! Your peaceful garden awaits your visit 🌿",
        "Good morning! A moment of reflection can set the tone for your whole day.",
        "The sun is up and your garden is ready. How's your heart today? 💚",
        "Morning light filters through the leaves. Take a breath and check in.",
        "🌅 A fresh start awaits. Your garden grows with every word you share.",
        "The birds are singing in your garden. Time for your morning reflection?",
        "Good morning! Even a small seed of thought can grow into something beautiful.",
        "Your garden has been waiting patiently. Ready to tend to your thoughts?",
        "New day, new growth 🌻 What's blooming in your mind today?",
        "The morning air is crisp in your garden. Perfect time for journaling.",
        "🌞 Sunshine and self-care go hand in hand. How are you feeling?",
        "Another beautiful day in your pocket forest. Time to check in?"
    ]
    
    static let streakMessages = [
        "🔥 %d days strong! Your garden is thriving. Keep the momentum going!",
        "Day %d of your growth journey. Your garden is getting stronger!",
        "%d days of consistent care 🌳 Your forest is flourishing!",
        "Amazing! %d days in a row. Your dedication is beautiful to see.",
        "Your %d-day streak is incredible! The garden thanks you 💚",
        "%d days of growth! You're cultivating something special here."
    ]
    
    static let treeMessages = [
        "A new day, a new chance to grow. Your %@ is waiting 🌳",
        "Your %@ could use some morning sunlight and care.",
        "Good morning! Your %@ stretches toward the sun ☀️",
        "Your %@ is growing beautifully. Time to nurture it today?",
        "The %@ in your garden sways gently, waiting for you."
    ]
    
    static func randomMessage(streak: Int, treeType: String?) -> String {
        var pool: [String] = general
        
        // Add streak-specific messages if streak > 3
        if streak > 3 {
            let streakMsg = streakMessages.randomElement()!
            pool.append(String(format: streakMsg, streak))
        }
        
        // Add tree-specific messages if there's an active tree
        if let tree = treeType {
            let treeName = TreeType(rawValue: tree)?.name ?? "tree"
            let treeMsg = treeMessages.randomElement()!
            pool.append(String(format: treeMsg, treeName))
        }
        
        return pool.randomElement() ?? general[0]
    }
}

// MARK: - Evening Messages

private enum EveningMessages {
    static let general = [
        "Your seedling could use some water before the day ends 💧",
        "The garden is quiet tonight. A few words before bed?",
        "Before the day closes, take a moment for yourself.",
        "Your garden misses you. Even a brief visit helps it grow.",
        "The evening breeze whispers through your garden. Time to reflect?",
        "🌜 The moon is rising over your garden. How was your day?",
        "Wind down with a moment of reflection. Your garden awaits.",
        "The stars are coming out ✨ Perfect time for evening thoughts.",
        "Before sleep, nurture your garden with a few gentle words.",
        "Your plants are settling in for the night. Join them for a moment?",
        "Evening peace awaits in your garden 🍃 Care to visit?",
        "The day is winding down. Your garden is a safe space to reflect.",
        "🌸 Soft evening light fills your garden. Time for a check-in?",
        "One small entry before bed keeps your garden growing strong.",
        "The fireflies are out in your garden tonight ✨ Come say hello?"
    ]
    
    static let streakAtRisk = [
        "⏰ Your %d-day garden streak ends at midnight. Don't let it wilt!",
        "Streak alert! 🔥 %d days of growth are on the line tonight.",
        "Your %d-day streak needs one more watering before midnight 💧",
        "Keep the flame alive! 🔥 Day %d is waiting for you.",
        "Just a quick visit? Your %d-day streak is counting on you!",
        "Your garden's %d-day streak is almost through another day! 🌟"
    ]
    
    static let treeProgress = [
        "Your %@ has grown %d%% 🌱 One more watering to keep it healthy!",
        "Your %@ is %d%% grown. A little care tonight?",
        "The %@ in your garden is %d%% of the way there! 🌳",
        "Almost there! Your %@ is at %d%% growth 💚",
        "Your %@ needs just a bit more love — currently %d%% grown!"
    ]
    
    static func randomMessage(streak: Int, treeType: String?, treeProgress: Double?) -> String {
        var pool: [String] = general
        
        // Add streak-at-risk messages if streak > 3
        if streak > 3 {
            let riskMsg = streakAtRisk.randomElement()!
            pool.append(String(format: riskMsg, streak))
        }
        
        // Add tree progress messages if there's an active tree with progress
        if let tree = treeType, let progress = treeProgress, progress > 0 && progress < 1 {
            let treeName = TreeType(rawValue: tree)?.name ?? "tree"
            let progressPercent = Int(progress * 100)
            let progressMsg = self.treeProgress.randomElement()!
            pool.append(String(format: progressMsg, treeName, progressPercent))
        }
        
        return pool.randomElement() ?? general[0]
    }
}

// MARK: - Notification Delegate Handler

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    var onNotificationTapped: (() -> Void)?
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case "JOURNAL_NOW", UNNotificationDefaultActionIdentifier:
            // User tapped notification or "Journal Now" action
            onNotificationTapped?()
            
        case "SNOOZE":
            // Snooze for 30 minutes
            Task { @MainActor in
                await NotificationService.shared.snoozeNotification(minutes: 30)
            }
            
        default:
            break
        }
        
        completionHandler()
    }
}
