//
//  TestGardenView.swift
//  pocket-garden
//
//  Testing View - 100 Tree Playground
//

import SwiftUI
import Darwin

// MARK: - Test Tree Data

struct TestTree: Identifiable {
    let id = UUID()
    let type: TreeType
    let position: CGPoint
    let scale: CGFloat
    let plantedDaysAgo: Int
    
    var emoji: String { type.emoji }
    var name: String { type.name }
}

// MARK: - Test Garden View

struct TestGardenView: View {
    @State private var trees: [TestTree] = []
    @State private var scale: CGFloat = 0.5
    @State private var offset: CGSize = .zero
    @State private var layoutStyle: LayoutStyle = .forest // Default to forest
    @State private var showLayoutPicker = false
    
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero
    
    private let treeCount = 100
    private let minScale: CGFloat = 0.2
    private let maxScale: CGFloat = 2.0
    private let treeSize: CGFloat = 60 // Size of each tree for collision detection
    private let treePadding: CGFloat = 15 // Minimum space between trees
    
    enum LayoutStyle: String, CaseIterable {
        case forest = "Forest"
        case spiral = "Spiral"
        case grid = "Grid"
        case random = "Random"
        
        var icon: String {
            switch self {
            case .spiral: return "hurricane"
            case .grid: return "square.grid.2x2"
            case .random: return "sparkles"
            case .forest: return "tree"
            }
        }
    }
    
    // Canvas size with proper padding for all trees
    private var canvasSize: CGFloat {
        1200 // Fixed size that fits well with monthly layout
    }
    
    // Safe area margins to keep trees within scrollable bounds
    private let safeMargin: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Background
            ForestBackgroundView(weather: .sunny, scrollOffset: 0)
            
            // Canvas with trees
            gardenCanvas
            
            // Top stats bar
            VStack {
                statsBar
                Spacer()
            }
            
