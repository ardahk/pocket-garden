//
//  TreeDetailView.swift
//  pocket-garden
//
//  Shows detailed information about a tree and all journal entries that contributed to its growth
//

import SwiftUI
import SwiftData

struct TreeDetailView: View {
    let tree: GrowingTree
    
    @Query(sort: \EmotionEntry.date, order: .reverse) private var allEntries: [EmotionEntry]
    @State private var selectedEntry: EmotionEntry?
    @Environment(\.dismiss) private var dismiss
    
    private var treeType: TreeType {
        TreeType(rawValue: tree.treeType) ?? .oak
    }
    
    /// Get entries that contributed to this tree's growth (based on dates)
    private var treeEntries: [EmotionEntry] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: tree.plantedDate)
        
        // Use last watered date if available, otherwise use today to include all entries
        let endDate = calendar.startOfDay(for: tree.lastWateredDate ?? Date())
        
        // Filter entries within the tree's growth period (inclusive)
        let relevantEntries = allEntries.filter { entry in
            let entryDay = calendar.startOfDay(for: entry.date)
            return entryDay >= startDate && entryDay <= endDate
        }
        
        // Sort by date ascending (oldest first - shows growth journey)
        return relevantEntries.sorted { $0.date < $1.date }
    }
    
    /// Group entries by week for better organization
    private var entriesByWeek: [(week: String, entries: [EmotionEntry])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        var grouped: [String: [EmotionEntry]] = [:]
        var weekOrder: [String] = []
        
        for entry in treeEntries {
            let weekOfYear = calendar.component(.weekOfYear, from: entry.date)
            let year = calendar.component(.year, from: entry.date)
            
            let key = "\(year)-\(weekOfYear)"
            
            if grouped[key] == nil {
                grouped[key] = []
                weekOrder.append(key)
            }
            grouped[key]?.append(entry)
        }
        
        return weekOrder.compactMap { key in
            guard let entries = grouped[key], !entries.isEmpty else { return nil }
            let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entries[0].date)) ?? entries[0].date
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return (week: "Week of \(formatter.string(from: weekStart))", entries: entries)
        }
    }
    
    private var completionDate: Date? {
        guard tree.isFullyGrown else { return nil }
        return Calendar.current.date(byAdding: .day, value: tree.daysToGrow - 1, to: tree.plantedDate)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peacefulGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.xl) {
                        // Tree header
                        treeHeaderView
                        
                        // Growth timeline
                        growthTimelineView
                        
                        // Entries section
                        entriesSection
                    }
                    .padding(Layout.screenPadding)
                    .padding(.bottom, Spacing.xxxl)
                }
            }
            .navigationTitle("Tree Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryGreen)
                }
            }
            .sheet(item: $selectedEntry) { entry in
                EntryDetailViewRedesigned(entry: entry)
            }
        }
    }
    
    // MARK: - Tree Header
    
    private var treeHeaderView: some View {
        HStack(alignment: .center, spacing: Spacing.xl) {
            // Tree emoji with subtle glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.primaryGreen.opacity(0.22),
                                Color.primaryGreen.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 12,
                            endRadius: 60
                        )
                    )
                    .frame(width: 110, height: 110)
                
                Text(tree.isFullyGrown ? treeType.emoji : treeType.emojiForStage(tree.growthStage))
                    .font(.system(size: 68))
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(treeType.name)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    if tree.isFullyGrown {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.successGreen)
                            Text("Fully Grown")
                                .foregroundColor(.successGreen)
                        }
                        .font(.system(size: 14, weight: .medium))
                    } else {
                        Text("Day \(tree.waterCount) of \(tree.daysToGrow)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryGreen)
                    }
                }
                
                HStack(spacing: Spacing.lg) {
                    statItem(icon: "drop.fill", value: "\(tree.waterCount)", label: "Waterings", color: .emotionContent)
                    statItem(icon: "calendar", value: "\(tree.daysToGrow)", label: "Days", color: .accentGold)
                    statItem(icon: "doc.text.fill", value: "\(treeEntries.count)", label: "Entries", color: .primaryGreen)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
        )
    }
    
    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Text(label)
                .font(Typography.caption)
                .foregroundColor(.textSecondary)
        }
    }
    
    // MARK: - Growth Timeline
    
    private var growthTimelineView: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Growth Journey")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            HStack(spacing: Spacing.lg) {
                // Planted date
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.primaryGreen)
                            .font(.system(size: 12))
                        Text("Planted")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    Text(formatDate(tree.plantedDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textPrimary)
                }
                
                // Arrow
                Image(systemName: "arrow.right")
                    .foregroundColor(.textSecondary)
                    .font(.system(size: 12))
                
                // Completion date
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: tree.isFullyGrown ? "checkmark.circle.fill" : "hourglass")
                            .foregroundColor(tree.isFullyGrown ? .successGreen : .accentGold)
                            .font(.system(size: 12))
                        Text(tree.isFullyGrown ? "Completed" : "In Progress")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    if let completion = completionDate {
                        Text(formatDate(completion))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textPrimary)
                    } else {
                        Text("Growing...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryGreen)
                    }
                }
                
                Spacer()
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.primaryGreen.opacity(0.08))
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    // MARK: - Entries Section
    
    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Journal Entries")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(treeEntries.count) entries")
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)
            }
            
            if treeEntries.isEmpty {
                emptyEntriesView
            } else {
                // Group by week
                ForEach(entriesByWeek, id: \.week) { group in
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(group.week)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .padding(.leading, Spacing.sm)
                        
                        ForEach(group.entries) { entry in
                            TreeEntryCard(entry: entry) {
                                Theme.Haptics.light()
                                selectedEntry = entry
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyEntriesView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 32))
                .foregroundColor(.textSecondary.opacity(0.5))
            
            Text("No entries found")
                .font(Typography.body)
                .foregroundColor(.textSecondary)
            
            Text("Entries from your tree's growth period will appear here.")
                .font(Typography.caption)
                .foregroundColor(.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.cardBackground)
        )
    }
}

// MARK: - Preview

#Preview {
    TreeDetailView(tree: GrowingTree(
        plantedDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
        waterCount: 7,
        treeType: "oak",
        isFullyGrown: true
    ))
    .modelContainer(for: [GrowingTree.self, EmotionEntry.self], inMemory: true)
}

