//
//  AIPromptHelpers.swift
//  pocket-garden
//
//  Shared helpers for AI prompt construction and text processing.
//

import SwiftUI
import NaturalLanguage
import Foundation

// MARK: - Panda Feedback Model

struct PandaFeedback: Codable {
    let text: String
    let emotionHint: String
    let tags: [String]?
}

// MARK: - Language Detection

/// Languages officially supported by Apple Foundation Models (iOS 26)
let afmSupportedLanguages: Set<String> = [
    "en", "de", "es", "fr", "it", "ja", "ko", "pt", "zh-Hans", "zh-Hant", "tr"
]

func detectLanguageCode(from text: String) -> String? {
    guard !text.isEmpty else { return nil }
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    return recognizer.dominantLanguage?.rawValue
}

func detectLanguage(from text: String) -> String? {
    guard !text.isEmpty else { return nil }
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    guard let language = recognizer.dominantLanguage else { return nil }
    let locale = Locale(identifier: "en")
    return locale.localizedString(forLanguageCode: language.rawValue)
}

func isLanguageSupportedByAFM(_ text: String) -> Bool {
    guard let langCode = detectLanguageCode(from: text) else { return true }
    let baseCode = langCode.components(separatedBy: "-").first ?? langCode
    return afmSupportedLanguages.contains(langCode) || afmSupportedLanguages.contains(baseCode)
}

func languageInstruction(for text: String?) -> String {
    guard let text = text, !text.isEmpty,
          let detectedLanguage = detectLanguage(from: text),
          detectedLanguage.lowercased() != "english" else {
        return ""
    }

    return """

    CRITICAL LANGUAGE & RESPONSE RULES:
    - The user wrote in \(detectedLanguage). You MUST respond entirely in \(detectedLanguage).
    - DO NOT just paraphrase or summarize what the user wrote.
    - DO NOT restate their entry back to them.
    - You MUST provide ORIGINAL therapeutic feedback that:
      1. Validates their emotions with empathy
      2. Acknowledges specific details they mentioned
      3. Offers ONE helpful suggestion from the Sanctuary practices listed above
    - Your response should feel like a caring friend giving advice, NOT a summary of what they said.
    """
}

// MARK: - User Name Helpers

/// Trims and normalises a raw name string (collapses whitespace, removes empty parts).
func sanitizeUserName(_ raw: String) -> String {
    raw.trimmingCharacters(in: .whitespacesAndNewlines)
       .components(separatedBy: .whitespacesAndNewlines)
       .filter { !$0.isEmpty }
       .joined(separator: " ")
}

/// Returns prompt lines that inject the user's preferred name (or a guard against guessing).
func namePromptLines() -> [String] {
    let name = sanitizeUserName(UserDefaults.standard.string(forKey: "userFirstName") ?? "")
    if !name.isEmpty {
        return [
            "User's preferred first name: \(name)",
            "IMPORTANT: Use this name naturally when addressing the user. Never infer or invent names from journal content."
        ]
    }
    return ["IMPORTANT: Do not guess the user's name from journal content."]
}

// MARK: - Text Processing

func minimizeMarkdown(_ s: String) -> String {
    var out = s
    ["#", "##", "###", "####", "---"].forEach { out = out.replacingOccurrences(of: $0, with: "") }
    return out.trimmingCharacters(in: .whitespacesAndNewlines)
}

func extractTextFromResponse(_ raw: String) -> String {
    var cleaned = raw

    // Try to extract "text" field from JSON-like response
    if let start = cleaned.range(of: "\"text\":") {
        let afterKey = cleaned[start.upperBound...]
        if let openQuote = afterKey.firstIndex(of: "\"") {
            let contentStart = cleaned.index(after: openQuote)
            var idx = contentStart
            while idx < cleaned.endIndex {
                if cleaned[idx] == "\"" {
                    let prevIdx = cleaned.index(before: idx)
                    if prevIdx >= contentStart && cleaned[prevIdx] == "\\" {
                        idx = cleaned.index(after: idx)
                        continue
                    }
                    cleaned = String(cleaned[contentStart..<idx])
                    break
                }
                idx = cleaned.index(after: idx)
            }
        }
    }

    // Remove any remaining JSON artifacts that might leak through
    let artifactsToRemove = [
        "emotionHint:", "\"emotionHint\":",
        "tags:", "\"tags\":",
        "/10", "supportive", "proud", "concerned",
        "{", "}", "[", "]"
    ]
    for artifact in artifactsToRemove {
        if cleaned.contains(artifact) && cleaned.count < 300 {
            cleaned = cleaned.replacingOccurrences(of: artifact, with: "")
        }
    }

    if let range = cleaned.range(of: "emotionHint", options: .caseInsensitive) {
        cleaned = String(cleaned[..<range.lowerBound])
    }

    return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
}

// MARK: - Sanctuary Items

