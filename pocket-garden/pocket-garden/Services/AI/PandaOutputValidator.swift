//
//  PandaOutputValidator.swift
//  pocket-garden
//
//  Validates AFM outputs to ensure they are quality therapeutic feedback,
//  not paraphrasing or repetition.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Output Validation Service

/// Validates AFM outputs to ensure they are quality therapeutic feedback, not paraphrasing or repetition
@available(iOS 26.0, *)
final class PandaOutputValidator {
    static let shared = PandaOutputValidator()
    private init() {}

    /// Result of output validation
    struct ValidationResult {
        let isValid: Bool
        let reason: String?
        let correctedOutput: String?
    }

    /// Validate an AFM-generated output against the original input
    /// - Parameters:
    ///   - output: The generated feedback text
    ///   - input: The original user input (journal entry, worry text, etc.)
    ///   - context: Type of feedback for context-aware validation ("journal", "weekly", "savoring", "worry_tree")
    /// - Returns: ValidationResult with validity status and optional corrected output
    func validate(
        output: String,
        input: String,
        context: String
    ) async -> ValidationResult {
        // Step 1: Quick local checks (fast, no AFM call needed)
        let localCheck = performLocalValidation(output: output, input: input)
        if !localCheck.isValid {
            // If local check fails badly, try to get a corrected version from AFM
            if let corrected = await generateCorrectedOutput(
                originalInput: input,
                badOutput: output,
                context: context,
                failureReason: localCheck.reason ?? "paraphrasing detected"
            ) {
                return ValidationResult(isValid: false, reason: localCheck.reason, correctedOutput: corrected)
            }
            return localCheck
        }

        // Step 2: AFM-based quality validation (more thorough)
        let afmCheck = await performAFMValidation(output: output, input: input, context: context)
        if !afmCheck.isValid {
            if let corrected = await generateCorrectedOutput(
                originalInput: input,
                badOutput: output,
                context: context,
                failureReason: afmCheck.reason ?? "low quality feedback"
            ) {
                return ValidationResult(isValid: false, reason: afmCheck.reason, correctedOutput: corrected)
            }
        }

        return afmCheck
    }

    // MARK: - Local Validation (Fast Checks)

    private func performLocalValidation(output: String, input: String) -> ValidationResult {
        let normalizedOutput = normalize(output)
        let normalizedInput = normalize(input)
        let lowerOutput = output.lowercased()

        // Check 0: Safety check - harmful content in output
        let harmfulPhrases = [
            "kill yourself", "end your life", "you should die", "better off dead",
            "nobody cares about you", "you're worthless", "you're pathetic",
            "just give up", "there's no hope", "you deserve to suffer",
            "you're a loser", "you're stupid", "you're an idiot",
            "shut up", "nobody likes you", "you're disgusting"
        ]
        for phrase in harmfulPhrases {
            if lowerOutput.contains(phrase) {
                return ValidationResult(
                    isValid: false,
                    reason: "Output contains harmful content",
                    correctedOutput: nil
                )
            }
        }

        // Check 0b: Safety check - dismissive/toxic positivity patterns
        let dismissivePatterns = [
            "just think positive", "just be happy", "stop being sad",
            "get over it", "it's not that bad", "others have it worse",
            "you're overreacting", "calm down", "stop complaining"
        ]
        for pattern in dismissivePatterns {
            if lowerOutput.contains(pattern) {
                return ValidationResult(
                    isValid: false,
                    reason: "Output contains dismissive or toxic positivity",
                    correctedOutput: nil
                )
            }
        }

        // Check 1: Jaccard similarity (word overlap)
        let jaccardSim = jaccardSimilarity(normalizedOutput, normalizedInput)
        if jaccardSim > 0.65 {
            return ValidationResult(
                isValid: false,
                reason: "Output has too much word overlap with input (similarity: \(Int(jaccardSim * 100))%)",
                correctedOutput: nil
            )
        }

        // Check 2: N-gram overlap (phrase copying)
        let trigramOverlap = ngramOverlap(normalizedOutput, normalizedInput, n: 3)
        if trigramOverlap > 0.40 {
            return ValidationResult(
                isValid: false,
                reason: "Output contains too many copied phrases from input",
                correctedOutput: nil
            )
        }

        // Check 3: Length ratio check (output shouldn't be much longer than reasonable feedback)
        let outputWords = normalizedOutput.split(separator: " ").count
        if outputWords < 15 {
            return ValidationResult(
                isValid: false,
                reason: "Output is too short to be meaningful feedback",
                correctedOutput: nil
            )
        }

        // Check 4: Detect if output starts by restating the input
        let inputStart = String(normalizedInput.prefix(50))
        let outputStart = String(normalizedOutput.prefix(100))
        if outputStart.contains(inputStart) && inputStart.count > 20 {
            return ValidationResult(
                isValid: false,
                reason: "Output starts by restating the user's input",
                correctedOutput: nil
            )
        }

        return ValidationResult(isValid: true, reason: nil, correctedOutput: nil)
    }

