//
//  AppleIntelligenceService.swift
//  pocket-garden
//
//  AI Feedback Generation using Natural Language Framework
//

import Foundation
import NaturalLanguage

class AppleIntelligenceService {

    // MARK: - Singleton

    static let shared = AppleIntelligenceService()

    private init() {}

    // MARK: - Main Feedback Generation

    /// Generate personalized AI feedback based on entry
    func generateFeedback(for entry: EmotionEntry) async -> String {
        guard let transcription = entry.transcription, !transcription.isEmpty else {
            return generateRatingBasedFeedback(rating: entry.emotionRating)
        }

        // Analyze sentiment
        let sentiment = analyzeSentiment(text: transcription)

        // Extract key themes
        let themes = extractThemes(from: transcription)

        // Detect emotional tone
        let emotionalTone = detectEmotionalTone(from: transcription, sentiment: sentiment)

        // Generate contextual feedback
        return generateContextualFeedback(
            rating: entry.emotionRating,
            sentiment: sentiment,
            themes: themes,
            emotionalTone: emotionalTone,
            transcription: transcription
        )
    }

    // MARK: - Sentiment Analysis

    /// Analyze sentiment of text using NaturalLanguage framework
    func analyzeSentiment(text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)

        if let sentimentScore = sentiment?.rawValue,
           let score = Double(sentimentScore) {
            return score // Returns -1.0 (negative) to 1.0 (positive)
        }

        return 0.0
    }

    // MARK: - Theme Extraction

    /// Extract key themes and topics from text
    func extractThemes(from text: String) -> [String] {
        var themes: [String] = []

        // Use linguistic tagger to find named entities and nouns
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = text

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if let tag = tag, tag == .noun {
                let noun = String(text[tokenRange]).lowercased()
                if noun.count > 3 && !themes.contains(noun) { // Filter short words
                    themes.append(noun)
                }
            }
            return true
        }

        // Also check for common emotional keywords
        let emotionalKeywords = detectEmotionalKeywords(in: text)
        themes.append(contentsOf: emotionalKeywords)

        return Array(themes.prefix(5)) // Return top 5 themes
    }

    // MARK: - Emotional Tone Detection

    func detectEmotionalTone(from text: String, sentiment: Double) -> EmotionalTone {
        let lowercasedText = text.lowercased()

        // Keywords for different emotional tones
        let joyKeywords = ["happy", "joy", "excited", "amazing", "wonderful", "love", "great", "fantastic", "awesome", "glad", "grateful", "blessed"]
        let calmKeywords = ["calm", "peaceful", "relaxed", "serene", "content", "comfortable", "easy", "gentle", "quiet"]
        let anxiousKeywords = ["anxious", "worried", "nervous", "stressed", "overwhelmed", "pressure", "tense", "uneasy", "afraid", "concerned"]
        let sadKeywords = ["sad", "down", "depressed", "disappointed", "hurt", "lonely", "empty", "broken", "lost", "hopeless"]
        let gratefulKeywords = ["grateful", "thankful", "blessed", "appreciate", "fortunate", "lucky", "value"]
        let reflectiveKeywords = ["thinking", "reflect", "realize", "understand", "learn", "grow", "journey", "process"]

        var scores: [EmotionalTone: Int] = [
            .joyful: 0,
            .calm: 0,
            .anxious: 0,
            .sad: 0,
            .grateful: 0,
            .reflective: 0
        ]

        // Count keyword matches
        for word in joyKeywords where lowercasedText.contains(word) { scores[.joyful, default: 0] += 1 }
        for word in calmKeywords where lowercasedText.contains(word) { scores[.calm, default: 0] += 1 }
        for word in anxiousKeywords where lowercasedText.contains(word) { scores[.anxious, default: 0] += 1 }
        for word in sadKeywords where lowercasedText.contains(word) { scores[.sad, default: 0] += 1 }
        for word in gratefulKeywords where lowercasedText.contains(word) { scores[.grateful, default: 0] += 1 }
        for word in reflectiveKeywords where lowercasedText.contains(word) { scores[.reflective, default: 0] += 1 }

        // Adjust scores based on sentiment
        if sentiment > 0.3 {
            scores[.joyful, default: 0] += 2
            scores[.grateful, default: 0] += 1
        } else if sentiment < -0.3 {
            scores[.sad, default: 0] += 2
            scores[.anxious, default: 0] += 1
        }

        // Return tone with highest score
        if let maxTone = scores.max(by: { $0.value < $1.value }), maxTone.value > 0 {
            return maxTone.key
        }

        // Default based on sentiment
        if sentiment > 0.2 {
            return .joyful
        } else if sentiment < -0.2 {
            return .sad
        } else {
            return .reflective
        }
    }

    // MARK: - Emotional Keywords

    private func detectEmotionalKeywords(in text: String) -> [String] {
        let lowercasedText = text.lowercased()
        var keywords: [String] = []

        let emotionalWords = [
            "family", "friends", "work", "health", "relationship",
            "achievement", "challenge", "growth", "change", "future",
            "past", "present", "self", "others", "nature"
        ]

        for word in emotionalWords {
            if lowercasedText.contains(word) {
                keywords.append(word)
            }
        }

        return keywords
    }

    // MARK: - Contextual Feedback Generation

    func generateContextualFeedback(
        rating: Int,
        sentiment: Double,
        themes: [String],
        emotionalTone: EmotionalTone,
        transcription: String
    ) -> String {
        // Select appropriate feedback template based on multiple factors
        let templates = FeedbackTemplates.getTemplates(
            for: rating,
            tone: emotionalTone,
            sentiment: sentiment
        )

        var feedback = templates.randomElement() ?? "You're on a meaningful journey. Every step counts. 🌱"

        // Personalize with themes if available
        if !themes.isEmpty {
            let themeAddition = generateThemeResponse(themes: themes, rating: rating)
            if !themeAddition.isEmpty {
                feedback += " " + themeAddition
            }
        }

        return feedback
    }

    // MARK: - Theme Response

    private func generateThemeResponse(themes: [String], rating: Int) -> String {
        guard themes.first != nil else { return "" }

        // Create contextual responses based on themes
        let themeResponses: [String: [String]] = [
            "work": [
                "Your dedication to your work shows great commitment.",
                "Finding balance with work is part of growth.",
                "Remember to celebrate your professional achievements."
            ],
            "family": [
                "Family connections are precious roots in your garden.",
                "The love you share with family nourishes growth.",
                "Family moments create lasting memories."
            ],
            "friends": [
                "Friendship is a beautiful source of support.",
                "Your social connections strengthen you.",
                "Cherish these meaningful relationships."
            ],
            "health": [
                "Taking care of your health is self-love.",
                "Your wellbeing is worth prioritizing.",
                "Physical and mental health bloom together."
            ],
            "nature": [
                "Nature has a way of restoring balance.",
                "Connection with nature feeds the soul.",
                "The natural world reflects our inner growth."
            ]
        ]

        for (key, responses) in themeResponses {
            if themes.contains(key) {
                return responses.randomElement() ?? ""
            }
        }

        return ""
    }

    // MARK: - Rating-Based Feedback

    private func generateRatingBasedFeedback(rating: Int) -> String {
        let templates = FeedbackTemplates.getTemplates(for: rating, tone: .reflective, sentiment: 0.0)
        return templates.randomElement() ?? "You're growing stronger every day. 🌱"
    }
}

