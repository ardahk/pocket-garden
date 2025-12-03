//
//  FullGardenView.swift
//  pocket-garden
//
//  Full Garden View - Shows all fully grown trees
//

import SwiftUI
import SwiftData
import Darwin

struct FullGardenView: View {
    @Query private var grownTrees: [GrowingTree]
    @Query(sort: \EmotionEntry.date, order: .reverse) private var entries: [EmotionEntry]
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var initialOffset: CGSize = .zero
    @State private var selectedEntry: EmotionEntry?
    
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero
    
    private let minScale: CGFloat = 0.3
    private let maxScale: CGFloat = 2.0
    
    
    private var fullyGrownTrees: [GrowingTree] {
        grownTrees.filter { $0.isFullyGrown }
    }
    
    private var canvasSize: CGFloat {
        // Dynamic canvas size based on tree count
        let baseSize: CGFloat = 600
        let treeFactor = CGFloat(fullyGrownTrees.count) * 40
        return max(baseSize, min(baseSize + treeFactor, 3000))
    }
    
    var body: some View {
        ZStack {
            // Background
            ForestBackgroundView(weather: .sunny, scrollOffset: 0)
            
            if fullyGrownTrees.isEmpty {
                emptyGardenView
            } else {
                gardenCanvasView
            }
            
            // Top stats bar
            VStack {
                statsBar
                Spacer()
            }
        }
        .navigationTitle("My Garden")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: TestGardenView()) {
                    Image(systemName: "flask.fill")
                        .foregroundColor(.primaryGreen)
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailViewRedesigned(entry: entry)
        }
        .onAppear {
            autoZoomToFit()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyGardenView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.primaryGreen.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Text("🌳")
                    .font(.system(size: 60))
            }
            