    // MARK: - AFM-Based Validation

    @MainActor
    private func performAFMValidation(output: String, input: String, context: String) async -> ValidationResult {
        #if canImport(FoundationModels)
        guard PandaFoundationManager.shared.isAvailable else {
            return ValidationResult(isValid: true, reason: nil, correctedOutput: nil)
        }

        // Detect language for instructions
        let detectedLang = detectLanguage(from: input) ?? "the user's language"

        let validationPrompt = buildValidationPrompt(
            output: output,
            input: input,
            context: context,
            language: detectedLang
        )

        do {
            let session = LanguageModelSession(instructions: """
                You are a quality assurance assistant for an emotional wellness app called Pocket Forest.
                Your job is to evaluate whether AI-generated feedback is helpful and appropriate.

                Respond ONLY with valid JSON in this exact format:
                {"valid": true/false, "reason": "explanation if invalid"}
                """)

            let response = try await session.respond(to: validationPrompt)
            let rawText = response.content

            // Parse validation response
            if let data = rawText.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let isValid = json["valid"] as? Bool {
                let reason = json["reason"] as? String
                return ValidationResult(isValid: isValid, reason: reason, correctedOutput: nil)
            }

            // Fallback: check for obvious keywords
            let lower = rawText.lowercased()
            if lower.contains("\"valid\": false") || lower.contains("\"valid\":false") {
                return ValidationResult(isValid: false, reason: "AFM validation failed", correctedOutput: nil)
            }

            return ValidationResult(isValid: true, reason: nil, correctedOutput: nil)
        } catch {
            // On error, assume valid to avoid blocking
            return ValidationResult(isValid: true, reason: nil, correctedOutput: nil)
        }
        #else
        return ValidationResult(isValid: true, reason: nil, correctedOutput: nil)
        #endif
    }

    // MARK: - Corrected Output Generation

