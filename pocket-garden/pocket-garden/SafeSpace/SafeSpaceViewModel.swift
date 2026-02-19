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
    var selectedAmbientSound: AmbientSoundType? = nil

    // Model context for persistence
    private var modelContext: ModelContext?

    // Tracks which sound was playing before the app became inactive,
    // so the icon state and audio can be restored when returning.
    private var soundBeforeInactive: AmbientSoundType? = nil

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        
        // Register this service as the active one for app lifecycle management
        AppLifecycleManager.shared.activeAmbientService = ambientSoundService
    }
    
    deinit {
        // Clean up when viewmodel is deallocated
        ambientSoundService.stopImmediate()
        AppLifecycleManager.shared.activeAmbientService = nil
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
        session.ambientSound = selectedAmbientSound?.rawValue

        // Save to SwiftData
        modelContext?.insert(session)
        try? modelContext?.save()

        // Reset
        currentSession = nil
        sessionStartTime = nil
        completedActivities = []
        ambientSoundService.stop()
    }

    // MARK: - Cleanup

    func cleanup() {
        // Fade out when user manually exits (smooth UX)
        ambientSoundService.fadeOutAndStop(duration: 0.8)
        endSession()
    }

    /// Called when the user switches away from the Sanctuary tab.
    /// Stops audio immediately and clears the icon state so sound buttons
    /// don't appear active (green) while audio is not playing.
    /// Unlike handleScenePhaseChange(.inactive), this does NOT save the sound
    /// for restoration — switching tabs is a deliberate action, not an interruption.
    func handleTabDeselected() {
        ambientSoundService.stop()
        selectedAmbientSound = nil
        // Also clear the restoration slot so a future app-resume doesn't
        // unexpectedly restart music the user has already left behind.
        soundBeforeInactive = nil
    }

    // Handle app lifecycle changes
    func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // Immediately stop audio — clear icon state so it reflects reality
            ambientSoundService.stopImmediate()
            soundBeforeInactive = nil
            selectedAmbientSound = nil
        case .inactive:
            // Save which sound was on so we can restore it when the app comes back,
            // then clear the icon immediately so it shows as off while audio is stopped.
            soundBeforeInactive = selectedAmbientSound
            selectedAmbientSound = nil
            ambientSoundService.stopImmediate()
        case .active:
            // Resume the sound that was playing before the app became inactive
            if let sound = soundBeforeInactive, currentSession != nil {
                selectedAmbientSound = sound
                ambientSoundService.play(sound) // Already fades in
                soundBeforeInactive = nil
            }
        @unknown default:
            break
        }
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
            selectedAmbientSound = nil
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
