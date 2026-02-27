//
//  PandaFeedbackService.swift
//  pocket-garden
//
//  AI-powered journal entry feedback using Apple Foundation Models.
//

import Foundation
import SwiftData
import NaturalLanguage
#if canImport(FoundationModels)
import FoundationModels
#endif

final class PandaFeedbackService {
    static let shared = PandaFeedbackService()
    private init() {}

    func generate(for entry: EmotionEntry, recentHints: [String]) async -> (text: String, emotion: MascotEmotion, usedAFM: Bool) {
        if detectCrisis(in: entry.transcription) {
            return (crisisResponse(), .concerned, false)
        }

        if #available(iOS 26.0, *), PandaFoundationManager.shared.isAvailable {
            if let afm = await generateWithAFM(entry: entry, recentHints: recentHints) {
                let mapped = mapEmotion(hint: afm.emotionHint, rating: entry.emotionRating)
                let clamped = clampEmotion(mapped, rating: entry.emotionRating)
                return (afm.text, clamped, true)
            }
        }
        let local = BumblebeeLocalFeedbackEngine.shared.generate(entry: entry)
        return (local.text, local.emotion, false)
    }

    private func mapEmotion(hint: String, rating: Int) -> MascotEmotion {
        let h = hint.lowercased()
        if h.contains("happy") || h.contains("proud") { return .happy }
        if h.contains("support") || h.contains("encourage") { return .supportive }
        if h.contains("concern") || h.contains("tough") || h.contains("hard") { return .concerned }
        if h.contains("thinking") { return .thinking }
        if h.contains("sleep") { return .sleeping }
        if h.contains("neutral") { return .neutral }
        return MascotEmotion.from(rating: rating)
    }

    private func clampEmotion(_ emotion: MascotEmotion, rating: Int) -> MascotEmotion {
        guard rating >= 8 else { return emotion }
        switch emotion {
        case .happy, .proud:
            return emotion
        default:
            return .happy
        }
    }

    private func buildPrompt(entry: EmotionEntry, recentHints: [String]) -> String {
        var lines: [String] = []
        lines.append("User's emotion rating: \(entry.emotionRating)/10")
        lines.append(contentsOf: namePromptLines())
        if let t = entry.transcription, !t.isEmpty {
            lines.append("\nUser's journal entry:")
            lines.append("\"\(t.prefix(1200))\"")
            let langInstruction = languageInstruction(for: t)
            if !langInstruction.isEmpty {
                lines.append(langInstruction)
            }
        }
        if !recentHints.isEmpty {
            lines.append("\nYour recent replies (vary your wording and avoid repeating these):")
            recentHints.prefix(5).forEach { lines.append("- \($0.prefix(200))") }

            let recentPractices = recentHints.compactMap { hint -> String? in
                for item in sanctuaryItems.keys {
                    if hint.lowercased().contains(item.lowercased()) { return item }
                }
                return nil
            }
            if !recentPractices.isEmpty {
                lines.append("\nSanctuary practices you recently suggested (try a different one): \(recentPractices.joined(separator: ", "))")
            }
        }
        lines.append("\nRespond with valid JSON: {\"text\": \"...\", \"emotionHint\": \"...\", \"tags\": [...]}")
        return lines.joined(separator: "\n")
    }

    private func instructionsText() -> String {
        let practices = sanctuaryItemNames()
        return "You are Bumblebee, a warm and thoughtful emotional wellness companion. Read the user's emotion rating and journal entry carefully. In your response (3–5 sentences, max 75 words):\n1. Always take the emotion rating into account together with the text.\n2. If the rating is 8, 9, or 10 out of 10, the overall tone MUST be clearly celebratory and proud. You may briefly acknowledge remaining stress, but focus mainly on what went well and why the user feels capable or hopeful.\n3. If the rating is 4–7, use a balanced, supportive tone that recognizes both difficulties and strengths.\n4. If the rating is 1–3, use a very gentle, compassionate tone and avoid minimizing their experience.\n5. Acknowledge at least one concrete detail they mentioned so it feels specific.\n6. Offer exactly one gentle, actionable suggestion (no long lists).\n7. When it fits, let that suggestion be one specific practice from the user's Sanctuary space in the app (available practices: \(practices)). Mention \"in Sanctuary\" so they know where to go.\n8. If you suggest a Sanctuary practice, name exactly one practice only. Never offer alternatives, lists, slash options, or \"X or Y\" wording.\n9. Use warm, conversational language and vary your phrasing each time.\n10. Never diagnose, give medical advice, or repeat recent responses.\n11. If the user expresses thoughts of self-harm or suicide, respond with deep compassion and include crisis resources: 988 Lifeline (call/text 988), Crisis Text Line (text HOME to 741741), findahelpline.com for international help.\n\nMake it feel personal and genuine, not scripted."
    }

    @MainActor
    private func generateWithAFM(entry: EmotionEntry, recentHints: [String]) async -> PandaFeedback? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = PandaSessionManager.shared.getSession()
            let promptText = buildPrompt(entry: entry, recentHints: recentHints)
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

                let userInput = entry.transcription ?? ""
                if !userInput.isEmpty {
                    let validation = await PandaOutputValidator.shared.validate(
                        output: feedbackText,
                        input: userInput,
                        context: "journal"
                    )

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
}
