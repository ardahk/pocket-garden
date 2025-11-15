import Foundation
import SwiftData

@Model
class CalmSession {
    var id: UUID
    var date: Date
    var activities: [String] // Activity types completed
    var duration: TimeInterval
    var ambientSound: String?
    var startedFromEmergency: Bool // Analytics
    var emotionBefore: Int? // Optional: emotion rating before session
    var emotionAfter: Int? // Optional: emotion rating after session

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        activities: [String] = [],
        duration: TimeInterval = 0,
        ambientSound: String? = nil,
        startedFromEmergency: Bool = true,
        emotionBefore: Int? = nil,
        emotionAfter: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.activities = activities
        self.duration = duration
        self.ambientSound = ambientSound
        self.startedFromEmergency = startedFromEmergency
        self.emotionBefore = emotionBefore
        self.emotionAfter = emotionAfter
    }
}
