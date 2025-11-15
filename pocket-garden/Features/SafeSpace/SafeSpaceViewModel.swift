import Foundation
import SwiftUI
import SwiftData
import Observation

@Observable
class SafeSpaceViewModel {
    // Services
    let ambientSoundService = AmbientSoundService()

    // Current session
    var currentSession: CalmSession?
    var sessionStartTime: Date?
    var completedActivities: [String] = []

    // UI State
    var selectedActivity: CalmActivity?
    var isActivityActive: Bool = false
    var selectedAmbientSound: AmbientSoundType = .silent

    // Model context for persistence
    private var modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    // MARK: - Session Management

    func startSession(fromEmergency: Bool = true) {
        guard currentSession == nil else { return }

        let session = CalmSession(
            date: Date(),
            startedFromEmergency: fromEmergency
        )

        currentSession = session
        sessionStartTime = Date()
        completedActivities = []
    }

    func endSession() {
        guard let session = currentSession,
              let startTime = sessionStartTime else { return }

        // Calculate duration
        let duration = Date().timeIntervalSince(startTime)
        session.duration = duration
        session.activities = completedActivities
        session.ambientSound = selectedAmbientSound != .silent ? selectedAmbientSound.rawValue : nil

        // Save to SwiftData
        modelContext?.insert(session)
        try? modelContext?.save()

        // Reset
        currentSession = nil
        sessionStartTime = nil
        completedActivities = []
        ambientSoundService.stop()
    }

    // MARK: - Activity Management

    func startActivity(_ activity: CalmActivity) {
        selectedActivity = activity
        isActivityActive = true

        // Start session if not already started
        if currentSession == nil {
            startSession()
        }
    }

    func completeActivity(_ activity: CalmActivity) {
        completedActivities.append(activity.type.rawValue)
        isActivityActive = false
        selectedActivity = nil
    }

    func cancelActivity() {
        isActivityActive = false
        selectedActivity = nil
    }

    // MARK: - Ambient Sound Control

    func toggleAmbientSound(_ soundType: AmbientSoundType) {
        if selectedAmbientSound == soundType {
            selectedAmbientSound = .silent
            ambientSoundService.stop()
        } else {
            selectedAmbientSound = soundType
            ambientSoundService.play(soundType)
        }
    }

    func setAmbientSound(_ soundType: AmbientSoundType) {
        selectedAmbientSound = soundType
        ambientSoundService.play(soundType)
    }

    // MARK: - Analytics

    func getTotalSessions(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<CalmSession>()
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    func getRecentSessions(context: ModelContext, limit: Int = 10) -> [CalmSession] {
        var descriptor = FetchDescriptor<CalmSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    func getMostUsedActivity(context: ModelContext) -> String? {
        let sessions = getRecentSessions(context: context, limit: 50)
        let allActivities = sessions.flatMap { $0.activities }

        // Count frequency
        let activityCounts = allActivities.reduce(into: [:]) { counts, activity in
            counts[activity, default: 0] += 1
        }

        return activityCounts.max(by: { $0.value < $1.value })?.key
    }
}
