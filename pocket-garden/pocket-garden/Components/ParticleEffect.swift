//
//  ParticleEffect.swift
//  pocket-garden
//
//  Beautiful Particle Effects for Celebrations
//

import SwiftUI

// MARK: - Confetti View

struct ConfettiView: View {
    let particleCount: Int
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ConfettiPiece(particle: particle)
            }
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: -200...200),
                y: -CGFloat.random(in: 0...100),
                rotation: Double.random(in: 0...360),
                color: [Color.emotionJoy, Color.accentGold, Color.primaryGreen, Color.secondaryTerracotta].randomElement()!,
                size: CGFloat.random(in: 8...16)
            )
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let color: Color
    let size: CGFloat
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    @State private var offsetY: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 0.6)
            .rotationEffect(.degrees(rotation))
            .offset(x: particle.x, y: particle.y + offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 3.0)) {
                    offsetY = 800
                    opacity = 0
                }

                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Floating Leaves

struct FloatingLeavesView: View {
    let leafCount: Int
    @State private var leaves: [Leaf] = []

    var body: some View {
        ZStack {
            ForEach(leaves) { leaf in
                LeafParticle(leaf: leaf)
            }
        }
        .onAppear {
            generateLeaves()
        }
    }

    private func generateLeaves() {
        leaves = (0..<leafCount).map { index in
            Leaf(
                x: CGFloat.random(in: -150...150),
                y: -CGFloat(index) * 50,
                size: CGFloat.random(in: 12...24),
                delay: Double(index) * 0.2
            )
        }
    }
}

struct Leaf: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let delay: Double
}

struct LeafParticle: View {
    let leaf: Leaf
    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        LeafShape()
            .fill(
                LinearGradient(
                    colors: [Color.primaryGreen, Color.primaryGreen.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: leaf.size * 0.6, height: leaf.size)
            .rotationEffect(.degrees(rotation))
            .offset(x: leaf.x + offsetX, y: leaf.y + offsetY)
            .opacity(opacity)
            .onAppear {
                // Falling animation
                withAnimation(.easeIn(duration: 4.0).delay(leaf.delay)) {
                    offsetY = 900
                    opacity = 0
                }

                // Swaying animation
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(leaf.delay)) {
                    offsetX = CGFloat.random(in: -30...30)
                }

                // Rotation animation
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false).delay(leaf.delay)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Sparkles

struct SparklesView: View {
    let sparkleCount: Int
    @State private var sparkles: [Sparkle] = []

    var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                SparkleParticle(sparkle: sparkle)
            }
        }
        .onAppear {
            generateSparkles()
        }
    }

    private func generateSparkles() {
        sparkles = (0..<sparkleCount).map { index in
            Sparkle(
                x: CGFloat.random(in: -150...150),
                y: CGFloat.random(in: -200...200),
                delay: Double(index) * 0.1
            )
        }
    }
}

struct Sparkle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let delay: Double
}

struct SparkleParticle: View {
    let sparkle: Sparkle
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 20))
            .foregroundColor(.accentGold)
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .offset(x: sparkle.x, y: sparkle.y)
            .onAppear {
                // Pop in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(sparkle.delay)) {
                    scale = 1.0
                    opacity = 1.0
                }

                // Fade out
                withAnimation(.easeOut(duration: 1.0).delay(sparkle.delay + 0.5)) {
                    opacity = 0
                    scale = 1.5
                }

                // Rotation
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false).delay(sparkle.delay)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Butterflies

struct ButterfliesView: View {
    let butterflyCount: Int
    @State private var butterflies: [Butterfly] = []

    var body: some View {
        ZStack {
            ForEach(butterflies) { butterfly in
                ButterflyParticle(butterfly: butterfly)
            }
        }
        .onAppear {
            generateButterflies()
        }
    }

    private func generateButterflies() {
        butterflies = (0..<butterflyCount).map { index in
            Butterfly(
                startX: CGFloat.random(in: -100...100),
                startY: CGFloat.random(in: 100...400),
                delay: Double(index) * 0.5
            )
        }
    }
}

struct Butterfly: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let delay: Double
}

struct ButterflyParticle: View {
    let butterfly: Butterfly
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    @State private var wingRotation: Double = 0

    var body: some View {
        HStack(spacing: 0) {
            // Left wing
            FlowerPetalShape()
                .fill(
                    LinearGradient(
                        colors: [Color.accentGold, Color.emotionJoy],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 12, height: 16)
                .rotationEffect(.degrees(wingRotation), anchor: .trailing)

            // Body
            Capsule()
                .fill(Color.textPrimary)
                .frame(width: 3, height: 16)

            // Right wing
            FlowerPetalShape()
                .fill(
                    LinearGradient(
                        colors: [Color.emotionJoy, Color.accentGold],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                )
                .frame(width: 12, height: 16)
                .scaleEffect(x: -1)
                .rotationEffect(.degrees(-wingRotation), anchor: .leading)
        }
        .offset(x: butterfly.startX + offsetX, y: butterfly.startY + offsetY)
        .onAppear {
            // Fluttering wings
            withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true).delay(butterfly.delay)) {
                wingRotation = 20
            }

            // Flying path
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true).delay(butterfly.delay)) {
                offsetX = CGFloat.random(in: -100...100)
            }

            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true).delay(butterfly.delay)) {
                offsetY = CGFloat.random(in: -150...150)
            }
        }
    }
}

// MARK: - Preview

#Preview("Confetti") {
    ZStack {
        Color.backgroundCream
            .ignoresSafeArea()

        ConfettiView(particleCount: 30)
    }
}

#Preview("Floating Leaves") {
    ZStack {
        Color.backgroundCream
            .ignoresSafeArea()

        FloatingLeavesView(leafCount: 15)
    }
}

#Preview("Sparkles") {
    ZStack {
        Color.backgroundCream
            .ignoresSafeArea()

        SparklesView(sparkleCount: 20)
    }
}

#Preview("Butterflies") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "87CEEB"), Color(hex: "E0F6FF")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        ButterfliesView(butterflyCount: 5)
    }
}