            VStack(spacing: Spacing.sm) {
                Text("No Trees Yet")
                    .font(Typography.title2)
                    .foregroundColor(.textPrimary)
                
                Text("Grow your first tree by journaling daily.\nFully grown trees will appear here!")
                    .font(Typography.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(Layout.screenPadding)
    }
    
    // MARK: - Garden Canvas
    
    private var gardenCanvasView: some View {
        GeometryReader { geometry in
            let treePositions = calculateTreePositions(in: geometry.size)
            let bounds = calculateBounds(positions: treePositions, screenSize: geometry.size)
            
            ZStack {
                // Trees
                ForEach(Array(zip(fullyGrownTrees, treePositions)), id: \.0.id) { tree, position in
                    GardenTreeView(tree: tree, globalScale: scale)
                        .position(position)
                        .onTapGesture {
                            handleTreeTap(tree: tree)
                        }
                }
            }
            .frame(width: bounds.width, height: bounds.height)
            .scaleEffect(scale * magnifyBy)
            .offset(
                x: clampOffset(
                    current: offset.width + dragOffset.width,
                    bounds: bounds.width * scale,
                    screen: geometry.size.width
                ),
                y: clampOffset(
                    current: offset.height + dragOffset.height,
                    bounds: bounds.height * scale,
                    screen: geometry.size.height
                )
            )
            .gesture(
                MagnificationGesture()
                    .updating($magnifyBy) { value, state, _ in
                        state = value
                    }
                    .onEnded { value in
                        let newScale = scale * value
                        scale = min(max(newScale, minScale), maxScale)
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        offset.width += value.translation.width
                        offset.height += value.translation.height
                        clampOffsetToBounds(screenSize: geometry.size, boundsSize: bounds)
                    }
            )
        }
    }
    
    // MARK: - Stats Bar
    
    private var totalWaterings: Int {
        fullyGrownTrees.reduce(into: 0) { $0 += $1.waterCount }
    }
    
    private var oldestTree: GrowingTree? {
        fullyGrownTrees.min(by: { $0.plantedDate < $1.plantedDate })
    }
    
    private var statsBar: some View {
        VStack(spacing: Spacing.sm) {
            // Main stats row
            HStack(spacing: Spacing.lg) {
                // Tree count
                statItem(icon: "tree.fill", value: "\(fullyGrownTrees.count)", label: "Trees", color: .primaryGreen)
                
                Divider()
                    .frame(height: 24)
                
                // Total waterings
                statItem(icon: "drop.fill", value: "\(totalWaterings)", label: "Waterings", color: .emotionContent)
                
                Divider()
                    .frame(height: 24)
                
                // Garden age
                if let oldest = oldestTree {
                    let days = Calendar.current.dateComponents([.day], from: oldest.plantedDate, to: Date()).day ?? 0
                    statItem(icon: "calendar", value: "\(days)", label: "Days", color: .accentGold)
                }
            }
            
            // Tree type breakdown
            HStack(spacing: Spacing.md) {
                ForEach(TreeType.allCases, id: \.self) { type in
                    let count = fullyGrownTrees.filter { $0.treeType == type.rawValue }.count
                    if count > 0 {
                        HStack(spacing: 4) {
                            Text(type.emoji)
                                .font(.system(size: 14))
                            Text("\(count)")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.cardBackground.opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, Layout.screenPadding)
        .padding(.top, Spacing.sm)
    }
    
    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateTreePositions(in size: CGSize) -> [CGPoint] {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        var positions: [CGPoint] = []
        
        // Forest layout - cluster-based placement with first tree centered
        guard !fullyGrownTrees.isEmpty else { return positions }
        
        // First tree is always at center
        positions.append(center)
        
        // Remaining trees in clusters around center
        if fullyGrownTrees.count > 1 {
            let remainingTrees = Array(fullyGrownTrees.dropFirst())
            let clusterCount = max(1, remainingTrees.count / 3)
            var clusters: [CGPoint] = []
            
            for i in 0..<clusterCount {
                let angle = Double(i) * (2 * .pi / Double(clusterCount)) - .pi / 2
                let radius = min(size.width, size.height) * 0.28
                clusters.append(CGPoint(
                    x: center.x + CGFloat(Darwin.cos(angle)) * radius,
                    y: center.y + CGFloat(Darwin.sin(angle)) * radius
                ))
            }
            
            for (i, tree) in remainingTrees.enumerated() {
                let cluster = clusters[i % clusters.count]
                let seed = tree.id.hashValue
                let angle = Double(seed & 0xFFFF) / Double(0xFFFF) * 2 * .pi
                let distance = 40 + CGFloat((seed >> 16) & 0xFF) / 255.0 * 70
                let x = cluster.x + CGFloat(Darwin.cos(angle)) * distance
                let y = cluster.y + CGFloat(Darwin.sin(angle)) * distance
                positions.append(CGPoint(x: x, y: y))
            }
        }
        
        return positions
    }
    
    private func calculateBounds(positions: [CGPoint], screenSize: CGSize) -> CGSize {
        guard !positions.isEmpty else { return screenSize }
        
        let minX = positions.map { $0.x }.min() ?? 0
        let maxX = positions.map { $0.x }.max() ?? screenSize.width
        let minY = positions.map { $0.y }.min() ?? 0
        let maxY = positions.map { $0.y }.max() ?? screenSize.height
        
        let padding: CGFloat = 100
        let width = max(screenSize.width, maxX - minX + padding * 2)
        let height = max(screenSize.height, maxY - minY + padding * 2)
        
        return CGSize(width: width, height: height)
    }
    
    private func clampOffset(current: CGFloat, bounds: CGFloat, screen: CGFloat) -> CGFloat {
        let maxOffset = max(0, (bounds - screen) / 2)
        return min(max(current, -maxOffset), maxOffset)
    }
    
    private func clampOffsetToBounds(screenSize: CGSize, boundsSize: CGSize) {
        let maxOffsetX = max(0, (boundsSize.width * scale - screenSize.width) / 2)
        let maxOffsetY = max(0, (boundsSize.height * scale - screenSize.height) / 2)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
            offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
        }
    }
    
    private func autoZoomToFit() {
        let treeCount = fullyGrownTrees.count
        if treeCount > 5 {
            scale = max(minScale, 1.0 - CGFloat(treeCount) * 0.03)
        }
    }
    
    private func handleTreeTap(tree: GrowingTree) {
        Theme.Haptics.light()
        
        // Find the entry from when the tree was fully grown
        let calendar = Calendar.current
        let completionDay = tree.plantedDate.addingTimeInterval(TimeInterval(tree.daysToGrow * 24 * 60 * 60))
        
        // Find entries around that date
        let relevantEntries = entries.filter { entry in
            calendar.isDate(entry.date, inSameDayAs: completionDay) ||
            (entry.date < completionDay &&
             calendar.dateComponents([.day], from: entry.date, to: completionDay).day ?? 0 <= 1)
        }
        
        if let lastEntry = relevantEntries.first {
            selectedEntry = lastEntry
        } else if let latestEntry = entries.first {
            // Fallback to most recent entry
            selectedEntry = latestEntry
        }
    }
}

// MARK: - Garden Tree View

struct GardenTreeView: View {
    let tree: GrowingTree
    let globalScale: CGFloat
    
    @State private var isAnimating = false
    
    private var treeType: TreeType {
        TreeType(rawValue: tree.treeType) ?? .oak
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Tree with shadow
            ZStack {
                Text(treeType.emoji)
                    .font(.system(size: 50))
                    .opacity(0.3)
                    .blur(radius: 3)
                    .offset(x: 3, y: 5)
                
                Text(treeType.emoji)
                    .font(.system(size: 50))
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
            }
            
            // Label (visible when zoomed in)
            if globalScale > 0.5 {
                Text(treeType.name)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .opacity(globalScale > 0.7 ? 1.0 : (globalScale - 0.5) * 5.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double.random(in: 0...0.2))) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FullGardenView()
    }
    .modelContainer(for: [GrowingTree.self, EmotionEntry.self], inMemory: true)
}
