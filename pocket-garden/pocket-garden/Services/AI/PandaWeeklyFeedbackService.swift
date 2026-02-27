//
//  PandaWeeklyFeedbackService.swift
//  pocket-garden
//
//  Extracted from GardenMascot.swift
//

import Foundation
import SwiftData
import NaturalLanguage

#if canImport(FoundationModels)
import FoundationModels
#endif

final class PandaWeeklyFeedbackService {
    static let shared = PandaWeeklyFeedbackService()
    private init() {}

    /// Generate a weekly Panda message from multiple entries. Uses Apple Intelligence
    /// when available, with a local on-device fallback otherwise.
    func generate(for entries: [EmotionEntry]) async -> (text: String, usedAFM: Bool) {
        guard !entries.isEmpty else {
            let text = "This week is just getting started. Each check\u{2011}in you make helps me understand how you're doing, and I'm here whenever you want to share more. \u{1F331}"
            return (text, false)
        }

        if #available(iOS 26.0, *), PandaFoundationManager.shared.isAvailable {
            if let afm = await generateWithAFM(entries: entries) {
                return (afm.text, true)
            }
        }

        let local = generateLocal(for: entries)
        return (local, false)
    }

    @MainActor
    private func generateWithAFM(entries: [EmotionEntry]) async -> PandaFeedback? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = PandaSessionManager.shared.getSession()
            let promptText = buildWeeklyPrompt(entries: entries)
            do {
                let response = try await session.respond(to: promptText)
                let rawText = response.content

                var feedbackText: String
                var emotionHint: String = "supportive"
                var tags: [String]? = nil

                if let data = rawText.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(PandaFeedback.self, from: data) {
                    feedbackText = minimizeMarkdown(decoded.text)
                    emotionHint = decoded.emotionHint
                    tags = decoded.tags
                } else {
                    feedbackText = minimizeMarkdown(extractTextFromResponse(rawText))
                }

                // Validate the generated output
                let combinedInput = entries.compactMap { $0.cleanedTranscription ?? $0.transcription }.joined(separator: " ")
                if !combinedInput.isEmpty {
                    let validation = await PandaOutputValidator.shared.validate(
                        output: feedbackText,
                        input: combinedInput,
                        context: "weekly"
                    )

                    // Use corrected output if validation failed but correction succeeded
                    if !validation.isValid, let corrected = validation.correctedOutput {
                        feedbackText = corrected
                    }
                }

                return PandaFeedback(
                    text: feedbackText,
                    emotionHint: emotionHint,
                    tags: tags
                )
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }

    private func generateLocal(for entries: [EmotionEntry]) -> String {
        let calendar = Calendar.current
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"

        let ratings = entries.map { $0.emotionRating }
        let avgRating = Double(ratings.reduce(0, +)) / Double(max(ratings.count, 1))

        // Find one recent entry with text for a concrete detail
        let textEntry = entries
            .sorted(by: { $0.date > $1.date })
            .first(where: { !($0.cleanedTranscription?.isEmpty ?? $0.transcription?.isEmpty ?? true) })

        var detailLine = ""
        if let e = textEntry {
            let day = dayFormatter.string(from: e.date)
            let snippet = (e.cleanedTranscription ?? e.transcription ?? "").prefix(120)
            if !snippet.isEmpty {
                detailLine = " For example, on \(day) you shared: \"\(snippet)\"."
            }
        }

        let checkInCount = Set(entries.map { calendar.startOfDay(for: $0.date) }).count

        let base: String
        switch avgRating {
        case 8...10:
            base = "You've had a really bright week so far, with lots of moments of good energy and emotional strength."
        case 6..<8:
            base = "This week has a steady, gently positive rhythm. You're noticing what supports your wellbeing and showing up for yourself."
        case 4..<6:
            base = "This week has been a mix of easier and tougher moments, but you keep checking in and that takes courage."
        default:
            base = "It's been a heavy week so far, and I can tell you've been carrying a lot. Thank you for being honest in your check\u{2011}ins."
        }

        let consistency: String
        switch checkInCount {
        case 5...:
            consistency = " You've checked in on most days, which is an amazing act of self\u{2011}care."
        case 3...4:
            consistency = " You've checked in on several days, and that consistency really matters."
        case 1...2:
            consistency = " Even a couple of check\u{2011}ins this week are meaningful steps in understanding how you're feeling."
        default:
            consistency = ""
        }

        let suggestion: String
        switch avgRating {
        case 8...10:
            suggestion = " This weekend, consider writing down one or two things that have been working especially well, so you can return to them when you need a boost. If you'd like, you could also spend a few minutes with Three Good Moments in Sanctuary to help you really soak it in."
        case 6..<8:
            suggestion = " Over the next few days, try repeating one small habit that helped you feel a bit more grounded\u{2014}like a short walk, a mindful pause, or journaling before bed. You might also choose one quick Breathing Exercise in Sanctuary when you want a small reset."
        case 4..<6:
            suggestion = " In the coming days, choose one tiny act of kindness toward yourself\u{2014}something that feels doable, like a five\u{2011}minute break or a gentle walk. When you feel up for it, you could try a short Muscle Relaxation in Sanctuary to give your system a gentler pace."
        default:
            suggestion = " For the rest of this week, see if you can give yourself permission to move slowly and choose just one small thing that feels supportive, even if it's simply taking a deeper breath. If it helps, you might spend a few minutes with Gentle Affirmations in Sanctuary."
        }

        return base + consistency + detailLine + " " + suggestion
    }

    private func buildWeeklyPrompt(entries: [EmotionEntry]) -> String {
        var lines: [String] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"

        // Detect dominant language from entries
        let allText = entries.compactMap { $0.cleanedTranscription ?? $0.transcription }.joined(separator: " ")
        let langInstruction = languageInstruction(for: allText)

        lines.append("You are Bumblebee, a warm and thoughtful emotional wellness companion.")
        lines.append(contentsOf: namePromptLines())
        lines.append("You are reading the user's journal entries for this week so far (from the start of the week up to today). In your response:")
        lines.append("- Write 3\u{2013}6 sentences, maximum 120 words.")
        lines.append("- Clearly refer to 'this week' or 'this week so far'.")
        lines.append("- Acknowledge at least one concrete detail from their entries so it feels specific.")
        lines.append("- Describe any noticeable pattern in how they have been feeling.")
        lines.append("- Offer exactly one gentle, actionable suggestion for the coming days.")
        lines.append("- When it fits, let that suggestion be one specific practice from the user's Sanctuary space in the app (available practices: \(sanctuaryItemNames())). Mention \"in Sanctuary\" so they know where to go.")
        lines.append("- If you suggest a Sanctuary practice, name exactly one practice only. Never use alternatives such as 'or', lists, or multiple options.")
        lines.append("- Use warm, conversational language and never give medical advice.")
        if !langInstruction.isEmpty {
            lines.append(langInstruction)
        }
        lines.append("")
        lines.append("Here are the entries for this week:")

        for entry in entries {
            let day = formatter.string(from: entry.date)
            let rating = entry.emotionRating
            let text = (entry.cleanedTranscription ?? entry.transcription ?? "").prefix(240)
            if !text.isEmpty {
                lines.append("- \(day) \u{2014} rating \(rating)/10: \"\(text)\"")
            } else {
                lines.append("- \(day) \u{2014} rating \(rating)/10.")
            }
        }

        lines.append("")
        lines.append("Respond with valid JSON: {\"text\": \"...\", \"emotionHint\": \"...\", \"tags\": [...]}")
        return lines.joined(separator: "\n")
    }
}
