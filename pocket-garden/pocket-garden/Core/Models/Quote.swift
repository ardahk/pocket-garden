//
//  Quote.swift
//  pocket-garden
//
//  Inspirational Quote Model
//

import Foundation
import SwiftData

@Model
final class Quote {
    var id: UUID
    var category: String
    var text: String
    var emoji: String?
    var date: Date
    var isWeeklyQuote: Bool
    
    init(category: String, text: String, emoji: String? = nil, date: Date = Date(), isWeeklyQuote: Bool = false) {
        self.id = UUID()
        self.category = category
        self.text = text
        self.emoji = emoji
        self.date = date
        self.isWeeklyQuote = isWeeklyQuote
    }
}

// MARK: - Quote Data Structure (for CSV parsing)

struct QuoteData: Codable {
    let category: String
    let quote: String
    
    enum CodingKeys: String, CodingKey {
        case category = "Category"
        case quote = "Quote"
    }
}
