//
//  NotificationService.swift
//  pocket-garden
//
//  Gentle Garden Push Notifications Service
//  Handles scheduling, permissions, and message generation.
//
//  Two gentle nudges per day — only delivered when the user
//  hasn't journaled yet. Times are randomised slightly each day
//  so the notifications never feel mechanical.
//

import Foundation
import UserNotifications
import SwiftData
internal import Combine

// MARK: - Notification Preferences

struct NotificationPreferences: Codable {
    var notificationsEnabled: Bool

    static let `default` = NotificationPreferences(notificationsEnabled: true)
}

// MARK: - Notification Service

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var preferences: NotificationPreferences {
        didSet { savePreferences() }
    }
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()
    private let preferencesKey = "notificationPreferences"

    // Fixed base hours — jitter is added at scheduling time
    private let firstReminderBaseHour  = 18 // 6:00 PM
    private let secondReminderBaseHour = 21 // 9:00 PM

    // Identifier prefixes — a date suffix is appended so each day's
    // pair is unique and old ones expire cleanly.
    private let firstReminderIDPrefix  = "garden.reminder.first."
    private let secondReminderIDPrefix = "garden.reminder.second."

    // MARK: - Initialization

    private init() {
        self.preferences = Self.loadPreferences()
        Task { await checkAuthorizationStatus() }
    }

    // MARK: - Persistence

    private static func loadPreferences() -> NotificationPreferences {
        guard let data = UserDefaults.standard.data(forKey: "notificationPreferences"),
              let prefs = try? JSONDecoder().decode(NotificationPreferences.self, from: data) else {
            return .default
        }
        return prefs
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
            title: "Remind in 30 min",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: "GARDEN_REMINDER",
            actions: [journalAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    // MARK: - Scheduling

    /// Schedule up to two reminders for today (and the next few days ahead)
    /// if the user hasn't journaled yet. Already-delivered IDs are left
    /// alone; only future ones are (re)scheduled.
    func scheduleNotifications(
        currentStreak: Int = 0,
        hasEntryToday: Bool = false,
        currentTreeType: String? = nil,
        treeProgress: Double? = nil
    ) async {
        // Remove any stale notifications from previous days
        await removeStalePendingNotifications()

        guard preferences.notificationsEnabled else { return }
        guard authorizationStatus == .authorized else { return }
        guard !hasEntryToday else {
            // User already journaled — no reminders needed today.
            await cancelTodaysReminders()
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Schedule for today only (called again on every app launch to refresh)
        for (prefix, baseHour) in [
            (firstReminderIDPrefix,  firstReminderBaseHour),
            (secondReminderIDPrefix, secondReminderBaseHour)
        ] {
            let dateKey = Self.dateKey(for: today)
            let identifier = prefix + dateKey

            // Skip if already pending
            let pending = await center.pendingNotificationRequests()
            if pending.contains(where: { $0.identifier == identifier }) { continue }

            // Add ±30 min jitter so the time never feels robotic
            let jitter = Int.random(in: -30...30)

            guard let fireDate = calendar.date(
                bySettingHour: baseHour,
                minute: 0,
                second: 0,
                of: today
            ).flatMap({
                calendar.date(byAdding: .minute, value: jitter, to: $0)
            }) else { continue }

            // Don't schedule for a time that has already passed today
            guard fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Pocket Forest 🌿"
            content.body = ReminderMessages.randomMessage(
                isFirstReminder: (baseHour == firstReminderBaseHour),
                streak: currentStreak,
                treeType: currentTreeType,
                treeProgress: treeProgress
            )
            content.sound = .default
            content.categoryIdentifier = "GARDEN_REMINDER"

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
            }
        }
    }

    // MARK: - Cancel Helpers

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func cancelEveningNotification() {
        // Legacy helper kept for call-site compatibility — now cancels today's second reminder
        let dateKey = Self.dateKey(for: Date())
        center.removePendingNotificationRequests(withIdentifiers: [secondReminderIDPrefix + dateKey])
    }

    /// Called when the user submits a journal entry — dismiss both today's reminders.
    func cancelTodayRemindersAfterEntry() {
        Task { await cancelTodaysReminders() }
    }

    private func cancelTodaysReminders() async {
        let dateKey = Self.dateKey(for: Date())
        center.removePendingNotificationRequests(withIdentifiers: [
            firstReminderIDPrefix  + dateKey,
            secondReminderIDPrefix + dateKey
        ])
    }

    /// Prune pending notifications from previous days (they'll never fire usefully)
    private func removeStalePendingNotifications() async {
        let pending = await center.pendingNotificationRequests()
        let todayKey = Self.dateKey(for: Date())

        let staleIDs = pending
            .map(\.identifier)
            .filter { id in
                (id.hasPrefix(firstReminderIDPrefix) || id.hasPrefix(secondReminderIDPrefix))
                && !id.hasSuffix(todayKey)
            }

        if !staleIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: staleIDs)
        }
    }

    // MARK: - Snooze

    func snoozeNotification(minutes: Int = 30) async {
        let content = UNMutableNotificationContent()
        content.title = "Pocket Forest 🌿"
        content.body = SnoozeMessages.random()
        content.sound = .default
        content.categoryIdentifier = "GARDEN_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "garden.snooze", content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
        }
    }

    // MARK: - Utilities

    private static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Reminder Messages

private enum ReminderMessages {

