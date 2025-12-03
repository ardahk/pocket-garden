//
//  TreeInfoSheet.swift
//  pocket-garden
//
//  Tree Information with Fun Facts
//

import SwiftUI

struct TreeInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    let treeType: TreeType
    @State private var selectedType: TreeType
    
    init(treeType: TreeType) {
        self.treeType = treeType
        _selectedType = State(initialValue: treeType)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peacefulGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Tree emoji
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.primaryGreen.opacity(0.2),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 160, height: 160)
                            
                            Text(selectedType.emoji)
                                .font(.system(size: 100))
                        }
                        .padding(.top, Spacing.xl)
                        
                        // Tree name and description
                        VStack(spacing: Spacing.md) {
                            Text(selectedType.name)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.textPrimary)
                            
                            Text(selectedType.description)
                                .font(Typography.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Layout.screenPadding)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                ForEach(TreeType.allCases, id: \.self) { type in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedType = type
                                        }
                                    }) {
                                        HStack(spacing: Spacing.xs) {
                                            Text(type.emoji)
                                                .font(.system(size: 18))
                                            
                                            Text(type.name)
                                                .font(Typography.callout)
                                        }
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(
                                            Capsule()
                                                .fill(selectedType == type ? Color.primaryGreen.opacity(0.15) : Color.cardBackground)
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(selectedType == type ? Color.primaryGreen : Color.clear, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Layout.screenPadding)
                        }
                        
                        // Fun facts
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("🌟 Fun Facts")
                                .font(Typography.headline)
                                .foregroundColor(.textPrimary)
                            
                            ForEach(Array(selectedType.funFacts.enumerated()), id: \.offset) { index, fact in
                                FactRow(number: index + 1, fact: fact)
                            }
                        }
                        .padding(.horizontal, Layout.screenPadding)
                        
                        // Care tips
                        Card(backgroundColor: .primaryGreen.opacity(0.1)) {
                            VStack(alignment: .leading, spacing: Spacing.md) {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.primaryGreen)
                                    
                                    Text("Growth Tips")
                                        .font(Typography.headline)
                                        .foregroundColor(.textPrimary)
                                }
                                
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    TipRow(icon: "drop.fill", text: "Journal daily to water your tree")
                                    TipRow(icon: "calendar", text: "Takes \(selectedType.daysToGrow) days to fully grow")
                                    TipRow(icon: "leaf.fill", text: "Each journal entry helps it grow stronger")
                                }
                            }
                            .padding(.vertical, Spacing.sm)
                        }
                        .padding(.horizontal, Layout.screenPadding)
                    }
                    .padding(.bottom, Spacing.xxxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGreen)
                }
            }
        }
    }
}

struct FactRow: View {
    let number: Int
    let fact: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Text("\(number)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primaryGreen)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.primaryGreen.opacity(0.1))
                )
            
            Text(fact)
                .font(Typography.body)
                .foregroundColor(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.primaryGreen)
                .frame(width: 24)
            
            Text(text)
                .font(Typography.callout)
                .foregroundColor(.textSecondary)
        }
    }
}

// Add fun facts to TreeType enum
extension TreeType {
    var funFacts: [String] {
        switch self {
        case .oak:
            return [
                "Oak trees can live for over 1,000 years, making them witnesses to centuries of history.",
                "A mature oak can produce up to 10 million acorns in its lifetime, though only 1 in 10,000 becomes a tree.",
                "Oak wood is incredibly strong and has been used to build ships, furniture, and even whiskey barrels.",
                "Oak trees support more life forms than any other native tree species in many regions.",
                "The oak is often called the 'King of Trees' due to its strength and longevity."
            ]
        case .pine:
            return [
                "Pine trees can survive in some of the harshest climates on Earth, from arctic to tropical.",
                "Some pine species can grow up to 260 feet tall - taller than the Statue of Liberty!",
                "Pine cones can stay closed for years until a forest fire triggers them to open and release seeds.",
                "Pine trees produce a natural antifreeze that prevents their sap from freezing in winter.",
                "The scent of pine has been shown to reduce stress and improve mood."
            ]
        case .cherry:
            return [
                "Cherry blossoms only bloom for about 2 weeks each year, making them a symbol of life's fleeting beauty.",
                "Japan's cherry blossom season attracts millions of visitors for 'hanami' (flower viewing) celebrations.",
                "Some cherry trees can produce both beautiful flowers and delicious fruit.",
                "Cherry trees can live for over 100 years and continue blooming throughout their life.",
                "The wood of cherry trees is prized for making musical instruments and fine furniture."
            ]
        }
    }
}
