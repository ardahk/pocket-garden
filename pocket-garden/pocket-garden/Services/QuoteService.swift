//
//  QuoteService.swift
//  pocket-garden
//
//  Smart Quote Selection with AFM Analysis
//

import Foundation
import SwiftData
#if canImport(FoundationModels)
import FoundationModels
#endif

class QuoteService {
    private var allQuotes: [QuoteData] = []
    
    init() {
        loadQuotes()
    }
    
    // MARK: - Load Quotes from CSV
    
    private func loadQuotes() {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "csv"),
              let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            print("Failed to load quotes.csv")
            return
        }
        
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else { return }
        
        // Skip header row
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            
            // Parse CSV line (handle quoted strings)
            let components = parseCSVLine(line)
            guard components.count >= 2 else { continue }
            
            let quote = QuoteData(category: components[0], quote: components[1])
            allQuotes.append(quote)
        }
        
        print("Loaded \(allQuotes.count) quotes")
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        
        if !current.isEmpty {
            result.append(current.trimmingCharacters(in: .whitespaces))
        }
        
        return result
    }
    
    // MARK: - Daily Quote Selection
    
    func getDailyQuote(
        recentEntries: [EmotionEntry],
        modelContext: ModelContext
    ) async -> Quote? {
        // Check if we already have today's quote
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate<Quote> { quote in
                quote.date >= today && !quote.isWeeklyQuote
            }
        )
        
        if let existingQuote = try? modelContext.fetch(descriptor).first {
            return existingQuote
        }
        
        // Analyze recent entries and select appropriate quote
        let category = await analyzeRecentEntries(recentEntries)
        let quoteData = selectQuote(forCategory: category)
        
        // Get emoji (with iOS 26 availability check for FoundationModels)
        var emoji: String
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            emoji = await getEmojiForQuote(quoteData.quote, category: quoteData.category, fallbackEntries: recentEntries)
        } else {
            emoji = getFallbackEmoji(forCategory: quoteData.category, entries: recentEntries)
        }
        #else
        emoji = getFallbackEmoji(forCategory: quoteData.category, entries: recentEntries)
        #endif
        
        let quote = Quote(
            category: quoteData.category,
            text: quoteData.quote,
            emoji: emoji,
            date: Date(),
            isWeeklyQuote: false
        )
        
        modelContext.insert(quote)
        try? modelContext.save()
        
        return quote
    }
    
    // MARK: - Weekly Quote Selection
    
    func getWeeklyQuote(
        weekEntries: [EmotionEntry],
        modelContext: ModelContext
    ) async -> Quote? {
        // Check if we already have this week's quote
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate<Quote> { quote in
                quote.date >= weekStart && quote.isWeeklyQuote
            }
        )
        
        if let existingQuote = try? modelContext.fetch(descriptor).first {
            return existingQuote
        }
        
        // Analyze week's mood and select motivational quote
        let category = await analyzeWeeklyMood(weekEntries)
        let quoteData = selectQuote(forCategory: category)
        
        // Get emoji (with iOS 26 availability check for FoundationModels)
        var emoji: String
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            emoji = await getEmojiForQuote(quoteData.quote, category: quoteData.category, fallbackEntries: weekEntries)
        } else {
            emoji = getFallbackEmoji(forCategory: quoteData.category, entries: weekEntries)
        }
        #else
        emoji = getFallbackEmoji(forCategory: quoteData.category, entries: weekEntries)
        #endif
        
        let quote = Quote(
            category: quoteData.category,
            text: quoteData.quote,
            emoji: emoji,
            date: Date(),
            isWeeklyQuote: true
        )
        
        modelContext.insert(quote)
        try? modelContext.save()
        
        return quote
    }
    
    // MARK: - AFM Analysis
    
    private func analyzeRecentEntries(_ entries: [EmotionEntry]) async -> String {
        guard !entries.isEmpty else { return "OPTIMISM" }
        
        // Get last 2-3 entries
        let recentEntries = Array(entries.prefix(3))
        let transcriptions = recentEntries.compactMap { $0.cleanedTranscription }.joined(separator: "\n\n")
        
        guard !transcriptions.isEmpty else { return "OPTIMISM" }
        
        // Try AFM analysis
        if #available(iOS 26.0, *) {
            if let category = try? await analyzeWithAFM(text: transcriptions, type: "daily") {
                return category
            }
        }
        
        // Fallback: analyze based on ratings
        let avgRating = recentEntries.map { $0.emotionRating }.reduce(0, +) / recentEntries.count
        return fallbackCategorySelection(rating: avgRating, text: transcriptions)
    }
    
    private func analyzeWeeklyMood(_ entries: [EmotionEntry]) async -> String {
        guard !entries.isEmpty else { return "ENCOURAGEMENT" }
        
        let transcriptions = entries.compactMap { $0.cleanedTranscription }.joined(separator: "\n\n")
        
        // Try AFM analysis
        if #available(iOS 26.0, *) {
            if let category = try? await analyzeWithAFM(text: transcriptions, type: "weekly") {
                return category
            }
        }
        
        // Fallback: analyze based on ratings
        let avgRating = entries.map { $0.emotionRating }.reduce(0, +) / entries.count
        return fallbackCategorySelection(rating: avgRating, text: transcriptions)
    }
    
    @available(iOS 26.0, *)
    private func analyzeWithAFM(text: String, type: String) async throws -> String {
        let instructions = """
        You are analyzing journal entries to select an appropriate inspirational quote category.
        
        Available categories:
        LOVE, LISTENING, STEWARDSHIP, RESILIENCE, EXPLORING, KINDNESS, GRATITUDE, 
        COURAGE, OPTIMISM, PERSEVERANCE, ENCOURAGEMENT, MINDFULNESS, OVERCOMING, 
        TRUE BEAUTY, CHARACTER, APPRECIATING NATURE, EQUALITY, LAUGHTER
        
        Based on the journal entries, identify the theme that would be most helpful and motivating.
        
        Respond with ONLY the category name, nothing else.
        """
        
        let session = LanguageModelSession(instructions: instructions)
        let prompt = "\(type == "weekly" ? "Weekly" : "Recent") journal entries:\n\n\(text)"
        
        var response = ""
        let stream = session.streamResponse(to: prompt)
        
        for try await partial in stream {
            response += partial.content
        }
        
        let category = response.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Validate category exists
        if allQuotes.contains(where: { $0.category == category }) {
            return category
        }
        
        return "ENCOURAGEMENT"
    }
    
    @available(iOS 26.0, *)
    private func getEmojiForQuote(_ quote: String, category: String, fallbackEntries: [EmotionEntry]) async -> String {
        do {
            let instructions = """
            You select the perfect emoji to represent an inspirational quote.
            Respond with ONLY a single emoji, nothing else.
            """
            
            let session = LanguageModelSession(instructions: instructions)
            let prompt = "Category: \(category)\nQuote: \(quote)\n\nSelect one emoji:"
            
            var response = ""
            let stream = session.streamResponse(to: prompt)
            
            for try await partial in stream {
                response += partial.content
            }
            
            let emoji = response.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // If AFM returns empty or just whitespace, use fallback
            if emoji.isEmpty {
                print("⚠️ AFM returned empty emoji, using fallback")
                return getFallbackEmoji(forCategory: category, entries: fallbackEntries)
            }
            
            print("✅ AFM emoji: \(emoji)")
            return emoji
        } catch {
            print("❌ AFM emoji generation failed: \(error), using fallback")
            return getFallbackEmoji(forCategory: category, entries: fallbackEntries)
        }
    }
    
    // MARK: - Fallback Selection
    
    private func fallbackCategorySelection(rating: Int, text: String) -> String {
        let lowercaseText = text.lowercased()
        
        // Check for specific themes
        if lowercaseText.contains("love") || lowercaseText.contains("relationship") || lowercaseText.contains("heart") {
            return "LOVE"
        } else if lowercaseText.contains("difficult") || lowercaseText.contains("hard") || lowercaseText.contains("struggle") {
            return "RESILIENCE"
        } else if lowercaseText.contains("grateful") || lowercaseText.contains("thank") || lowercaseText.contains("appreciate") {
            return "GRATITUDE"
        } else if lowercaseText.contains("nature") || lowercaseText.contains("walk") || lowercaseText.contains("outside") {
            return "APPRECIATING NATURE"
        } else if lowercaseText.contains("kind") || lowercaseText.contains("help") {
            return "KINDNESS"
        }
        
        // Based on rating
        if rating <= 4 {
            return "ENCOURAGEMENT"
        } else if rating <= 6 {
            return "OPTIMISM"
        } else {
            return "GRATITUDE"
        }
    }
    
    private func selectQuote(forCategory category: String) -> QuoteData {
        // Get quotes from the category
        let categoryQuotes = allQuotes.filter { $0.category == category }
        
        if categoryQuotes.isEmpty {
            // Fallback to any quote
            return allQuotes.randomElement() ?? QuoteData(category: "OPTIMISM", quote: "Every day is a new beginning.")
        }
        
        // Select random quote from category
        return categoryQuotes.randomElement()!
    }
    
    // MARK: - Fallback Emoji Selection
    
    private func getFallbackEmoji(forCategory category: String, entries: [EmotionEntry]) -> String {
        // Calculate average sentiment from entries
        let averageRating = entries.isEmpty ? 5.0 : Double(entries.reduce(0) { $0 + $1.emotionRating }) / Double(entries.count)
        
        // Base emojis for each category
        let categoryEmojis: [String: [String]] = [
            "LOVE": ["💕", "❤️", "💖", "💝", "💗"],
            "LISTENING": ["👂", "🎧", "🧏", "💬", "🗣️"],
            "STEWARDSHIP": ["🤝", "🌍", "🌱", "♻️", "🛡️"],
            "RESILIENCE": ["💪", "🦾", "🔥", "⚡", "🌟"],
            "EXPLORING": ["🗺️", "🧭", "🔍", "🌄", "🚀"],
            "KINDNESS": ["🤗", "💝", "🌸", "☀️", "🌻"],
            "GRATITUDE": ["🙏", "💚", "🌺", "✨", "🌈"],
            "COURAGE": ["🦁", "⚔️", "🛡️", "🔥", "💫"],
            "OPTIMISM": ["😊", "🌞", "🌈", "✨", "🌟"],
            "PERSEVERANCE": ["🏔️", "🎯", "🚀", "💎", "⛰️"],
            "ENCOURAGEMENT": ["🌟", "💪", "🎉", "🌈", "✨"],
            "MINDFULNESS": ["🧘", "☮️", "🌿", "🕉️", "💆"],
            "OVERCOMING": ["🏆", "💪", "⚡", "🔥", "🎯"],
            "TRUE BEAUTY": ["🌹", "✨", "🦋", "🌺", "💎"],
            "CHARACTER": ["👤", "🎭", "💎", "🌟", "👑"],
            "APPRECIATING NATURE": ["🌿", "🌲", "🏞️", "🌸", "🦋"],
            "EQUALITY": ["⚖️", "🤝", "🌍", "✊", "💪"],
            "LAUGHTER": ["😄", "😂", "🎭", "😊", "🤗"]
        ]
        
        // Get emoji pool for category
        let emojiPool = categoryEmojis[category] ?? ["✨", "🌟", "💫", "⭐", "🌈"]
        
        // Sentiment-based selection
        // High ratings (7-10): Use brighter/more positive emojis
        // Mid ratings (4-6): Use balanced emojis
        // Low ratings (1-3): Use supportive/encouraging emojis
        
        if averageRating >= 7.0 {
            // Pick from first half (more positive)
            let positiveEmojis = Array(emojiPool.prefix(3))
            return positiveEmojis.randomElement() ?? emojiPool.first!
        } else if averageRating >= 4.0 {
            // Pick from middle
            return emojiPool.randomElement() ?? "✨"
        } else {
            // Pick supportive emojis for lower ratings
            let supportiveEmojis = Array(emojiPool.suffix(3))
            return supportiveEmojis.randomElement() ?? emojiPool.last!
        }
    }
}
