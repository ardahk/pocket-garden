//
//  BumblebeeLocalFeedbackEngine.swift
//  pocket-garden
//
//  On-device fallback feedback engine when Apple Intelligence is unavailable.
//

import Foundation
import SwiftData
import NaturalLanguage

final class BumblebeeLocalFeedbackEngine {
    static let shared = BumblebeeLocalFeedbackEngine()
    private init() {}

    func generate(entry: EmotionEntry) -> (text: String, emotion: MascotEmotion) {
        let text = entry.transcription ?? ""
        let sentiment = sentimentScore(for: text)
        let emotion = blendedEmotion(rating: entry.emotionRating, sentiment: sentiment)
        let msg = message(for: emotion, topics: keywords(from: text))
        return (msg, emotion)
    }

    private func sentimentScore(for text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let tag = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0
        return Double(tag?.rawValue ?? "0") ?? 0
    }

    private func blendedEmotion(rating: Int, sentiment: Double) -> MascotEmotion {
        if rating <= 4 || sentiment < -0.5 { return .concerned }
        if rating >= 8 || sentiment > 0.5 { return .happy }
        return .supportive
    }

    private func keywords(from text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
        tagger.string = text
        var nouns = Set<String>()
        let range = text.startIndex..<text.endIndex
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            if let tag = tag, tag == .noun {
                let lemmaTag = tagger.tag(at: tokenRange.lowerBound, unit: .word, scheme: .lemma)
                let lemma = lemmaTag.0?.rawValue ?? String(text[tokenRange])
                nouns.insert(lemma.lowercased())
            }
            return true
        }
        return Array(nouns.prefix(3))
    }

    private func message(for emotion: MascotEmotion, topics: [String]) -> String {
        let topic = topics.first ?? "what you're experiencing"
        let variations: [[String]] = [
            ["Love this energy! ", "This is wonderful! ", "So glad to hear this! "],
            ["I hear how \(topic) is affecting you. ", "It sounds like \(topic) has been on your mind. ", "I can sense \(topic) is important right now. "],
            ["That sounds really tough with \(topic). ", "I can feel the weight of \(topic) in your words. ", "\(topic.capitalized) can be so challenging. "]
        ]

        switch emotion {
        case .happy:
            let opening = variations[0].randomElement()!
            return "\(opening)It's clear something positive happened today. Consider jotting down what made this moment special\u{2014}it helps us recreate these feelings. What small thing brought you joy? If you'd like to keep the glow going, you could also spend a few minutes with Three Good Moments in Sanctuary. \u{1F31F}"
        case .supportive:
            let opening = variations[1].randomElement()!
            return "\(opening)Your feelings are completely valid. When things feel uncertain, try this: take three slow breaths, then name one thing you can control right now. Sometimes the smallest step forward is enough. If you want a bit more support, you might try the Grounding Technique in Sanctuary. \u{1F49A}"
        case .concerned:
            let opening = variations[2].randomElement()!
            return "\(opening)I'm right here with you. When everything feels heavy, let's ground together: place your feet flat, take a slow breath, and name five things you can see. You don't have to carry this alone. If it feels okay, you could also spend a few minutes with Muscle Relaxation in Sanctuary. \u{1F917}"
        default:
            return "Thanks for sharing your thoughts with me. Taking time to check in with yourself matters, and I'm here for every step of your journey."
        }
    }
}
