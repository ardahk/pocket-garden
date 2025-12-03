//
//  ForestGardenViewRedesigned.swift
//  pocket-garden
//
//  Redesigned Forest with Growing Tree System
//

import SwiftUI
import SwiftData
import Darwin

struct ForestGardenViewRedesigned: View {
    @Query private var grownTrees: [GrowingTree]
    @Query(sort: \EmotionEntry.date, order: .reverse) private var entries: [EmotionEntry]
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentTree: GrowingTree?
    @State private var showPlantingAnimation = false
    @State private var showWateringAnimation = false
    @State private var showTreeSelection = false
    @State private var selectedTreeType: TreeType = .oak
    @State private var showTreeInfo = false
    @State private var selectedEntry: EmotionEntry?
    
    var body: some View {
        ZStack {
            // Background
            ForestBackgroundView(weather: .sunny, scrollOffset: 0)
            
            if grownTrees.isEmpty && currentTree == nil {
                emptyStateView
            } else {
                currentTreeCanvasView
            }
            
            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    actionButton
                        .padding(Spacing.xl)
                }
            }
            
            // Animations
            if showPlantingAnimation {
                PlantingAnimationView()
                    .transition(.opacity)
            }
            
            if showWateringAnimation {
                WateringAnimationView()
                    .transition(.opacity)
            }
            