    @MainActor
    private func generateCorrectedOutput(
        originalInput: String,
        badOutput: String,
        context: String,
        failureReason: String
    ) async -> String? {
        #if canImport(FoundationModels)
        guard PandaFoundationManager.shared.isAvailable else { return nil }

        let detectedLang = detectLanguage(from: originalInput) ?? "the user's language"
        let langCode = detectLanguageCode(from: originalInput) ?? "en"

        let correctionPrompt = buildCorrectionPrompt(
            originalInput: originalInput,
            badOutput: badOutput,
            context: context,
            failureReason: failureReason,
            language: detectedLang,
            languageCode: langCode
        )

        do {
            let session = LanguageModelSession(instructions: """
                You are Bumblebee, a warm and thoughtful emotional wellness companion.
                Your task is to provide CORRECTED feedback that avoids the mistakes of a previous response.

                CRITICAL RULES:
                - DO NOT paraphrase or summarize what the user wrote
                - DO NOT restate their entry back to them
                - Provide ORIGINAL therapeutic feedback with empathy and one actionable suggestion
                - Respond in the SAME LANGUAGE as the user's input
                - Keep response to 3-5 sentences, max 75 words
                """)

            let response = try await session.respond(to: correctionPrompt)
            var corrected = response.content

            // Extract text if JSON format
            if corrected.contains("\"text\":") {
                if let data = corrected.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = json["text"] as? String {
                    corrected = text
                }
            }

            // Clean markdown
            corrected = minimizeMarkdown(corrected)

            // Verify the correction is actually better
            let correctedCheck = performLocalValidation(output: corrected, input: originalInput)
            if correctedCheck.isValid {
                return corrected
            }

            return nil
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }

    // MARK: - Prompt Builders

    private func buildValidationPrompt(output: String, input: String, context: String, language: String) -> String {
        """
        Evaluate if this AI-generated feedback is quality therapeutic support (NOT a summary or paraphrase).

        CONTEXT: \(contextDescription(context))
        USER'S LANGUAGE: \(language)

        USER'S ORIGINAL INPUT:
        "\(input.prefix(800))"

        AI-GENERATED FEEDBACK:
        "\(output)"

        VALIDATION CRITERIA - Mark as INVALID if:
        1. The feedback mostly just restates or paraphrases what the user wrote
        2. The feedback is a summary of the user's entry
        3. The feedback lacks empathy or emotional validation
        4. The feedback doesn't offer any supportive suggestion
        5. The feedback is in a different language than the user's input
        6. The feedback sounds robotic or impersonal

        Mark as VALID if:
        1. The feedback acknowledges the user's emotions with genuine empathy
        2. The feedback provides ORIGINAL supportive commentary (not just rewording their text)
        3. The feedback includes at least one helpful, actionable suggestion
        4. The feedback is in the same language as the user's input
        5. The feedback sounds warm and conversational

        Respond with JSON: {"valid": true/false, "reason": "explanation if invalid"}
        """
    }

    private func buildCorrectionPrompt(
        originalInput: String,
        badOutput: String,
        context: String,
        failureReason: String,
        language: String,
        languageCode: String
    ) -> String {
        """
        A previous AI response was rejected because: \(failureReason)

        CONTEXT: \(contextDescription(context))

        USER'S ORIGINAL INPUT (in \(language)):
        "\(originalInput.prefix(800))"

        REJECTED RESPONSE (DO NOT REPEAT THIS PATTERN):
        "\(badOutput.prefix(400))"

        Please generate a NEW, CORRECTED response that:
        1. Is written entirely in \(language)
        2. Does NOT paraphrase or summarize the user's input
        3. DOES validate the user's emotions with genuine empathy
        4. DOES acknowledge one specific detail they mentioned
        5. DOES offer ONE gentle, actionable suggestion (from Sanctuary if appropriate: \(sanctuaryItemNames()))
        6. Sounds warm, personal, and conversational
        7. Is 3-5 sentences, max 75 words

        Respond ONLY with the corrected feedback text (no JSON, no quotes).
        """
    }

    private func contextDescription(_ context: String) -> String {
        switch context {
        case "journal":
            return "Voice journal entry feedback - user recorded how they're feeling"
        case "weekly":
            return "Weekly insight - summarizing the user's emotional patterns this week"
        case "savoring":
            return "Three Good Moments exercise - user listed positive moments from their day"
        case "worry_tree":
            return "Worry Tree exercise - user worked through a worry they're experiencing"
        default:
            return "Emotional wellness feedback"
        }
    }

    // MARK: - Text Similarity Helpers

    private func normalize(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: .punctuationCharacters).joined()
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
    }

    private func jaccardSimilarity(_ a: String, _ b: String) -> Double {
        let wordsA = Set(a.split(separator: " ").map { String($0) })
        let wordsB = Set(b.split(separator: " ").map { String($0) })

        guard !wordsA.isEmpty || !wordsB.isEmpty else { return 0 }

        let intersection = wordsA.intersection(wordsB).count
        let union = wordsA.union(wordsB).count

        return Double(intersection) / Double(union)
    }

    private func ngramOverlap(_ a: String, _ b: String, n: Int) -> Double {
        let wordsA = a.split(separator: " ").map { String($0) }
        let wordsB = b.split(separator: " ").map { String($0) }

        guard wordsA.count >= n && wordsB.count >= n else { return 0 }

        var ngramsA = Set<String>()
        for i in 0...(wordsA.count - n) {
            let ngram = wordsA[i..<(i+n)].joined(separator: " ")
            ngramsA.insert(ngram)
        }

        var ngramsB = Set<String>()
        for i in 0...(wordsB.count - n) {
            let ngram = wordsB[i..<(i+n)].joined(separator: " ")
            ngramsB.insert(ngram)
        }

        guard !ngramsA.isEmpty else { return 0 }

        let overlap = ngramsA.intersection(ngramsB).count
        return Double(overlap) / Double(ngramsA.count)
    }
}
