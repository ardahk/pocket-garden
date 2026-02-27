//
//  PandaWorryTreeService.swift
//  pocket-garden
//
//  Extracted from GardenMascot.swift
//

import Foundation
import NaturalLanguage

#if canImport(FoundationModels)
import FoundationModels
#endif

final class PandaWorryTreeService {
    static let shared = PandaWorryTreeService()
    private init() {}

    /// Generate Bumblebee feedback for a completed Worry Tree.
    /// Uses Apple Intelligence when available, with a simple local fallback.
    func generate(
        worryText: String,
        canControl: Bool?,
        actionPlan: String?,
        letGoNote: String?,
        historySummary: String
    ) async -> (text: String, usedAFM: Bool) {
        if #available(iOS 26.0, *), PandaFoundationManager.shared.isAvailable {
            if let afm = await generateWithAFM(
                worryText: worryText,
                canControl: canControl,
                actionPlan: actionPlan,
                letGoNote: letGoNote,
                historySummary: historySummary
            ) {
                return (afm.text, true)
            }
        }

        let local = generateLocal(
            worryText: worryText,
            canControl: canControl,
            actionPlan: actionPlan,
            letGoNote: letGoNote
        )
        return (local, false)
    }

    @MainActor
    private func generateWithAFM(
        worryText: String,
        canControl: Bool?,
        actionPlan: String?,
        letGoNote: String?,
        historySummary: String
    ) async -> PandaFeedback? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = PandaSessionManager.shared.getSession()
            let promptText = buildWorryTreePrompt(
                worryText: worryText,
                canControl: canControl,
                actionPlan: actionPlan,
                letGoNote: letGoNote,
                historySummary: historySummary
            )

            do {
                let response = try await session.respond(to: promptText)
                let rawText = response.content

                var feedbackText: String
                var emotionHint: String = "supportive"
                var tags: [String]? = ["worry_tree"]

                if let data = rawText.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(PandaFeedback.self, from: data) {
                    feedbackText = minimizeMarkdown(decoded.text)
                    emotionHint = decoded.emotionHint
                    tags = decoded.tags
                } else {
                    feedbackText = minimizeMarkdown(extractTextFromResponse(rawText))
                }

                // Validate the generated output
                var inputParts: [String] = [worryText]
                if let plan = actionPlan { inputParts.append(plan) }
                if let note = letGoNote { inputParts.append(note) }
                let combinedInput = inputParts.joined(separator: " ")

                if !combinedInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let validation = await PandaOutputValidator.shared.validate(
                        output: feedbackText,
                        input: combinedInput,
                        context: "worry_tree"
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
        worryText: String,
        canControl: Bool?,
        actionPlan: String?,
        letGoNote: String?
    ) -> String {
        var lines: [String] = []
        lines.append("Thank you for walking through this worry. That alone is a big step.")

        if let canControl = canControl {
            if canControl, let plan = actionPlan, !plan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lines.append("You identified something you can influence and even sketched a plan. Try choosing just one tiny step from your plan to focus on next.")
                lines.append("Remember, you don't have to fix everything at once\u{2014}small, realistic actions are enough.")
                lines.append("Your worry was: \(worryText)")
                lines.append("Your next gentle step might be: \(plan.prefix(160))")
            } else if !canControl {
                lines.append("You noticed that this worry is largely outside your control, which is hard and also very wise.")
                if let note = letGoNote, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    lines.append("The way you chose to let go\u{2014}'\(note.prefix(160))'\u{2014}is a powerful act of self-care.")
                }
                lines.append("When this worry shows up again, gently remind yourself what is and isn't yours to carry.")
            }
        }

        lines.append("If you'd like a bit more support after this, you might spend a few minutes with the Grounding Technique in Sanctuary.")

        return lines.joined(separator: " ")
    }

    private func buildWorryTreePrompt(
        worryText: String,
        canControl: Bool?,
        actionPlan: String?,
        letGoNote: String?,
        historySummary: String
    ) -> String {
        var lines: [String] = []

        // Detect language from worry text and notes
        let allText = worryText + " " + (actionPlan ?? "") + " " + (letGoNote ?? "")
        let langInstruction = languageInstruction(for: allText)

        lines.append("You are Bumblebee, a warm, practical emotional support companion.")
        lines.append(contentsOf: namePromptLines())
        lines.append("The user has just completed a 'Worry Tree' exercise in a wellbeing app.")
        lines.append("")
        lines.append("Your goals in this context:")
        lines.append("- Acknowledge the specific worry and how hard it feels.")
        lines.append("- Briefly reflect on what the user can and cannot control.")
        lines.append("- Help them turn their insights into gentle, realistic next steps that support their goals.")
        lines.append("- If they created an action plan, refine it into 1\u{2013}3 tiny, concrete steps they can actually do.")
        lines.append("- If the worry is outside their control, focus on acceptance, self-compassion, and shifting attention back to what they can influence.")
        lines.append("- Optionally, connect to patterns you notice from previous Worry Tree entries without overwhelming them.")
        lines.append("- Gently suggest exactly one practice from the Sanctuary space that could help them unwind or feel safer (available practices: \(sanctuaryItemNames())). Mention \"in Sanctuary\" so they know where to go.")
        lines.append("- If you suggest a Sanctuary practice, name exactly one practice only. Never use alternatives like 'or', slash options, or multiple practice names.")
        lines.append("- Never give medical advice or make diagnoses. Stay supportive, non-clinical, and non-judgmental.")
        if !langInstruction.isEmpty {
            lines.append(langInstruction)
        }
        lines.append("")
        lines.append("Response format:")
        lines.append("- 3\u{2013}7 sentences.")
        lines.append("- Maximum ~150 words.")
        lines.append("- Use warm, conversational language, as if talking directly to the user.")
        lines.append("- Always sound encouraging and realistic\u{2014}no toxic positivity.")
        lines.append("- End with that Sanctuary suggestion in a friendly, encouraging tone.")
        lines.append("")
        lines.append("Here is the current Worry Tree result:")
        lines.append("- Worry: \(worryText)")
        if let canControl = canControl {
            lines.append("- User believes they can control some part of this: \(canControl ? "yes" : "no")")
        }
        if let actionPlan, !actionPlan.isEmpty {
            lines.append("- Action plan (user's own words): \(actionPlan)")
        }
        if let letGoNote, !letGoNote.isEmpty {
            lines.append("- Let-go note (how they plan to release this): \(letGoNote)")
        }
        lines.append("")
        lines.append("Recent Worry Tree history (most recent first, may be empty):")
        lines.append(historySummary.isEmpty ? "(no previous entries)" : historySummary)
        lines.append("")
        lines.append("Now respond with valid JSON of the form:")
        lines.append("{\"text\": \"...\", \"emotionHint\": \"supportive\", \"tags\": [\"worry_tree\", \"goals\"]}")

        return lines.joined(separator: "\n")
    }
}