            // Stats overlay
            statsOverlay
        }
        .navigationTitle("Your Garden")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(destination: TestGardenView()) {
                    Image(systemName: "flask.fill")
                        .foregroundColor(.primaryGreen)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if currentTree != nil {
                    Button {
                        showTreeInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.primaryGreen)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showTreeSelection) {
            TreeSelectionSheet(
                selectedType: $selectedTreeType,
                hasJournaledToday: hasJournaledToday
            ) {
                plantNewTree(type: selectedTreeType)
            }
        }
        .sheet(isPresented: $showTreeInfo) {
            if let tree = currentTree {
                TreeInfoSheet(treeType: TreeType(rawValue: tree.treeType) ?? .oak)
            }
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailViewRedesigned(entry: entry)
        }
        .onAppear {
            loadCurrentTree()
            checkForWatering()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.xxxl) {
            Spacer()
            
            VStack(spacing: Spacing.xl) {
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
                    
                    Text("🌱")
                        .font(.system(size: 100))
                }
                .fadeIn()
                
                VStack(spacing: Spacing.md) {
                    Text("Plant Your First Tree")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Start your journey by planting a tree. Water it daily with journal entries and watch it grow over time!")
                        .font(Typography.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                    
                    Text("💡 Tap the button below to choose your first tree")
                        .font(Typography.callout)
                        .foregroundColor(.primaryGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                .fadeIn(delay: 0.2)
            }
            
            Spacer()
        }
        .padding(Layout.screenPadding)
    }
    
    // MARK: - Current Tree Canvas View
    
    private var currentTreeCanvasView: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                // Current growing tree (center)
                if let tree = currentTree {
                    CurrentTreeView(tree: tree)
                        .onTapGesture {
                            handleTreeTap(tree: tree)
                        }
                }
                
                Spacer()
                
                // All trees chip (only show if there are fully grown trees)
                if fullyGrownTreeCount > 0 {
                    NavigationLink(destination: FullGardenView()) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "tree.fill")
                                .font(.system(size: 14, weight: .medium))
                            
                            Text("All trees")
                                .font(Typography.callout)
                            
                            Text("\(fullyGrownTreeCount)")
                                .font(Typography.footnote)
                                .foregroundColor(.primaryGreen.opacity(0.8))
                        }
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            Capsule()
                                .fill(Color.cardBackground.opacity(0.95))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.primaryGreen.opacity(0.25), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
                        )
                        .foregroundColor(.primaryGreen)
                    }
                    .padding(.bottom, 120)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var fullyGrownTreeCount: Int {
        grownTrees.filter { $0.isFullyGrown }.count
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Group {
            if let tree = currentTree {
                if tree.isFullyGrown {
                    // Plant new tree button
                    ForestActionButton(
                        icon: "plus.circle.fill",
                        label: "Plant New Tree",
                        color: .primaryGreen
                    ) {
                        showTreeSelection = true
                    }
                } else if tree.canWaterToday() && !entries.isEmpty && Calendar.current.isDateInToday(entries.first?.date ?? Date.distantPast) {
                    // Water button (only if journaled today)
                    ForestActionButton(
                        icon: "drop.fill",
                        label: "Water Tree",
                        color: .emotionContent
                    ) {
                        waterCurrentTree()
                    }
                } else {
                    EmptyView()
                }
            } else {
                // Plant first tree
                ForestActionButton(
                    icon: "leaf.fill",
                    label: "Plant Tree",
                    color: .primaryGreen
                ) {
                    showTreeSelection = true
                }
            }
        }
    }
    
    // MARK: - Stats Overlay
    
    private var statsOverlay: some View {
        VStack {
            HStack(spacing: Spacing.md) {
                if let tree = currentTree {
                    // Current tree progress
                    statsCard(
                        icon: "leaf.fill",
                        value: "\(tree.waterCount)/\(tree.daysToGrow)",
                        label: "Days",
                        color: .primaryGreen
                    )
                }
                
                // Total trees
                statsCard(
                    icon: "tree.fill",
                    value: "\(grownTrees.count)",
                    label: "Trees",
                    color: .emotionContent
                )
                
                // Streak
                statsCard(
                    icon: "flame.fill",
                    value: "\(currentStreak)",
                    label: "Streak",
                    color: .accentGold
                )
            }
            .padding(Spacing.md)
            .background(
                Capsule()
                    .fill(Color.cardBackground.opacity(0.95))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
            .padding(.horizontal, Layout.screenPadding)
            .padding(.top, Spacing.sm)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadCurrentTree() {
        // Find the tree that's not fully grown
        currentTree = grownTrees.first(where: { !$0.isFullyGrown })
    }
    
    private func checkForWatering() {
        // Auto-water if user journaled today and hasn't watered yet
        guard let tree = currentTree,
              tree.canWaterToday(),
              let todayEntry = entries.first,
              Calendar.current.isDateInToday(todayEntry.date) else {
            return
        }
        
        // Check if this entry was created after last watering
        if let lastWatered = tree.lastWateredDate {
            if todayEntry.date > lastWatered {
                waterCurrentTree()
            }
        } else {
            waterCurrentTree()
        }
    }
    
    private func waterCurrentTree() {
        guard let tree = currentTree else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showWateringAnimation = true
        }
        
        tree.water()
        try? modelContext.save()
        
        Theme.Haptics.success()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showWateringAnimation = false
            }
            
            // Check if tree is now fully grown
            if tree.isFullyGrown {
                // Show celebration
                Theme.Haptics.success()
            }
        }
    }
    
    private func plantNewTree(type: TreeType) {
        // Check if user has journaled today before allowing planting
        guard hasJournaledToday else {
            return
        }
        
        // Move current tree to grown trees if it's fully grown
        if let tree = currentTree, tree.isFullyGrown {
            // Keep it in the database, it's already there
        }
        
        // Find a nice position for the new tree
        let position = findNextTreePosition()
        
        // Create new tree
        let newTree = GrowingTree(
            treeType: type.rawValue,
            position: position
        )
        
        modelContext.insert(newTree)
        currentTree = newTree
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            showPlantingAnimation = true
        }
        
        Theme.Haptics.success()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showPlantingAnimation = false
            }
        }
        
        try? modelContext.save()
    }
    
    private func findNextTreePosition() -> GrowingTreePosition {
        // Simple spiral placement algorithm
        let count = grownTrees.count
        let angle = Double(count) * 2.4 // Golden angle
        let radius = 0.15 + (Double(count) * 0.08)
        
        let x = 0.5 + Darwin.cos(angle) * radius
        let y = 0.5 + Darwin.sin(angle) * radius
        
        return GrowingTreePosition(
            x: min(max(x, 0.1), 0.9),
            y: min(max(y, 0.2), 0.8)
        )
    }
    
    private func handleTreeTap(tree: GrowingTree) {
        Theme.Haptics.light()
        
        if tree.isFullyGrown {
            // For fully grown trees, find the last entry from when it was fully grown
            // This is when waterCount reached daysToGrow
            let calendar = Calendar.current
            let completionDay = tree.plantedDate.addingTimeInterval(TimeInterval(tree.daysToGrow * 24 * 60 * 60))
            
            // Find entries around that date
            let relevantEntries = entries.filter { entry in
                calendar.isDate(entry.date, inSameDayAs: completionDay) ||
                entry.date < completionDay && 
                calendar.dateComponents([.day], from: entry.date, to: completionDay).day ?? 0 <= 1
            }
            
            if let lastEntry = relevantEntries.first {
                selectedEntry = lastEntry
            }
        } else {
            // For growing trees, show the latest entry (most recent watering)
            if let latestEntry = entries.first {
                selectedEntry = latestEntry
            }
        }
    }
    
    private func statsCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Text(label)
                .font(Typography.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(minWidth: 70)
    }
    
    private var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        
        for i in 0..<entries.count {
            let expectedDate = calendar.date(byAdding: .day, value: -i, to: Date())!
            if entries.first(where: {
                calendar.isDate($0.date, inSameDayAs: expectedDate)
            }) != nil {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var hasJournaledToday: Bool {
        guard let todayEntry = entries.first else { return false }
        return Calendar.current.isDateInToday(todayEntry.date)
    }
}

// MARK: - Supporting Views

struct TreeInForest: View {
    let tree: GrowingTree
    let scale: CGFloat
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(TreeType(rawValue: tree.treeType)?.emoji ?? "🌳")
                .font(.system(size: 60 * scale))
            
            Text(TreeType(rawValue: tree.treeType)?.name ?? "Tree")
                .font(.system(size: 12 * scale))
                .foregroundColor(.textSecondary)
        }
    }
}

