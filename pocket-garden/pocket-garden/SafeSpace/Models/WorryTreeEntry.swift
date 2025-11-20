import Foundation
import SwiftData

@Model
class WorryTreeEntry {
    var id: UUID
    var date: Date
    var worryText: String
    var canControl: Bool?
    var actionPlan: String?
    var letGoNote: String?
    var pandaFeedback: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        worryText: String,
        canControl: Bool?,
        actionPlan: String? = nil,
        letGoNote: String? = nil,
        pandaFeedback: String? = nil
    ) {
        self.id = id
        self.date = date
        self.worryText = worryText
        self.canControl = canControl
        self.actionPlan = actionPlan
        self.letGoNote = letGoNote
        self.pandaFeedback = pandaFeedback
    }
}
