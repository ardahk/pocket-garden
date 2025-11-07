//
//  TreeView.swift
//  pocket-garden
//
//  Beautiful Tree Visualization with 5 Growth Stages
//

import SwiftUI

struct TreeView: View {
    let entry: EmotionEntry
    let size: CGSize
    let onTap: () -> Void

    @State private var isAnimating = false
    @State private var blossomOffsets: [CGSize] = []

    private var stage: TreeStage {
        TreeStage(rawValue: entry.treeStage) ?? .seed
    }

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            onTap()
        }) {
            ZStack {
                // Tree visualization
                treeBody

                // Blossoms for high ratings
                if entry.emotionRating >= 7 {
                    blossomsView
                }

                // Shadow
                treeShadow
            }
            .frame(width: size.width, height: size.height)
        }
        .buttonStyle(TreeButtonStyle())
        .onAppear {
            generateBlossomOffsets()
            withAnimation(Theme.Animation.gentleSpring.delay(0.2)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Tree Body

    @ViewBuilder
    private var treeBody: some View {
        switch stage {
        case .seed:
            seedView
        case .sprout:
            sproutView
        case .youngTree:
            youngTreeView
        case .matureTree:
            matureTreeView
        case .bloomingTree:
            bloomingTreeView
        }
    }

    // MARK: - Seed Stage (🌱)

    private var seedView: some View {
        VStack(spacing: 2) {
            // Sprout
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.primaryGreen, Color.primaryGreen.opacity(0.6)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 4, height: isAnimating ? 20 : 0)

            // Seed
            Capsule()
                .fill(Color.secondaryTerracotta.opacity(0.8))
                .frame(width: 12, height: 16)
        }
        .scaleEffect(isAnimating ? 1.0 : 0.3)
        .offset(y: size.height * 0.2)
    }

    // MARK: - Sprout Stage (🌿)

    private var sproutView: some View {
        VStack(spacing: 0) {
            // Leaves
            HStack(spacing: -4) {
                LeafShape()
                    .fill(Color.primaryGreen)
                    .frame(width: 16, height: 24)
                    .rotationEffect(.degrees(-30))

                LeafShape()
                    .fill(Color.primaryGreen.opacity(0.8))
                    .frame(width: 16, height: 24)
                    .rotationEffect(.degrees(30))
            }
            .offset(y: 8)

            // Stem
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "8B7355"),
                            Color.primaryGreen.opacity(0.6)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 6, height: isAnimating ? 40 : 0)
        }
        .scaleEffect(isAnimating ? 1.0 : 0.5)
        .offset(y: size.height * 0.15)
    }

    // MARK: - Young Tree Stage (🌳)

    private var youngTreeView: some View {
        VStack(spacing: 0) {
            // Crown
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.emotionColor(for: entry.emotionRating).opacity(0.8),
                            Color.primaryGreen.opacity(0.6)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    // Texture
                    ForEach(0..<8, id: \.self) { _ in
                        Circle()
                            .fill(Color.primaryGreen.opacity(0.3))
                            .frame(width: CGFloat.random(in: 8...15))
                            .offset(
                                x: CGFloat.random(in: -15...15),
                                y: CGFloat.random(in: -15...15)
                            )
                    }
                )

            // Trunk
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "8B7355"),
                            Color(hex: "A0826D")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 12, height: isAnimating ? 60 : 0)
        }
        .scaleEffect(isAnimating ? 1.0 : 0.6)
        .offset(y: size.height * 0.05)
    }

    // MARK: - Mature Tree Stage (🌲)

    private var matureTreeView: some View {
        VStack(spacing: 0) {
            // Large crown
            ZStack {
                // Main crown
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.emotionColor(for: entry.emotionRating).opacity(0.7),
                                Color.primaryGreen.opacity(0.8)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 70, height: 70)

                // Secondary foliage
                Circle()
                    .fill(Color.primaryGreen.opacity(0.6))
                    .frame(width: 50, height: 50)
                    .offset(x: -25, y: 10)

                Circle()
                    .fill(Color.primaryGreen.opacity(0.6))
                    .frame(width: 50, height: 50)
                    .offset(x: 25, y: 10)

                // Texture details
                ForEach(0..<12, id: \.self) { _ in
                    Circle()
                        .fill(Color.primaryGreen.opacity(0.4))
                        .frame(width: CGFloat.random(in: 10...18))
                        .offset(
                            x: CGFloat.random(in: -25...25),
                            y: CGFloat.random(in: -25...25)
                        )
                }
            }

            // Strong trunk
            RoundedRectangle(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "6F5643"),
                            Color(hex: "8B7355"),
                            Color(hex: "A0826D")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 18, height: isAnimating ? 80 : 0)
        }
        .scaleEffect(isAnimating ? 1.0 : 0.7)
        .offset(y: -size.height * 0.05)
    }

    // MARK: - Blooming Tree Stage (🌸)

    private var bloomingTreeView: some View {
        VStack(spacing: 0) {
            // Magnificent crown
            ZStack {
                // Base crown
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.emotionColor(for: entry.emotionRating).opacity(0.9),
                                Color.primaryGreen
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)

                // Multiple foliage layers
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(Color.primaryGreen.opacity(0.7))
                        .frame(width: 60, height: 60)
                        .offset(
                            x: [CGFloat]([0, -30, 30, 0])[index],
                            y: [CGFloat]([-10, 15, 15, 30])[index]
                        )
                }

                // Rich texture
                ForEach(0..<20, id: \.self) { _ in
                    Circle()
                        .fill(Color.primaryGreen.opacity(Double.random(in: 0.3...0.6)))
                        .frame(width: CGFloat.random(in: 12...22))
                        .offset(
                            x: CGFloat.random(in: -35...35),
                            y: CGFloat.random(in: -35...35)
                        )
                }
            }

            // Thick, mature trunk
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "5D4E37"),
                            Color(hex: "6F5643"),
                            Color(hex: "8B7355"),
                            Color(hex: "A0826D")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 24, height: isAnimating ? 100 : 0)
                .overlay(
                    // Bark texture
                    VStack(spacing: 8) {
                        ForEach(0..<5) { _ in
                            Capsule()
                                .fill(Color.black.opacity(0.1))
                                .frame(width: 20, height: 2)
                        }
                    }
                )
        }
        .scaleEffect(isAnimating ? 1.0 : 0.8)
        .offset(y: -size.height * 0.1)
    }

    // MARK: - Blossoms

    private var blossomsView: some View {
        ForEach(0..<stage.blossomCount(emotionRating: entry.emotionRating), id: \.self) { index in
            if index < blossomOffsets.count {
                FlowerView(
                    petalCount: 5,
                    color: blossomColor,
                    size: CGFloat.random(in: 12...18)
                )
                .offset(blossomOffsets[index])
                .opacity(isAnimating ? 1.0 : 0.0)
                .scaleEffect(isAnimating ? 1.0 : 0.0)
                .animation(
                    Theme.Animation.spring.delay(Double(index) * 0.1),
                    value: isAnimating
                )
            }
        }
    }

    private var blossomColor: Color {
        switch entry.emotionRating {
        case 9...10: return .emotionJoy
        case 8: return Color(hex: "FFB6C1") // Light pink
        case 7: return .accentGold
        default: return .primaryGreen
        }
    }

    // MARK: - Shadow

    private var treeShadow: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color.black.opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: shadowRadius
                )
            )
            .frame(width: shadowRadius * 2, height: shadowRadius * 0.5)
            .offset(y: size.height * 0.45)
            .scaleEffect(isAnimating ? 1.0 : 0.0)
    }

    private var shadowRadius: CGFloat {
        switch stage {
        case .seed: return 10
        case .sprout: return 15
        case .youngTree: return 25
        case .matureTree: return 35
        case .bloomingTree: return 45
        }
    }

    // MARK: - Helpers

    private func generateBlossomOffsets() {
        let count = stage.blossomCount(emotionRating: entry.emotionRating)
        blossomOffsets = (0..<count).map { _ in
            CGSize(
                width: CGFloat.random(in: -30...30),
                height: CGFloat.random(in: -40...20)
            )
        }
    }
}

// MARK: - Tree Button Style

struct TreeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Tree Growth Stages") {
    ScrollView {
        VStack(spacing: Spacing.xxxl) {
            ForEach(1...5, id: \.self) { stage in
                let entry = EmotionEntry(
                    emotionRating: 8,
                    treeStage: stage
                )

                VStack(spacing: Spacing.md) {
                    TreeView(
                        entry: entry,
                        size: CGSize(width: 120, height: 180)
                    ) {
                        print("Tree tapped")
                    }

                    Text(TreeStage(rawValue: stage)?.name ?? "")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding()
        .background(Color.backgroundCream)
    }
}

#Preview("Different Emotions") {
    ScrollView(.horizontal) {
        HStack(spacing: Spacing.xl) {
            ForEach([2, 5, 7, 9], id: \.self) { rating in
                VStack(spacing: Spacing.md) {
                    TreeView(
                        entry: EmotionEntry(
                            emotionRating: rating,
                            treeStage: 5
                        ),
                        size: CGSize(width: 120, height: 180)
                    ) {
                        print("Tree tapped")
                    }

                    Text("Rating: \(rating)")
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding()
        .background(Color.backgroundCream)
    }
}