struct CurrentTreeView: View {
    let tree: GrowingTree
    
    private var treeType: TreeType {
        TreeType(rawValue: tree.treeType) ?? .oak
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Tree visual - growth stage only
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.primaryGreen.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                // Growth stage emoji (seed -> sapling -> tree)
                Text(treeType.emojiForStage(tree.growthStage))
                    .font(.system(size: 100))
            }
            
            // Progress card
            Card {
                VStack(spacing: Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack(spacing: Spacing.xs) {
                                Text(treeType.emoji)
                                    .font(.system(size: 24))
                                Text(treeType.name)
                                    .font(Typography.headline)
                                    .foregroundColor(.textPrimary)
                            }
                            
                            Text("Day \(tree.waterCount) of \(tree.daysToGrow)")
                                .font(Typography.callout)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                        
                        if tree.isFullyGrown {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.successGreen)
                        }
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.backgroundCream)
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(Color.primaryGreen)
                                .frame(width: geometry.size.width * tree.growthProgress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    if tree.isFullyGrown {
                        Text("🎉 Fully grown! Plant a new tree to continue.")
                            .font(Typography.callout)
                            .foregroundColor(.primaryGreen)
                            .multilineTextAlignment(.center)
                    } else if tree.canWaterToday() {
                        Text("💧 Journal today to water your tree!")
                            .font(Typography.callout)
                            .foregroundColor(.emotionContent)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("✅ Watered today! Come back tomorrow.")
                            .font(Typography.callout)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(width: 280)
        }
    }
}

struct ForestActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                Capsule()
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 4)
            )
        }
    }
}

struct TreeSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedType: TreeType
    let hasJournaledToday: Bool
    let onPlant: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.peacefulGradient
                    .ignoresSafeArea()
                
                VStack(spacing: Spacing.xl) {
                    Text("Choose Your Tree")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .padding(.top, Spacing.xl)
                    
                    ForEach(TreeType.allCases, id: \.self) { type in
                        TreeTypeCard(
                            type: type,
                            isSelected: selectedType == type
                        ) {
                            selectedType = type
                        }
                    }
                    
                    Spacer()
                    
                    if !hasJournaledToday {
                        Card(backgroundColor: .secondaryTerracotta.opacity(0.1)) {
                            VStack(spacing: Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondaryTerracotta)
                                
                                Text("Journal First!")
                                    .font(Typography.headline)
                                    .foregroundColor(.textPrimary)
                                
                                Text("Create a journal entry today before planting your tree. Each journal waters your tree!")
                                    .font(Typography.callout)
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, Spacing.md)
                        }
                        .padding(.horizontal, Layout.screenPadding)
                        
                        PrimaryButton("Go to Home", icon: "house.fill") {
                            dismiss()
                        }
                        .padding(.horizontal, Layout.screenPadding)
                    } else {
                        PrimaryButton("Plant \(selectedType.name)", icon: "leaf.fill") {
                            onPlant()
                            dismiss()
                        }
                        .padding(.horizontal, Layout.screenPadding)
                    }
                }
                .padding(.horizontal, Layout.screenPadding)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGreen)
                }
            }
        }
    }
}

struct TreeTypeCard: View {
    let type: TreeType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            onTap()
        }) {
            HStack(spacing: Spacing.lg) {
                Text(type.emoji)
                    .font(.system(size: 50))
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(type.name)
                        .font(Typography.headline)
                        .foregroundColor(.textPrimary)
                    
                    Text(type.description)
                        .font(Typography.callout)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.primaryGreen)
                }
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                            .stroke(isSelected ? Color.primaryGreen : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PlantingAnimationView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.xl) {
                Text("🌱")
                    .font(.system(size: 100))
                    .scaleEffect(1.0 + Darwin.sin(phase) * 0.2)
                    .rotationEffect(.degrees(Darwin.sin(phase) * 10))
                
                Text("Planting your tree...")
                    .font(Typography.title2)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }
}

struct WateringAnimationView: View {
    @State private var drops: [WaterDrop] = []
    
    var body: some View {
        ZStack {
            ForEach(drops) { drop in
                Text("💧")
                    .font(.system(size: 30))
                    .position(x: drop.x, y: drop.y)
                    .opacity(drop.opacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        for i in 0..<10 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                let drop = WaterDrop(
                    x: CGFloat.random(in: 100...300),
                    y: -50,
                    opacity: 1.0
                )
                drops.append(drop)
                
                withAnimation(.easeIn(duration: 1.0)) {
                    if let index = drops.firstIndex(where: { $0.id == drop.id }) {
                        drops[index].y = 400
                        drops[index].opacity = 0
                    }
                }
            }
        }
    }
}

struct WaterDrop: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}