    // First reminder (~6 PM) — soft, encouraging, forward-looking
    static let earlyEvening: [String] = [
        "Hey, the garden's been waiting for you all day 🌿 How's your heart doing?",
        "The evening light is beautiful right now. Come sit with your thoughts for a minute?",
        "You've made it through the day — take a breath and tell your garden how it went 🍃",
        "A little check-in before dinner? Your garden grows one honest moment at a time 🌱",
        "The soft part of the day is here. How are you really doing?",
        "Even a tiny entry keeps the roots strong 🌳 What's on your mind today?",
        "Hey you — how was your day? Your garden wants to know 💚",
        "Before the evening gets away from you, a quiet moment with your thoughts?",
        "The trees in your garden stretch toward the last bit of sunlight. How are you feeling? 🌅",
        "One honest sentence is all it takes. What do you want to remember about today?",
        "Your garden misses your voice. Just a few words? 🌼",
        "The day isn't over yet — there's still time to tend to yourself 🌿"
    ]

    // Second reminder (~9 PM) — gentle, warm, nudging before bed
    static let lateEvening: [String] = [
        "Almost bedtime 🌙 Your garden is still here, soft and quiet, waiting for you.",
        "Before you drift off — how was your day really? Just a little note 💫",
        "The moon is up and your garden is peaceful. A few words before you rest?",
        "Ending the day with a little reflection makes tomorrow feel lighter 🍃",
        "Hey, it's getting late — don't let today go unnoticed. You matter 💚",
        "Your garden keeps a safe space for you, even at night 🌙 Come say hi?",
        "One small entry before bed keeps the streak alive and your heart a little lighter 🌱",
        "The day is quieting down. Your thoughts deserve a home tonight ✨",
        "Before sleep takes over — what was today's one thing worth remembering?",
        "Even a rough day is worth noting. Your garden holds it without judgment 🌿",
        "It's cozy in your garden tonight 🌙 What's on your heart before you sleep?",
        "You made it through today. That's worth writing down, don't you think? 💛"
    ]

    // Streak-aware additions
    static let streakEarly: [String] = [
        "🔥 %d days in a row — your garden is glowing. Keep it going tonight?",
        "Day %d of showing up for yourself. That's something to be proud of 💚",
        "%d days strong! A quick check-in keeps that beautiful streak alive 🌱"
    ]

    static let streakLate: [String] = [
        "Your %d-day streak ends at midnight — just a few words to keep it alive 🌙",
        "Day %d is almost done. Don't let it slip away without a little note 💫",
        "Almost midnight and your %d-day streak is still on the line 🔥 You've got this."
    ]

    // Tree-aware additions
    static let treeEarly: [String] = [
        "Your %@ has been soaking up the evening light. Ready to give it some love? 🌳",
        "The %@ in your garden is growing beautifully — let's keep it that way 🌿"
    ]

    static let treeLate: [String] = [
        "Your %@ is settling in for the night — one quick entry before you do too? 🌙",
        "Almost time to sleep, and your %@ is %d%% of the way there. Just a little more 💚"
    ]

    static func randomMessage(
        isFirstReminder: Bool,
        streak: Int,
        treeType: String?,
        treeProgress: Double?
    ) -> String {
        var pool = isFirstReminder ? earlyEvening : lateEvening

        // Weave in streak messages with 40% probability when streak > 3
        if streak > 3, Bool.random() || Bool.random() {
            let templates = isFirstReminder ? streakEarly : streakLate
            if let template = templates.randomElement() {
                pool.append(String(format: template, streak))
            }
        }

        // Weave in tree messages when there's an active tree
        if let tree = treeType {
            let treeName = TreeType(rawValue: tree)?.name ?? "tree"
            let templates = isFirstReminder ? treeEarly : treeLate

            if let template = templates.randomElement() {
                if template.contains("%d") {
                    let pct = Int((treeProgress ?? 0) * 100)
                    pool.append(String(format: template, treeName, pct))
                } else {
                    pool.append(String(format: template, treeName))
                }
            }
        }

        return pool.randomElement() ?? pool[0]
    }
}

// MARK: - Snooze Messages

private enum SnoozeMessages {
    static let messages = [
        "Still here, still rooting for you 🌿 Ready when you are.",
        "No rush — your garden waits patiently 🍃",
        "Whenever you're ready, your thoughts have a home here 💚",
        "Take your time. Your garden isn't going anywhere 🌱",
        "Just a gentle reminder — your garden is here for you ✨"
    ]

    static func random() -> String {
        messages.randomElement() ?? messages[0]
    }
}

// MARK: - Deferred Notification Prompt Coordinator

@MainActor
final class NotificationPromptCoordinator {
    static let shared = NotificationPromptCoordinator()

    private let firstTreePromptKey = "hasRequestedNotificationsAfterFirstTree"
    private var shouldRequestAfterSanctuaryCompletion = false

    private init() {}

    func deferRequestUntilSanctuaryCompletion() {
        shouldRequestAfterSanctuaryCompletion = true
    }

    func cancelDeferredRequest() {
        shouldRequestAfterSanctuaryCompletion = false
    }

    var hasDeferredRequest: Bool {
        shouldRequestAfterSanctuaryCompletion
    }

    func requestIfDeferredAfterSanctuaryCompletion() async {
        guard shouldRequestAfterSanctuaryCompletion else { return }
        shouldRequestAfterSanctuaryCompletion = false

        _ = await NotificationService.shared.requestAuthorization()
        UserDefaults.standard.set(true, forKey: firstTreePromptKey)
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
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case "JOURNAL_NOW", UNNotificationDefaultActionIdentifier:
            onNotificationTapped?()
        case "SNOOZE":
            Task { @MainActor in
                await NotificationService.shared.snoozeNotification(minutes: 30)
            }
        default:
            break
        }
        completionHandler()
    }
}