            // Layout picker button
            VStack {
                Spacer()
                HStack {
                    layoutPickerButton
                    Spacer()
                }
                .padding(Spacing.xl)
            }
        }
        .navigationTitle("Test Garden (100 Trees)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            generateTrees()
        }
    }
    
    // MARK: - Garden Canvas
    
    private var gardenCanvas: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack {
                    // Trees positioned relative to center
                    ForEach(trees) { tree in
                        TestTreeView(tree: tree, globalScale: scale)
                            .position(x: tree.position.x, y: tree.position.y)
                    }
                }
                .frame(width: canvasSize, height: canvasSize)
                .scaleEffect(scale * magnifyBy, anchor: .center)
                .frame(
                    width: canvasSize * scale * magnifyBy,
                    height: canvasSize * scale * magnifyBy
                )
            }
            .gesture(
                MagnificationGesture()
                    .updating($magnifyBy) { value, state, _ in
                        state = value
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3)) {
                            scale = min(max(scale * value, minScale), maxScale)
                        }
                    }
            )
        }
    }
    
    // MARK: - Stats Bar
    
    private var statsBar: some View {
        HStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "tree.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.primaryGreen)
                
                Text("\(treeCount)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("Test Trees")
                    .font(Typography.callout)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Zoom indicator
            HStack(spacing: Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                
                Text(String(format: "%.0f%%", scale * 100))
                    .font(Typography.callout)
                    .foregroundColor(.textSecondary)
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
    
    // MARK: - Layout Picker
    
    private var layoutPickerButton: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if showLayoutPicker {
                VStack(spacing: Spacing.xs) {
                    ForEach(LayoutStyle.allCases, id: \.self) { style in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                layoutStyle = style
                                showLayoutPicker = false
                                generateTrees()
                            }
                        }) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: style.icon)
                                    .font(.system(size: 16))
                                Text(style.rawValue)
                                    .font(Typography.callout)
                            }
                            .foregroundColor(layoutStyle == style ? .white : .textPrimary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .fill(layoutStyle == style ? Color.primaryGreen : Color.cardBackground)
                            )
                        }
                    }
                }
                .padding(Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color.cardBackground.opacity(0.95))
                        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
                )
                .frame(width: 140)
                .transition(.scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity))
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showLayoutPicker.toggle()
                }
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: layoutStyle.icon)
                        .font(.system(size: 16, weight: .medium))
                    
                    if !showLayoutPicker {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.primaryGreen)
                        .shadow(color: Color.primaryGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func generateTrees() {
        trees = []
        
        switch layoutStyle {
        case .spiral:
            generateSpiralLayout()
            
        case .grid:
            generateGridLayout()
            
        case .random:
            generateRandomLayout()
            
        case .forest:
            generateMonthlyForestLayout()
        }
    }
    
    // MARK: - Layout Generators
    
    private func generateSpiralLayout() {
        let center = CGPoint(x: canvasSize / 2, y: canvasSize / 2)
        let minDistance = treeSize + treePadding
        
        for i in 0..<treeCount {
            // Golden angle spiral with proper spacing
            let angle = Double(i) * 2.39996323 // Golden angle in radians
            let radius = minDistance + Double(i) * (minDistance * 0.4)
            var x = center.x + CGFloat(Darwin.cos(angle) * radius)
            var y = center.y + CGFloat(Darwin.sin(angle) * radius)
            
            // Clamp to safe bounds
            x = clampToSafeBounds(x)
            y = clampToSafeBounds(y)
            
            trees.append(TestTree(
                type: TreeType.allCases[i % TreeType.allCases.count],
                position: CGPoint(x: x, y: y),
                scale: CGFloat.random(in: 0.85...1.15),
                plantedDaysAgo: Int.random(in: 7...365)
            ))
        }
    }
    
    private func generateGridLayout() {
        let cols = Int(ceil(sqrt(Double(treeCount))))
        let spacing = treeSize + treePadding + 20
        let gridWidth = CGFloat(cols) * spacing
        let startX = (canvasSize - gridWidth) / 2 + spacing / 2
        let startY = safeMargin + spacing / 2
        
        for i in 0..<treeCount {
            let row = i / cols
            let col = i % cols
            let x = startX + CGFloat(col) * spacing
            let y = startY + CGFloat(row) * spacing
            
            trees.append(TestTree(
                type: TreeType.allCases[i % TreeType.allCases.count],
                position: CGPoint(x: x, y: y),
                scale: CGFloat.random(in: 0.9...1.1),
                plantedDaysAgo: Int.random(in: 7...365)
            ))
        }
    }
    
    private func generateRandomLayout() {
        var placedPositions: [CGPoint] = []
        let minDistance = treeSize + treePadding
        
        for i in 0..<treeCount {
            var position: CGPoint
            var attempts = 0
            let maxAttempts = 100
            
            repeat {
                position = CGPoint(
                    x: CGFloat.random(in: safeMargin...(canvasSize - safeMargin)),
                    y: CGFloat.random(in: safeMargin...(canvasSize - safeMargin))
                )
                attempts += 1
            } while hasOverlap(position, with: placedPositions, minDistance: minDistance) && attempts < maxAttempts
            
            placedPositions.append(position)
            
            trees.append(TestTree(
                type: TreeType.allCases[i % TreeType.allCases.count],
                position: position,
                scale: CGFloat.random(in: 0.8...1.2),
                plantedDaysAgo: Int.random(in: 7...365)
            ))
        }
    }
    
    /// Monthly forest layout - each cluster represents a month
    private func generateMonthlyForestLayout() {
        var placedPositions: [CGPoint] = []
        let minDistance = treeSize + treePadding
        
        // Create 4 monthly clusters (representing 4 months)
        // Arranged in a 2x2 grid pattern
        let monthNames = ["October", "November", "December", "January"]
        let treesPerMonth = treeCount / 4
        
        // Define cluster centers in a 2x2 grid with good spacing
        let clusterCenters: [CGPoint] = [
            CGPoint(x: canvasSize * 0.3, y: canvasSize * 0.3),   // Top-left: October
            CGPoint(x: canvasSize * 0.7, y: canvasSize * 0.3),   // Top-right: November
            CGPoint(x: canvasSize * 0.3, y: canvasSize * 0.7),   // Bottom-left: December
            CGPoint(x: canvasSize * 0.7, y: canvasSize * 0.7),   // Bottom-right: January
        ]
        
        let clusterRadius: CGFloat = 140 // Max radius for each monthly cluster
        
        for monthIndex in 0..<4 {
            let clusterCenter = clusterCenters[monthIndex]
            let startIndex = monthIndex * treesPerMonth
            let endIndex = min(startIndex + treesPerMonth, treeCount)
            
            for i in startIndex..<endIndex {
                var position: CGPoint
                var attempts = 0
                let maxAttempts = 50
                
                repeat {
                    // Place trees in concentric rings within the cluster
                    let treeIndexInCluster = i - startIndex
                    let ring = treeIndexInCluster / 8 // 8 trees per ring
                    let angleOffset = Double(treeIndexInCluster % 8) * (.pi / 4) + Double(ring) * 0.3
                    let ringRadius = 30 + CGFloat(ring) * 35
                    
                    // Add some randomness but keep it organized
                    let jitterX = CGFloat.random(in: -15...15)
                    let jitterY = CGFloat.random(in: -15...15)
                    
                    var x = clusterCenter.x + CGFloat(Darwin.cos(angleOffset)) * min(ringRadius, clusterRadius) + jitterX
                    var y = clusterCenter.y + CGFloat(Darwin.sin(angleOffset)) * min(ringRadius, clusterRadius) + jitterY
                    
                    // Clamp to safe bounds
                    x = clampToSafeBounds(x)
                    y = clampToSafeBounds(y)
                    
                    position = CGPoint(x: x, y: y)
                    attempts += 1
                } while hasOverlap(position, with: placedPositions, minDistance: minDistance) && attempts < maxAttempts
                
                placedPositions.append(position)
                
                // Assign tree type based on month theme
                let treeType: TreeType
                switch monthIndex {
                case 0: treeType = .oak      // October - oak trees
                case 1: treeType = .pine     // November - pine trees
                case 2: treeType = .cherry   // December - cherry blossoms
                default: treeType = TreeType.allCases[i % TreeType.allCases.count]
                }
                
                trees.append(TestTree(
                    type: treeType,
                    position: position,
                    scale: CGFloat.random(in: 0.8...1.1),
                    plantedDaysAgo: (4 - monthIndex) * 30 + Int.random(in: 0...29) // Older trees for earlier months
                ))
            }
        }
    }
    
    // MARK: - Collision Detection
    
    private func hasOverlap(_ position: CGPoint, with existingPositions: [CGPoint], minDistance: CGFloat) -> Bool {
        for existing in existingPositions {
            let dx = position.x - existing.x
            let dy = position.y - existing.y
            let distance = sqrt(dx * dx + dy * dy)
            if distance < minDistance {
                return true
            }
        }
        return false
    }
    
    private func clampToSafeBounds(_ value: CGFloat) -> CGFloat {
        return min(max(value, safeMargin), canvasSize - safeMargin)
    }
    
    private func calculateBounds(screenSize: CGSize) -> CGSize {
        guard !trees.isEmpty else { return screenSize }
        
        let padding: CGFloat = 100
        let minX = trees.map { $0.position.x }.min() ?? 0
        let maxX = trees.map { $0.position.x }.max() ?? canvasSize
        let minY = trees.map { $0.position.y }.min() ?? 0
        let maxY = trees.map { $0.position.y }.max() ?? canvasSize
        
        let width = max(screenSize.width, maxX - minX + padding * 2)
        let height = max(screenSize.height, maxY - minY + padding * 2)
        
        return CGSize(width: width, height: height)
    }
    
    private func clampOffset(current: CGFloat, bounds: CGFloat, screen: CGFloat) -> CGFloat {
        let maxOffset = max(0, (bounds - screen) / 2)
        return min(max(current, -maxOffset), maxOffset)
    }
}

// MARK: - Test Tree View

struct TestTreeView: View {
    let tree: TestTree
    let globalScale: CGFloat
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Text(tree.emoji)
                    .font(.system(size: 45 * tree.scale))
                    .opacity(0.3)
                    .blur(radius: 2)
                    .offset(x: 2, y: 4)
                
                Text(tree.emoji)
                    .font(.system(size: 45 * tree.scale))
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
            }
            
            if globalScale > 0.5 {
                Text(tree.name)
                    .font(.system(size: 10 * tree.scale))
                    .foregroundColor(.textSecondary)
                    .opacity(globalScale > 0.7 ? 1.0 : (globalScale - 0.5) * 5.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double.random(in: 0...0.3))) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TestGardenView()
    }
}