// MARK: - Emotional Tone

enum EmotionalTone {
    case joyful
    case calm
    case anxious
    case sad
    case grateful
    case reflective
}

// MARK: - Feedback Templates

struct FeedbackTemplates {
    static func getTemplates(for rating: Int, tone: EmotionalTone, sentiment: Double) -> [String] {
        // High ratings (8-10)
        if rating >= 8 {
            switch tone {
            case .joyful:
                return [
                    "Your joy is absolutely radiant! This happiness is a beautiful flower in your garden. Keep nurturing these wonderful moments! 🌸✨",
                    "What a magnificent day! Your positive energy is contagious. You're blooming beautifully! 🌟",
                    "Your enthusiasm shines through! These joyful moments are the sunshine your garden needs. 🌞",
                    "Incredible! You're experiencing such vibrant joy. Let this happiness nourish your roots. 💫"
                ]
            case .grateful:
                return [
                    "Your gratitude is a powerful force for growth. These appreciative moments strengthen your roots deeply. 🙏🌱",
                    "What a beautiful perspective! Gratitude makes everything bloom more brilliantly. ✨",
                    "Your thankful heart creates fertile soil for happiness. Keep cultivating this appreciation. 💚"
                ]
            case .calm:
                return [
                    "Such beautiful peace! This calm contentment is a sign of deep roots and strong growth. 🌿",
                    "Your serenity is inspiring. Peaceful moments like these help your garden flourish quietly. ☮️",
                    "This tranquil joy shows real emotional balance. You're cultivating inner peace beautifully. 🍃"
                ]
            default:
                return [
                    "You're doing wonderfully! Keep celebrating these bright moments. 🌟",
                    "This positive energy is beautiful! Your garden is thriving. 🌺",
                    "What growth! You're blooming magnificently. Keep nurturing this joy. 🌸"
                ]
            }
        }

        // Medium-high ratings (6-7)
        else if rating >= 6 {
            switch tone {
            case .reflective:
                return [
                    "You're in a thoughtful space right now, and that's valuable. Reflection helps us grow stronger and wiser. 🌳",
                    "This balanced perspective shows maturity. You're tending your garden with care and wisdom. 🌿",
                    "Taking time to process and reflect is part of healthy growth. You're doing important work. 💭"
                ]
            case .calm:
                return [
                    "This steady, calm energy is wonderful. Consistent care helps gardens flourish over time. 🌱",
                    "Your balanced approach is serving you well. Steady growth is lasting growth. 🍃",
                    "Such peaceful contentment! You're creating sustainable happiness. 🌾"
                ]
            case .grateful:
                return [
                    "Even in ordinary moments, you find gratitude. That's the mark of a well-tended heart. 💚",
                    "Your appreciation for the simple things strengthens your roots. Beautiful perspective. 🌿",
                    "Gratitude in the everyday is powerful magic for your garden. ✨"
                ]
            default:
                return [
                    "You're finding balance, and that's beautiful. Every day is a new seed of possibility. 🌿",
                    "This steady energy shows you're tending your garden well. Keep going! 🌱",
                    "You're growing at your own pace, and that's perfect. Trust the process. 🌳"
                ]
            }
        }

        // Medium-low ratings (4-5)
        else if rating >= 4 {
            switch tone {
            case .anxious:
                return [
                    "I hear your worry. It's okay to feel uncertain sometimes. These challenging moments help your roots grow deeper. You're stronger than you know. 💪🌱",
                    "Anxiety is uncomfortable, but you're facing it with courage. That takes real strength. Be gentle with yourself today. 🫂",
                    "These uneasy feelings will pass. You've weathered storms before, and you'll weather this one too. Your garden endures. 🌧️→🌈"
                ]
            case .sad:
                return [
                    "I see you're struggling today. It's completely okay to feel this way. Even gardens need cloudy days. Your emotions are valid. 💙",
                    "This heaviness won't last forever. You're allowed to feel sad. Tomorrow brings new light. 🌙→🌅",
                    "These difficult emotions are part of being human. You're not alone in this. Your garden will bloom again. 🌱"
                ]
            case .reflective:
                return [
                    "You're processing something important. This inner work, though challenging, creates space for new growth. 🌿",
                    "Difficult days teach us valuable lessons. You're growing even when it doesn't feel like it. 💭",
                    "This contemplative space is necessary sometimes. Trust that you're exactly where you need to be. 🍃"
                ]
            default:
                return [
                    "Today feels tough, and that's okay. You're doing better than you think. Small steps count. 🦶🌱",
                    "Even on harder days, you're still here, still growing. That's courage. 💚",
                    "This too shall pass. Your resilience is building stronger roots. Keep going. 🌳"
                ]
            }
        }

        // Low ratings (1-3)
        else {
            switch tone {
            case .sad:
                return [
                    "I'm so sorry you're experiencing this pain. Please be incredibly gentle with yourself. Even in the darkest soil, seeds are preparing to grow. You matter. 💙🌱",
                    "This heaviness is real and valid. You don't have to carry it alone. Reach out if you need support. Your garden will see light again. 🫂",
                    "These are the hardest moments, I know. But you're still here, and that's profound strength. One moment at a time. 💪",
                    "Your pain matters. Please remember: this darkness is temporary, even when it doesn't feel that way. You're not alone. 🌙💙"
                ]
            case .anxious:
                return [
                    "I hear how overwhelming everything feels right now. Please take some deep breaths. You're safe. This intensity will ease. 🫁💚",
                    "Anxiety can feel crushing. Please be compassionate with yourself. You're doing your absolute best. That's enough. 🫂",
                    "These anxious feelings are so difficult. Remember: you've survived 100% of your hardest days so far. You will get through this too. 💪🌱"
                ]
            default:
                return [
                    "Today is really hard. That's okay. You don't have to be strong right now. Just breathe. Just be. Your garden endures even in storms. 🌧️💙",
                    "I see you're struggling deeply. Please reach out for support if you need it. You deserve care and compassion, especially from yourself. 🫂",
                    "These moments are so painful, but they're also temporary. You are resilient. Your roots run deep. Hold on. 🌳💚",
                    "Be extraordinarily gentle with yourself today. Rest. Breathe. Know that brighter days exist, even when you can't see them yet. 🌱→🌸"
                ]
            }
        }
    }
}
