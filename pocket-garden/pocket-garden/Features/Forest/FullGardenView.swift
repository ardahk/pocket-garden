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
    
    @State private var scale: CGFloat = 1.0
    @State private var selectedTree: GrowingTree?
    @State private var zoomAnchor: UnitPoint = .center
    @State private var hasActiveZoomAnchor: Bool = false
    
    @GestureState private var magnifyBy: CGFloat = 1.0
    
    private let maxScale: CGFloat = 2.0
    
    
    private var fullyGrownTrees: [GrowingTree] {
        grownTrees.filter { $0.isFullyGrown }
    }
    
    private var currentlyGrowingTree: GrowingTree? {
        grownTrees.first(where: { !$0.isFullyGrown })
    }
    
    private var totalTreeCount: Int {
        // Count fully grown trees + 1 if there's a tree currently growing
        fullyGrownTrees.count + (currentlyGrowingTree != nil ? 1 : 0)
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
            
            if fullyGrownTrees.isEmpty && currentlyGrowingTree == nil {
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
        .sheet(item: $selectedTree) { tree in
            TreeDetailView(tree: tree)
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
            let canvasSize = calculateCanvasSize(positions: treePositions)
            let dynamicMinScale = calculateMinScale(positions: treePositions, screenSize: geometry.size)
            
            // Clamp scale continuously so pinch can't over-zoom while fingers are down
            let clampedScale = min(max(scale * magnifyBy, dynamicMinScale), maxScale)
            
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack {
                    // Fully grown trees
                    ForEach(Array(zip(fullyGrownTrees, treePositions)), id: \.0.id) { tree, position in
                        GardenTreeView(tree: tree, globalScale: clampedScale)
                            .position(x: position.x, y: position.y)
                            .onTapGesture {
                                handleTreeTap(tree: tree)
                            }
                    }
                    
                    // Currently growing tree (shown with its current stage emoji)
                    if let growingTree = currentlyGrowingTree {
                        let growingPosition = calculateGrowingTreePosition(in: geometry.size, existingPositions: treePositions)
                        GrowingTreeInGardenView(tree: growingTree, globalScale: clampedScale)
                            .position(x: growingPosition.x, y: growingPosition.y)
                            .onTapGesture {
                                handleTreeTap(tree: growingTree)
                            }
                    }
                }
                .frame(width: canvasSize.width, height: canvasSize.height)
                .scaleEffect(clampedScale, anchor: zoomAnchor)
            }
            .scrollClipDisabled(false)
            .simultaneousGesture(
                MagnificationGesture()
                    .updating($magnifyBy) { value, state, _ in
                        state = value
                        
                        // On first update in this gesture, lock the anchor to the closest tree to reduce snapping
                        if !hasActiveZoomAnchor {
                            zoomAnchor = anchorPoint(for: treePositions, canvasSize: canvasSize, viewportSize: geometry.size)
                            hasActiveZoomAnchor = true
                        }
                    }
                    .onEnded { value in
                        let newScale = scale * value
                        // Set scale directly without animation to prevent any tweaking/bouncing effect
                        let finalScale = min(max(newScale, dynamicMinScale), maxScale)
                        scale = finalScale
                        hasActiveZoomAnchor = false
                    }
            )
        }
    }
    
    /// Calculate canvas size based on tree positions
    private func calculateCanvasSize(positions: [CGPoint]) -> CGSize {
        guard !positions.isEmpty else { return CGSize(width: 400, height: 600) }
        
        let minX = positions.map { $0.x }.min() ?? 0
        let maxX = positions.map { $0.x }.max() ?? 400
        let minY = positions.map { $0.y }.min() ?? 0
        let maxY = positions.map { $0.y }.max() ?? 600
        
        let padding: CGFloat = 150
        return CGSize(
            width: max(400, maxX - minX + padding * 2),
            height: max(600, maxY - minY + padding * 2)
        )
    }
    
    /// Calculate minimum scale to ensure trees don't overlap when zoomed out
    private func calculateMinScale(positions: [CGPoint], screenSize: CGSize) -> CGFloat {
        guard positions.count > 1 else { return 0.5 }
        
        // Find the minimum distance between any two trees
        var minDistance: CGFloat = .greatestFiniteMagnitude
        for i in 0..<positions.count {
            for j in (i + 1)..<positions.count {
                let dx = positions[i].x - positions[j].x
                let dy = positions[i].y - positions[j].y
                let distance = sqrt(dx * dx + dy * dy)
                minDistance = min(minDistance, distance)
            }
        }
        
        // At minScale, trees should still have at least 60pt spacing
        let desiredMinSpacing: CGFloat = 60
        let calculatedMinScale = desiredMinSpacing / minDistance
        
        // Clamp to reasonable range
        return max(0.4, min(calculatedMinScale, 0.8))
    }
    
    /// Anchor zoom near the closest tree to the viewport center for a natural feel
    private func anchorPoint(for positions: [CGPoint], canvasSize: CGSize, viewportSize: CGSize) -> UnitPoint {
        guard !positions.isEmpty else { return .center }
        
        // Use viewport center in canvas coordinates
        let viewportCenter = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        var closest = positions.first!
        var minDist = CGFloat.greatestFiniteMagnitude
        
        for p in positions {
            let dx = p.x - viewportCenter.x
            let dy = p.y - viewportCenter.y
            let dist = dx * dx + dy * dy
            if dist < minDist {
                minDist = dist
                closest = p
            }
        }
        
        let anchorX = max(0, min(1, closest.x / canvasSize.width))
        let anchorY = max(0, min(1, closest.y / canvasSize.height))
        return UnitPoint(x: anchorX, y: anchorY)
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
            // Main stats row - capsule style matching ForestGardenViewRedesigned
            HStack(alignment: .top, spacing: Spacing.md) {
                // Tree count (includes growing tree)
                statsCard(icon: "tree.fill", value: "\(totalTreeCount)", label: "Trees", color: .primaryGreen)
                
                // Total waterings
                statsCard(icon: "drop.fill", value: "\(totalWaterings)", label: "Waterings", color: .emotionContent)
                
                // Garden age
                if let oldest = oldestTree {
                    let days = Calendar.current.dateComponents([.day], from: oldest.plantedDate, to: Date()).day ?? 0
                    statsCard(icon: "calendar", value: "\(days)", label: "Days", color: .accentGold)
                }
            }
            
            // Tree type breakdown (including growing tree)
            HStack(spacing: Spacing.md) {
                ForEach(TreeType.allCases, id: \.self) { type in
                    let fullyGrownCount = fullyGrownTrees.filter { $0.treeType == type.rawValue }.count
                    let growingCount = (currentlyGrowingTree?.treeType == type.rawValue) ? 1 : 0
                    let totalCount = fullyGrownCount + growingCount
                    
                    if totalCount > 0 {
                        HStack(spacing: 4) {
                            Text(type.emoji)
                                .font(.system(size: 14))
                            Text("\(totalCount)")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(
            Capsule()
                .fill(Color.cardBackground.opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, Layout.screenPadding)
        .padding(.top, Spacing.sm)
    }
    
    private func statsCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Text(label)
                .font(Typography.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
    
    // MARK: - Helper Functions
    
    /// Minimum distance between any two trees to prevent overlap
    private let minTreeSpacing: CGFloat = 120
    
    private func calculateTreePositions(in size: CGSize) -> [CGPoint] {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        var positions: [CGPoint] = []
        
        guard !fullyGrownTrees.isEmpty else { return positions }
        
        // First tree is always at center
        positions.append(center)
        
        // Place remaining trees using spiral placement with collision detection
        if fullyGrownTrees.count > 1 {
            let goldenAngle = .pi * (3.0 - sqrt(5.0)) // ~137.5 degrees - optimal for even distribution
            
            for i in 1..<fullyGrownTrees.count {
                var placed = false
                var attempts = 0
                let maxAttempts = 50
                
                // Start with spiral placement, increase radius until no collision
                while !placed && attempts < maxAttempts {
                    // Spiral outward with golden angle
                    let baseRadius = minTreeSpacing * 0.8 * sqrt(CGFloat(i))
                    let adjustedRadius = baseRadius + CGFloat(attempts) * 20
                    let angle = goldenAngle * Double(i) + Double(attempts) * 0.3
                    
                    let x = center.x + CGFloat(Darwin.cos(angle)) * adjustedRadius
                    let y = center.y + CGFloat(Darwin.sin(angle)) * adjustedRadius
                    let candidatePoint = CGPoint(x: x, y: y)
                    
                    if !hasCollision(point: candidatePoint, existingPoints: positions, minDistance: minTreeSpacing) {
                        positions.append(candidatePoint)
                        placed = true
                    }
                    
                    attempts += 1
                }
                
                // Fallback: place at next available spiral position with larger radius
                if !placed {
                    let fallbackRadius = minTreeSpacing * CGFloat(positions.count)
                    let angle = goldenAngle * Double(i)
                    positions.append(CGPoint(
                        x: center.x + CGFloat(Darwin.cos(angle)) * fallbackRadius,
                        y: center.y + CGFloat(Darwin.sin(angle)) * fallbackRadius
                    ))
                }
            }
        }
        
        return positions
    }
    
    /// Check if a point collides with any existing points
    private func hasCollision(point: CGPoint, existingPoints: [CGPoint], minDistance: CGFloat) -> Bool {
        for existing in existingPoints {
            let dx = point.x - existing.x
            let dy = point.y - existing.y
            let distance = sqrt(dx * dx + dy * dy)
            if distance < minDistance {
                return true
            }
        }
        return false
    }
    
    private func autoZoomToFit() {
        let treeCount = totalTreeCount
        if treeCount > 5 {
            // Gradually zoom out for more trees, but respect min scale
            scale = max(0.5, 1.0 - CGFloat(treeCount) * 0.025)
        }
    }
    
    private func calculateGrowingTreePosition(in size: CGSize, existingPositions: [CGPoint]) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // If no fully grown trees, place growing tree at center
        if existingPositions.isEmpty {
            return center
        }
        
        // Find a collision-free position using spiral placement
        let goldenAngle = .pi * (3.0 - sqrt(5.0))
        let index = existingPositions.count
        
        for attempt in 0..<50 {
            let baseRadius = minTreeSpacing * 0.8 * sqrt(CGFloat(index))
            let adjustedRadius = baseRadius + CGFloat(attempt) * 20
            let angle = goldenAngle * Double(index) + Double(attempt) * 0.3
            
            let x = center.x + CGFloat(Darwin.cos(angle)) * adjustedRadius
            let y = center.y + CGFloat(Darwin.sin(angle)) * adjustedRadius
            let candidatePoint = CGPoint(x: x, y: y)
            
            if !hasCollision(point: candidatePoint, existingPoints: existingPositions, minDistance: minTreeSpacing) {
                return candidatePoint
            }
        }
        
        // Fallback
        let fallbackRadius = minTreeSpacing * CGFloat(existingPositions.count + 1)
        let angle = goldenAngle * Double(index)
        return CGPoint(
            x: center.x + CGFloat(Darwin.cos(angle)) * fallbackRadius,
            y: center.y + CGFloat(Darwin.sin(angle)) * fallbackRadius
        )
    }
    
    private func handleTreeTap(tree: GrowingTree) {
        Theme.Haptics.light()
        selectedTree = tree
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
        // Keep label area in the layout at all times to prevent vertical “twitching”
        // while zooming (caused by conditional view insertion/removal).
        let labelOpacity: Double = {
            if globalScale <= 0.6 { return 0.0 }
            if globalScale >= 0.8 { return 1.0 }
            return Double((globalScale - 0.6) / 0.2)
        }()

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
            
            // Label (fade in/out, but keep reserved height so emoji doesn't jump)
            Text(treeType.name)
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
                .opacity(labelOpacity)
                .frame(height: 14)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double.random(in: 0...0.2))) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Growing Tree In Garden View (shows current growth stage)

struct GrowingTreeInGardenView: View {
    let tree: GrowingTree
    let globalScale: CGFloat
    
    @State private var isAnimating = false
    @State private var isPulsing = false
    
    private var treeType: TreeType {
        TreeType(rawValue: tree.treeType) ?? .oak
    }
    
    private var currentStageEmoji: String {
        treeType.emojiForStage(tree.growthStage)
    }
    
    private var progressLabel: String {
        "Day \(tree.waterCount)/\(tree.daysToGrow)"
    }
    
    var body: some View {
        // Same idea as `GardenTreeView`: don't insert/remove the label container based on zoom,
        // otherwise the emoji “twitches” vertically as layout reflows mid-gesture.
        let labelOpacity: Double = {
            if globalScale <= 0.6 { return 0.0 }
            if globalScale >= 0.8 { return 1.0 }
            return Double((globalScale - 0.6) / 0.2)
        }()

        VStack(spacing: 4) {
            // Tree with pulsing glow to indicate it's growing
            ZStack {
                // Pulsing glow effect
                Circle()
                    .fill(Color.primaryGreen.opacity(0.2))
                    .frame(width: 70, height: 70)
                    .scaleEffect(isPulsing ? 1.2 : 0.9)
                    .opacity(isPulsing ? 0.3 : 0.6)
                
                // Shadow
                Text(currentStageEmoji)
                    .font(.system(size: 50))
                    .opacity(0.3)
                    .blur(radius: 3)
                    .offset(x: 3, y: 5)
                
                // Current stage emoji
                Text(currentStageEmoji)
                    .font(.system(size: 50))
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
            }
            
            // Label with progress (fade in/out, but keep reserved height so emoji doesn't jump)
            VStack(spacing: 2) {
                Text(treeType.name)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                
                Text(progressLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.primaryGreen)
            }
            .opacity(labelOpacity)
            .frame(height: 28)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double.random(in: 0...0.2))) {
                isAnimating = true
            }
            
            // Start pulsing animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
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
