//
//  MoodTrendChartView.swift
//  pocket-garden
//
//  Mood Trend Line Chart - Weekly view with navigation
//

import SwiftUI
import Charts

struct MoodTrendChartView: View {
    let entries: [EmotionEntry]
    @Environment(\.dismiss) private var dismiss
    
    @State private var weekOffset: Int = 0
    @State private var selectedDataPoint: ChartDataPoint?
    
    // MARK: - Computed Properties
    
    private var calendar: Calendar { Calendar.current }
    
    private var currentWeekStart: Date {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = weekday - 1
        let weekStart = calendar.date(byAdding: .day, value: -daysFromSunday, to: today)!
        return calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: weekStart)!
    }
    
    private var currentWeekEnd: Date {
        calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!
    }
    
    private var weekDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: currentWeekStart)
        let end = formatter.string(from: currentWeekEnd)
        return "\(start) - \(end)"
    }
    
    private var weekEntriesWithData: [ChartDataPoint] {
        // Filter entries for the current week and only include days with entries
        let weekEntries = entries.filter { entry in
            let entryDate = calendar.startOfDay(for: entry.date)
            return entryDate >= currentWeekStart && entryDate <= currentWeekEnd
        }
        
        // Group by day and take the latest entry per day
        var entriesByDay: [Date: EmotionEntry] = [:]
        for entry in weekEntries {
            let dayStart = calendar.startOfDay(for: entry.date)
            if let existing = entriesByDay[dayStart] {
                if entry.date > existing.date {
                    entriesByDay[dayStart] = entry
                }
            } else {
                entriesByDay[dayStart] = entry
            }
        }
        
        // Convert to chart data points, sorted by date
        return entriesByDay.map { date, entry in
            ChartDataPoint(date: date, rating: entry.emotionRating, entry: entry)
        }.sorted { $0.date < $1.date }
    }
    
    private var hasOlderEntries: Bool {
        entries.contains { entry in
            calendar.startOfDay(for: entry.date) < currentWeekStart
        }
    }
    
    private var hasNewerEntries: Bool {
        weekOffset > 0
    }
    
    private var weekAverage: Double {
        guard !weekEntriesWithData.isEmpty else { return 0 }
        let sum = weekEntriesWithData.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(weekEntriesWithData.count)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peacefulGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Week navigation
                        weekNavigationHeader
                        
                        // Chart card
                        chartCard
                        
                        // Week summary
                        weekSummaryCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Mood Trend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primaryGreen)
                }
            }
        }
    }
    
    // MARK: - Week Navigation
    
    private var weekNavigationHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    weekOffset += 1
                }
                Theme.Haptics.light()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(hasOlderEntries ? Color.primaryGreen : Color.textSecondary.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .background(Color.cardBackground)
                    .clipShape(Circle())
            }
            .disabled(!hasOlderEntries)
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(weekOffset == 0 ? "This Week" : weekOffset == 1 ? "Last Week" : "\(weekOffset) Weeks Ago")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
                
                Text(weekDateRange)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
            }
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    weekOffset -= 1
                }
                Theme.Haptics.light()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(hasNewerEntries ? Color.primaryGreen : Color.textSecondary.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .background(Color.cardBackground)
                    .clipShape(Circle())
            }
            .disabled(!hasNewerEntries)
        }
    }
    
    // MARK: - Chart Card
    
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if weekEntriesWithData.isEmpty {
                emptyStateView
            } else {
                moodLineChart
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 4)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
            
            Text("No entries this week")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color.textSecondary)
            
            Text("Check in daily to see your mood trend")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Color.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    private var moodLineChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Over Time")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
            
            Chart {
                ForEach(weekEntriesWithData) { dataPoint in
                    LineMark(
                        x: .value("Day", dataPoint.date, unit: .day),
                        y: .value("Mood", dataPoint.rating)
                    )
                    .foregroundStyle(Color.primaryGreen.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Day", dataPoint.date, unit: .day),
                        y: .value("Mood", dataPoint.rating)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.primaryGreen.opacity(0.3), Color.primaryGreen.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Day", dataPoint.date, unit: .day),
                        y: .value("Mood", dataPoint.rating)
                    )
                    .foregroundStyle(Color.emotionColor(for: dataPoint.rating))
                    .symbolSize(selectedDataPoint?.id == dataPoint.id ? 150 : 80)
                    .annotation(position: .top, spacing: 8) {
                        if selectedDataPoint?.id == dataPoint.id {
                            annotationView(for: dataPoint)
                        }
                    }
                }
            }
            .chartYScale(domain: 1...10)
            .chartYAxis {
                AxisMarks(values: [1, 3, 5, 7, 10]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(Color.textSecondary.opacity(0.2))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(dayAbbreviation(for: date))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleChartInteraction(at: value.location, proxy: proxy, geometry: geometry)
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        selectedDataPoint = nil
                                    }
                                }
                        )
                }
            }
            .frame(height: 200)
        }
    }
    
    private func annotationView(for dataPoint: ChartDataPoint) -> some View {
        VStack(spacing: 2) {
            Text(Theme.emotionLabel(for: dataPoint.rating))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
            
            Text("\(dataPoint.rating)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.emotionColor(for: dataPoint.rating))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.shadowColor, radius: 4, x: 0, y: 2)
    }
    
    private func handleChartInteraction(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotFrame!].origin.x
        
        guard let date: Date = proxy.value(atX: xPosition) else { return }
        
        // Find the closest data point
        let closest = weekEntriesWithData.min { a, b in
            abs(a.date.timeIntervalSince(date)) < abs(b.date.timeIntervalSince(date))
        }
        
        if let closest = closest {
            withAnimation(.easeOut(duration: 0.15)) {
                selectedDataPoint = closest
            }
            Theme.Haptics.selection()
        }
    }
    
    private func dayAbbreviation(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    // MARK: - Week Summary Card
    
    private var weekSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Week Summary")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
            
            HStack(spacing: 20) {
                summaryItem(
                    value: weekEntriesWithData.isEmpty ? "-" : String(format: "%.1f", weekAverage),
                    label: "Average",
                    color: weekEntriesWithData.isEmpty ? .textSecondary : Color.emotionColor(for: Int(weekAverage.rounded()))
                )
                
                Divider()
                    .frame(height: 40)
                
                summaryItem(
                    value: "\(weekEntriesWithData.count)",
                    label: "Entries",
                    color: .primaryGreen
                )
                
                Divider()
                    .frame(height: 40)
                
                summaryItem(
                    value: weekEntriesWithData.isEmpty ? "-" : "\(weekEntriesWithData.map { $0.rating }.max() ?? 0)",
                    label: "Best Day",
                    color: weekEntriesWithData.isEmpty ? .textSecondary : .emotionJoy
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 4)
    }
    
    private func summaryItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Chart Data Point

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let rating: Int
    let entry: EmotionEntry
}

// MARK: - Preview

#Preview {
    MoodTrendChartView(entries: EmotionEntry.sampleEntries())
}
