//
//  PocketGardenWidget.swift
//  PocketGardenWidget
//
//  Widget showing current tree growth and daily streak
//

import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), treeType: "oak", growthProgress: 0.5, waterCount: 4, daysToGrow: 7, hasJournaledToday: false, streak: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), treeType: "oak", growthProgress: 0.5, waterCount: 4, daysToGrow: 7, hasJournaledToday: false, streak: 3)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let entry = await fetchCurrentTreeData()
            let timeline = Timeline(entries: [entry], policy: .after(Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))))
            completion(timeline)
        }
    }
    
    @MainActor
    private func fetchCurrentTreeData() async -> SimpleEntry {
        // Access SwiftData in widget
        do {
            let schema = Schema([GrowingTree.self, EmotionEntry.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            
            // Fetch current tree
            let treeDescriptor = FetchDescriptor<GrowingTree>(
                predicate: #Predicate { !$0.isFullyGrown },
                sortBy: [SortDescriptor(\.plantedDate, order: .reverse)]
            )
            let currentTree = try? context.fetch(treeDescriptor).first
            
            // Check if journaled today
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            let entryPredicate = #Predicate<EmotionEntry> { entry in
                entry.date >= today && entry.date < tomorrow
            }
            let entryDescriptor = FetchDescriptor<EmotionEntry>(predicate: entryPredicate)
            let hasJournaledToday = (try? context.fetchCount(entryDescriptor)) ?? 0 > 0
            
            // Calculate streak
            let allEntries = try? context.fetch(FetchDescriptor<EmotionEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
            let streak = calculateStreak(entries: allEntries ?? [])
            
            return SimpleEntry(
                date: Date(),
                treeType: currentTree?.treeType ?? "oak",
                growthProgress: currentTree?.growthProgress ?? 0,
                waterCount: currentTree?.waterCount ?? 0,
                daysToGrow: currentTree?.daysToGrow ?? 7,
                hasJournaledToday: hasJournaledToday,
                streak: streak
            )
        } catch {
            return SimpleEntry(date: Date(), treeType: "oak", growthProgress: 0, waterCount: 0, daysToGrow: 7, hasJournaledToday: false, streak: 0)
        }
    }
    
    private func calculateStreak(entries: [EmotionEntry]) -> Int {
        var streak = 0
        let calendar = Calendar.current
        let today = Date()
        
        let hasEntryToday = entries.contains { calendar.isDate($0.date, inSameDayAs: today) }
        let startDay = hasEntryToday ? 0 : 1
        
        for i in startDay..<(entries.count + 1) {
            guard let expectedDate = calendar.date(byAdding: .day, value: -i, to: today) else { break }
            if entries.first(where: { calendar.isDate($0.date, inSameDayAs: expectedDate) }) != nil {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let treeType: String
    let growthProgress: Double
    let waterCount: Int
    let daysToGrow: Int
    let hasJournaledToday: Bool
    let streak: Int
}

struct PocketGardenWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "FAF8F3"),
                    Color(hex: "A8C69F").opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text("🌳")
                        .font(.system(size: 24))
                    Text("Pocket Garden")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "2D3436"))
                    Spacer()
                }
                
                Spacer()
                
                // Tree progress
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(TreeType(rawValue: entry.treeType)?.name ?? "Oak Tree")")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "2D3436"))
                    
                    HStack(spacing: 8) {
                        ProgressView(value: entry.growthProgress)
                            .tint(Color(hex: "A8C69F"))
                        
                        Text("\(entry.waterCount)/\(entry.daysToGrow)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "636E72"))
                            .monospacedDigit()
                    }
                }
                
                // Status footer
                HStack {
                    if entry.hasJournaledToday {
                        Label("Watered today", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "00B894"))
                    } else {
                        Label("Not watered yet", systemImage: "drop.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "636E72"))
                    }
                    
                    Spacer()
                    
                    if entry.streak > 0 {
                        Text("🔥 \(entry.streak)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "F4D06F"))
                    }
                }
            }
            .padding(16)
        }
    }
}

struct PocketGardenWidget: Widget {
    let kind: String = "PocketGardenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PocketGardenWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tree Growth")
        .description("Track your growing tree and daily streak")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    PocketGardenWidget()
} timeline: {
    SimpleEntry(date: .now, treeType: "oak", growthProgress: 0.57, waterCount: 4, daysToGrow: 7, hasJournaledToday: true, streak: 12)
    SimpleEntry(date: .now, treeType: "cherry", growthProgress: 0.35, waterCount: 5, daysToGrow: 14, hasJournaledToday: false, streak: 3)
}
