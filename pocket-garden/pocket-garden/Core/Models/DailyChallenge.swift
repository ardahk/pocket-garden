//
//  DailyChallenge.swift
//  pocket-garden
//
//  Daily Challenge System - Give users reasons to return daily
//

import SwiftUI
import Foundation

// MARK: - Daily Challenge

struct DailyChallenge: Identifiable {
    let id: String
    let prompt: String
    let emoji: String
    let category: ChallengeCategory
    let date: Date

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Challenge Category

enum ChallengeCategory: String, CaseIterable {
    case gratitude = "Gratitude"
    case reflection = "Reflection"
    case growth = "Growth"
    case mindfulness = "Mindfulness"
    case positivity = "Positivity"
    case creativity = "Creativity"

    var color: Color {
        switch self {
        case .gratitude: return .accentGold
        case .reflection: return .emotionContent
        case .growth: return .primaryGreen
        case .mindfulness: return .emotionCalm
        case .positivity: return .emotionJoy
        case .creativity: return .secondaryTerracotta
        }
    }

    var icon: String {
        switch self {
        case .gratitude: return "heart.fill"
        case .reflection: return "sparkles"
        case .growth: return "arrow.up.right"
        case .mindfulness: return "leaf.fill"
        case .positivity: return "sun.max.fill"
        case .creativity: return "paintbrush.fill"
        }
    }
}

// MARK: - Challenge Prompts

extension DailyChallenge {
    static let prompts: [(category: ChallengeCategory, emoji: String, text: String)] = [
        // Gratitude
        (.gratitude, "🙏", "What are three things you're grateful for today?"),
        (.gratitude, "💝", "Who made you smile today and why?"),
        (.gratitude, "🌟", "What small moment brought you joy today?"),
        (.gratitude, "🏠", "What comfort in your life do you appreciate most?"),
        (.gratitude, "🌸", "What positive change have you noticed in yourself recently?"),

        // Reflection
        (.reflection, "🤔", "What did you learn about yourself today?"),
        (.reflection, "💭", "How did you handle a challenge today?"),
        (.reflection, "📝", "What would you tell your past self from a year ago?"),
        (.reflection, "🔍", "What pattern in your life are you noticing lately?"),
        (.reflection, "⏰", "How did you spend your time today? Are you happy with it?"),

        // Growth
        (.growth, "🌱", "What's one thing you want to improve about yourself?"),
        (.growth, "💪", "What fear did you face or want to face soon?"),
        (.growth, "🎯", "What step can you take tomorrow toward your goals?"),
        (.growth, "📚", "What new skill or knowledge would enrich your life?"),
        (.growth, "🚀", "What limiting belief are you ready to let go of?"),

        // Mindfulness
        (.mindfulness, "🧘", "How are you feeling in this present moment?"),
        (.mindfulness, "🌊", "What sensations do you notice in your body right now?"),
        (.mindfulness, "🍃", "Describe your day using only your five senses"),
        (.mindfulness, "☁️", "What thoughts are passing through your mind?"),
        (.mindfulness, "🌙", "What do you need to release or let go of?"),

        // Positivity
        (.positivity, "😊", "What made you laugh or smile recently?"),
        (.positivity, "🌈", "What are you looking forward to?"),
        (.positivity, "✨", "What's something good that happened unexpectedly?"),
        (.positivity, "🎉", "What recent accomplishment are you proud of?"),
        (.positivity, "💫", "What makes you feel most alive?"),

        // Creativity
        (.creativity, "🎨", "If today was a color, what would it be and why?"),
        (.creativity, "🎵", "What song represents your current mood?"),
        (.creativity, "📖", "If your life was a book, what chapter are you in?"),
        (.creativity, "🌤️", "What weather would describe your emotions today?"),
        (.creativity, "🦋", "What would your ideal day look like?")
    ]

    static func todaysChallenge() -> DailyChallenge {
        let today = Date()
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: today) ?? 1
        let index = (dayOfYear - 1) % prompts.count
        let prompt = prompts[index]

        return DailyChallenge(
            id: "daily_\(dayOfYear)",
            prompt: prompt.text,
            emoji: prompt.emoji,
            category: prompt.category,
            date: today
        )
    }

    static func challengeFor(date: Date) -> DailyChallenge {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % prompts.count
        let prompt = prompts[index]

        return DailyChallenge(
            id: "daily_\(dayOfYear)",
            prompt: prompt.text,
            emoji: prompt.emoji,
            category: prompt.category,
            date: date
        )
    }
}

// MARK: - Weekly Insights

struct WeeklyInsight {
    let weekStartDate: Date
    let totalEntries: Int
    let averageRating: Double
    let moodTrend: MoodTrend
    let dominantEmotion: String
    let encouragement: String

    enum MoodTrend {
        case improving
        case stable
        case declining

        var emoji: String {
            switch self {
            case .improving: return "📈"
            case .stable: return "➡️"
            case .declining: return "📉"
            }
        }

        var color: Color {
            switch self {
            case .improving: return .successGreen
            case .stable: return .accentGold
            case .declining: return .emotionAnxious
            }
        }
    }

    static func generate(from entries: [EmotionEntry]) -> WeeklyInsight {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekEntries = entries.filter { $0.date >= weekAgo }

        let totalEntries = weekEntries.count
        let averageRating = weekEntries.isEmpty ? 0 : Double(weekEntries.reduce(0) { $0 + $1.emotionRating }) / Double(weekEntries.count)

        // Calculate trend
        let firstHalf = weekEntries.prefix(weekEntries.count / 2)
        let secondHalf = weekEntries.suffix(weekEntries.count / 2)
        let firstAvg = firstHalf.isEmpty ? 0 : Double(firstHalf.reduce(0) { $0 + $1.emotionRating }) / Double(firstHalf.count)
        let secondAvg = secondHalf.isEmpty ? 0 : Double(secondHalf.reduce(0) { $0 + $1.emotionRating }) / Double(secondHalf.count)

        let trend: MoodTrend
        if secondAvg > firstAvg + 0.5 {
            trend = .improving
        } else if secondAvg < firstAvg - 0.5 {
            trend = .declining
        } else {
            trend = .stable
        }

        // Determine dominant emotion
        let dominantEmotion = averageRating >= 8 ? "Joy" :
                             averageRating >= 6 ? "Content" :
                             averageRating >= 4 ? "Reflective" : "Growing"

        // Generate encouragement
        let encouragement = generateEncouragement(trend: trend, averageRating: averageRating, totalEntries: totalEntries)

        return WeeklyInsight(
            weekStartDate: weekAgo,
            totalEntries: totalEntries,
            averageRating: averageRating,
            moodTrend: trend,
            dominantEmotion: dominantEmotion,
            encouragement: encouragement
        )
    }

    private static func generateEncouragement(trend: MoodTrend, averageRating: Double, totalEntries: Int) -> String {
        switch trend {
        case .improving:
            return "Your emotional wellness is trending upward! Keep nurturing your growth. 🌱"
        case .stable:
            if averageRating >= 7 {
                return "You're maintaining a positive emotional state. Great work! ✨"
            } else {
                return "Consistency is key. Each day of reflection is progress. 💚"
            }
        case .declining:
            return "Remember, difficult periods are temporary. You're building resilience through awareness. 🌟"
        }
    }
}
