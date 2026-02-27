//
//  PandaSavoringService.swift
//  pocket-garden
//
//  Extracted from GardenMascot.swift
//

import Foundation
import NaturalLanguage

#if canImport(FoundationModels)
import FoundationModels
#endif

final class PandaSavoringService {
    static let shared = PandaSavoringService()
    private init() {}

    /// Generate a short reflection on the user's three good moments.
    /// Uses Apple Intelligence when available, with a simple local fallback.
    func generate(
        moments: [String],
        focusMoment: String?,
        detail: String?
    ) async -> (text: String, usedAFM: Bool) {
        let trimmed = moments.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !trimmed.isEmpty else {
            let text = "Even pausing to look for good moments is a quiet kind of self-care. You can always come back and add more when you're ready."
            return (text, false)
        }

        if #available(iOS 26.0, *), PandaFoundationManager.shared.isAvailable {
            if let afm = await generateWithAFM(moments: trimmed, focusMoment: focusMoment, detail: detail) {
                return (afm.text, true)
            }
        }

        let local = generateLocal(moments: trimmed, focusMoment: focusMoment, detail: detail)
        return (local, false)
    }

    @MainActor
    private func generateWithAFM(
        moments: [String],
        focusMoment: String?,
        detail: String?
    ) async -> PandaFeedback? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = PandaSessionManager.shared.getSession()
            let promptText = buildPrompt(moments: moments, focusMoment: focusMoment, detail: detail)
            do {
                let response = try await session.respond(to: promptText)
                let rawText = response.content

                var feedbackText: String
                var emotionHint: String = "supportive"
                var tags: [String]? = ["savoring"]

                if let data = rawText.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(PandaFeedback.self, from: data) {
                    feedbackText = minimizeMarkdown(decoded.text)
                    emotionHint = decoded.emotionHint
                    tags = decoded.tags
                } else {
                    feedbackText = minimizeMarkdown(extractTextFromResponse(rawText))
                }

                // Validate the generated output
                var inputParts: [String] = [moments.joined(separator: " ")]
                inputParts.append(focusMoment ?? "")
                inputParts.append(detail ?? "")
                let combinedInput = inputParts.joined(separator: " ")

                if !combinedInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let validation = await PandaOutputValidator.shared.validate(
                        output: feedbackText,
                        input: combinedInput,
                        context: "savoring"
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

    private func generateLocal(
        moments: [String],
        focusMoment: String?,
        detail: String?
    ) -> String {
        let listed = moments.prefix(3).map { "\u{2022} \($0)" }.joined(separator: " ")
        var base = "You just named a few good moments: \(listed). Even tiny bits of okayness help balance out your day."

        if let focus = focusMoment?.trimmingCharacters(in: .whitespacesAndNewlines), !focus.isEmpty {
            base += " One that stands out is: \(focus)."
        }

        if let d = detail?.trimmingCharacters(in: .whitespacesAndNewlines), !d.isEmpty {
            base += " The way you described it\u{2014}\"\(d.prefix(160))\"\u{2014}is something you can mentally return to when you need a small lift."
        }

        base += " Coming back to these moments now and then can gently train your brain to notice what supports you. When you want to reconnect with this feeling, you could run a short Three Good Moments in Sanctuary."
        return base
    }

    private func buildPrompt(
        moments: [String],
        focusMoment: String?,
        detail: String?
    ) -> String {
        var lines: [String] = []

        // Detect language from moments and detail
        let allText = moments.joined(separator: " ") + " " + (focusMoment ?? "") + " " + (detail ?? "")
        let langInstruction = languageInstruction(for: allText)

        lines.append("You are Bumblebee, a warm and thoughtful emotional wellness companion.")
        lines.append(contentsOf: namePromptLines())
        lines.append("The user has just completed a 'Three Good Moments' savoring exercise in a wellbeing app.")
        lines.append("")
        lines.append("Their moments:")
        for (index, m) in moments.prefix(3).enumerated() {
            lines.append("- Moment \(index + 1): \(m)")
        }
        if let focus = focusMoment, !focus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("\nMoment they chose to zoom in on: \(focus)")
        }
        if let d = detail, !d.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("\nTheir description of that moment: \"\(d.prefix(220))\"")
        }

        lines.append("")
        lines.append("In your response:")
        lines.append("- Write 3\u{2013}5 sentences, maximum 90 words.")
        lines.append("- Gently reinforce that noticing good moments is meaningful, even when the day is mixed.")
        lines.append("- Highlight 1\u{2013}2 specific details from their moments so it feels personal.")
        lines.append("- Offer exactly one simple suggestion for how they might revisit or build on these moments later.")
        lines.append("- When it fits, suggest one Sanctuary practice that matches the feeling of their moments (available practices: \(sanctuaryItemNames())). Mention \"in Sanctuary\" so they know where to go.")
        lines.append("- If you suggest a Sanctuary practice, name exactly one practice only. Never use 'or', lists, or multiple Sanctuary options.")
        lines.append("- Use warm, conversational language and never give medical advice.")
        if !langInstruction.isEmpty {
            lines.append(langInstruction)
        }
        lines.append("")
        lines.append("Respond with valid JSON of the form: {\"text\": \"...\", \"emotionHint\": \"supportive\", \"tags\": [\"savoring\"]}")
        return lines.joined(separator: "\n")
    }
}
