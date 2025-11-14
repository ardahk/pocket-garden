//
//  QuoteCard.swift
//  pocket-garden
//
//  Quote of the Day/Week Card
//

import SwiftUI

struct QuoteCard: View {
    let quote: Quote
    let isWeekly: Bool
    
    var body: some View {
        Card(backgroundColor: isWeekly ? Color.accentGold.opacity(0.08) : Color.primaryGreen.opacity(0.05)) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    Text(quote.emoji ?? "✨")
                        .font(.system(size: 32))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isWeekly ? "Quote of the Week" : "Quote of the Day")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textSecondary)
                            .textCase(.uppercase)
                        
                        Text(quote.category)
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary.opacity(0.7))
                    }
                    
                    Spacer()
                }
                
                // Quote text
                Text(quote.text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .fadeIn()
    }
}

// MARK: - Loading State

struct QuoteCardLoading: View {
    var body: some View {
        Card(backgroundColor: Color.primaryGreen.opacity(0.05)) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 12)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 10)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 16)
                }
            }
        }
        .shimmer()
    }
}