/// Dictionary of all Sanctuary practices with descriptions used in AI prompts.
let sanctuaryItems: [String: String] = [
    "Breathing Exercise": "A short guided breathing reset to calm your nervous system and steady your focus",
    "Grounding Technique": "A 5-4-3-2-1 sensory grounding technique to anchor yourself in the present moment",
    "Muscle Relaxation": "A gentle body-based release to soften tension and help your body feel safer",
    "Gentle Affirmations": "Supportive self-compassion statements to quiet harsh self-talk",
    "Three Good Moments": "A savoring exercise where you reflect on three positive moments from your day",
    "Worry Tree": "A guided decision tree to process worries by identifying what you can and cannot control",
]

/// Legacy Sanctuary practices kept here only as explicit "inactive" metadata.
let inactiveSanctuaryItems: [String] = [
    "Safe Place Visualization",
    "Box Breathing",
    "4-7-8 Breath",
    "Coherent Breathing",
    "Calming Breath"
]

/// Formats sanctuary items for inclusion in AFM prompts
func sanctuaryItemsForPrompt() -> String {
    var lines: [String] = ["SANCTUARY PRACTICES (always mention 'in Sanctuary' when suggesting):"]
    for (name, description) in sanctuaryItems.sorted(by: { $0.key < $1.key }) {
        lines.append("- \(name): \(description)")
    }
    lines.append("")
    lines.append("INACTIVE LEGACY PRACTICES (DO NOT SUGGEST): \(inactiveSanctuaryItems.sorted().joined(separator: ", "))")
    return lines.joined(separator: "\n")
}

/// Returns just the names of sanctuary items as a comma-separated list
func sanctuaryItemNames() -> String {
    sanctuaryItems.keys.sorted().joined(separator: ", ")
}

// MARK: - Crisis Detection

let crisisIndicators = [
    "want to die", "kill myself", "end it all", "end my life",
    "no reason to live", "better off dead", "suicide",
    "don't want to be here", "can't go on", "give up on life",
    "hurt myself", "self harm", "cutting myself",
    "take my own life", "suicidal", "not worth living",
    "want to disappear", "can't take it anymore", "rather be dead",
    "planning to end", "goodbye letter", "final goodbye",
    "harming myself", "self-harm", "overdose",
    "no one would miss me", "world without me",
    "done with life", "ending things"
]

func detectCrisis(in text: String?) -> Bool {
    guard let text = text?.lowercased() else { return false }
    return crisisIndicators.contains { text.contains($0) }
}

func crisisResponse() -> String {
    let name = sanitizeUserName(UserDefaults.standard.string(forKey: "userFirstName") ?? "")
    let greeting = name.isEmpty ? "I hear you" : "I hear you, \(name)"
    return """
    \(greeting), and I'm really glad you shared this with me. What you're feeling \
    is real and valid, and you don't have to carry it alone.\n\n\
    Please reach out to someone who can help:\n\n\
    \u{1F4DE} 988 Suicide & Crisis Lifeline \u{2014} Call or text 988 (US)\n\
    \u{1F4AC} Crisis Text Line \u{2014} Text HOME to 741741\n\
    \u{1F30D} International Crisis Lines \u{2014} findahelpline.com\n\n\
    You matter, and there are people who want to help. If you're in immediate danger, \
    please call your local emergency services \u{1F499}
    """
}

// MARK: - Sanctuary Deep Link

struct SanctuaryDeepLink: Equatable {
    let mentionPhrase: String
    let activityType: ActivityType
    let breathingPattern: BreathingPattern?

    init(phrase: String, activityType: ActivityType, breathingPattern: BreathingPattern? = nil) {
        self.mentionPhrase = phrase
        self.activityType = activityType
        self.breathingPattern = breathingPattern
    }
}

let allSanctuaryDeepLinks: [SanctuaryDeepLink] = [
    SanctuaryDeepLink(phrase: "breathing exercise",  activityType: .breathing, breathingPattern: .boxBreathing),
    SanctuaryDeepLink(phrase: "breathing",           activityType: .breathing, breathingPattern: .boxBreathing),
    SanctuaryDeepLink(phrase: "grounding exercise",        activityType: .grounding),
    SanctuaryDeepLink(phrase: "grounding technique",       activityType: .grounding),
    SanctuaryDeepLink(phrase: "grounding",                 activityType: .grounding),
    SanctuaryDeepLink(phrase: "body scan",                 activityType: .bodyScan),
    SanctuaryDeepLink(phrase: "muscle relaxation",         activityType: .bodyScan),
    SanctuaryDeepLink(phrase: "three good moments",        activityType: .nameAndSoothe),
    SanctuaryDeepLink(phrase: "good moments",              activityType: .nameAndSoothe),
    SanctuaryDeepLink(phrase: "worry tree",                activityType: .worryTree),
    SanctuaryDeepLink(phrase: "affirmations",              activityType: .affirmations),
    SanctuaryDeepLink(phrase: "gentle affirmations",       activityType: .affirmations),
]
