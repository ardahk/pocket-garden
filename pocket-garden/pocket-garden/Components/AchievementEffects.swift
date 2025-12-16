//
//  AchievementEffects.swift
//  pocket-garden
//
//  Premium visual effects for achievement system
//

import SwiftUI

// MARK: - Achievement Confetti View (with custom colors)

struct AchievementConfettiView: View {
    let particleCount: Int
    let colors: [Color]
    
    @State private var particles: [AchievementConfettiParticle] = []
    
    init(particleCount: Int = 50, colors: [Color] = [.accentGold, .primaryGreen, .emotionContent, .emotionCalm, .secondaryTerracotta]) {
        self.particleCount = particleCount
        self.colors = colors
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                AchievementConfettiPiece(particle: particle, colors: colors)
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<particleCount).map { index in
            AchievementConfettiParticle(
                x: CGFloat.random(in: -150...150),
                y: CGFloat.random(in: -300...(-50)),
                delay: Double(index) * 0.02
            )
        }
    }
}

struct AchievementConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let delay: Double
}

struct AchievementConfettiPiece: View {
    let particle: AchievementConfettiParticle
    let colors: [Color]
    
    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 1.0
    
    // Cache random values to prevent shape from changing during animation
    // These are initialized once and remain stable throughout the view's lifetime
    @State private var shapeType: Int = Int.random(in: 0...2)
    @State private var shapeColor: Color = .accentGold
    @State private var shapeWidth: CGFloat = 0
    @State private var shapeHeight: CGFloat = 0
    @State private var swayAmount: CGFloat = CGFloat.random(in: -40...40)
    
    private var renderedShape: some View {
        Group {
            if shapeType == 0 {
                Circle()
                    .fill(shapeColor)
                    .frame(width: shapeWidth, height: shapeHeight)
            } else if shapeType == 1 {
                Rectangle()
                    .fill(shapeColor)
                    .frame(width: shapeWidth, height: shapeHeight)
            } else {
                AchievementStar(corners: 4, smoothness: 0.4)
                    .fill(shapeColor)
                    .frame(width: shapeWidth, height: shapeHeight)
            }
        }
    }
    
    var body: some View {
        renderedShape
            .rotationEffect(.degrees(rotation))
            .offset(x: particle.x + offsetX, y: particle.y + offsetY)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                // Initialize random values once - these remain stable during animation
                shapeColor = colors.randomElement() ?? .accentGold
                
                // Set size ranges based on shape type
                switch shapeType {
                case 0: // Circle
                    shapeWidth = CGFloat.random(in: 6...12)
                    shapeHeight = shapeWidth
                case 1: // Rectangle
                    shapeWidth = CGFloat.random(in: 8...14)
                    shapeHeight = CGFloat.random(in: 4...8)
                default: // Star
                    shapeWidth = CGFloat.random(in: 10...16)
                    shapeHeight = shapeWidth
                }
                
                // Burst in
                withAnimation(.easeOut(duration: 0.3).delay(particle.delay)) {
                    opacity = 1.0
                    scale = 1.0
                }
                
                // Fall down
                withAnimation(.easeIn(duration: 2.5).delay(particle.delay + 0.2)) {
                    offsetY = 600
                    opacity = 0
                }
                
                // Sway (use cached random value)
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(particle.delay)) {
                    offsetX = swayAmount
                }
                
                // Rotate
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false).delay(particle.delay)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Achievement Star Shape

struct AchievementStar: Shape {
    let corners: Int
    let smoothness: Double
    
    func path(in rect: CGRect) -> Path {
        guard corners >= 2 else { return Path() }
        
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * smoothness
        
        var path = Path()
        let angleIncrement = .pi * 2 / Double(corners * 2)
        
        for i in 0..<corners * 2 {
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let angle = Double(i) * angleIncrement - .pi / 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Rarity Glow View

struct RarityGlowView: View {
    let rarity: AchievementRarity
    let size: CGFloat
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.5
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: rarity.gradientColors.map { $0.opacity(0.3) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size * 1.3, height: size * 1.3)
                .scaleEffect(pulseScale)
                .opacity(glowOpacity)
            
            // Rotating gradient ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: rarity.gradientColors + [rarity.gradientColors.first ?? .clear],
                        center: .center
                    ),
                    lineWidth: 4
                )
                .frame(width: size * 1.15, height: size * 1.15)
                .rotationEffect(.degrees(rotation))
                .opacity(0.6)
            
            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            rarity.color.opacity(0.4),
                            rarity.color.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size * 1.4, height: size * 1.4)
        }
        .onAppear {
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
                glowOpacity = 0.8
            }
            
            // Rotation animation (only for epic and legendary)
            if rarity == .epic || rarity == .legendary {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    /// Shimmer phase in \([-1, 1]\). Using a symmetric range makes the sweep feel centered
    /// and avoids “drifting” impressions on different device sizes.
    @State private var phase: CGFloat = -1
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            // Important: Keep the shimmer strictly within the view’s bounds so the sweep
            // never looks visually offset from the badge/icon on any screen size.
            .overlay {
                if isActive {
                    GeometryReader { geometry in
                        let w = geometry.size.width
                        let h = geometry.size.height
                        let bandWidth = w * 0.55
                        
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.75), // Increased from 0.35 to 0.75 for more visible shimmer
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: bandWidth, height: h)
                        // Slight angle reads more like “shimmer” and less like a hard bar.
                        .rotationEffect(.degrees(18))
                        // Sweep fully across, symmetric around center.
                        .offset(x: phase * (w + bandWidth))
                        .blendMode(.screen)
                    }
                    // Mask to the exact rendered content and clip to bounds to prevent any
                    // halo/band showing outside the badge (which can look like misalignment).
                    .mask(content.compositingGroup())
                    .clipped()
                }
            }
            .onAppear {
                if isActive {
                    withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
    }
}

extension View {
    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerEffect(isActive: isActive))
    }
}

// MARK: - Badge Ring

struct BadgeRing: View {
    let rarity: AchievementRarity
    let size: CGFloat
    let isUnlocked: Bool
    
    @State private var rotation: Double = 0
    @State private var innerRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Outer decorative ring
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: isUnlocked ? rarity.gradientColors : [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                        center: .center
                    ),
                    lineWidth: 4
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
            
            // Inner ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: isUnlocked ? [rarity.color.opacity(0.6), rarity.color] : [Color.gray.opacity(0.2), Color.gray.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size * 0.9, height: size * 0.9)
                .rotationEffect(.degrees(-innerRotation))
            
            // Background fill
            Circle()
                .fill(
                    LinearGradient(
                        colors: isUnlocked ? rarity.gradientColors.map { $0.opacity(0.2) } : [Color.gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.85, height: size * 0.85)
        }
        .onAppear {
            if isUnlocked && (rarity == .epic || rarity == .legendary) {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                    innerRotation = 360
                }
            }
        }
    }
}

// MARK: - Pulse Ring

struct PulseRing: View {
    let color: Color
    let size: CGFloat
    
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.8
    
    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    scale = 2.0
                    opacity = 0
                }
            }
    }
}

// MARK: - Achievement Symbol View

struct AchievementSymbolView: View {
    let symbolName: String
    let symbolStyle: SymbolRenderingMode
    let paletteColors: [Color]?
    let rarity: AchievementRarity
    let isUnlocked: Bool
    let size: CGFloat
    
    @State private var symbolScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Badge ring
            BadgeRing(rarity: rarity, size: size, isUnlocked: isUnlocked)
            
            // Symbol - centered properly within the badge
            // Use consistent color for all icons (rarity color when unlocked, gray when locked)
            Image(systemName: symbolName)
                .font(.system(size: size * 0.4, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(isUnlocked ? rarity.color : Color.gray.opacity(0.5))
                .scaleEffect(symbolScale)
        }
        .frame(width: size, height: size) // Ensure consistent frame for alignment
        .onAppear {
            if isUnlocked {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    symbolScale = 1.05
                }
            }
        }
    }
}

// MARK: - Celebration Burst

struct CelebrationBurst: View {
    let rarity: AchievementRarity
    
    @State private var showSparkles = false
    @State private var showConfetti = false
    @State private var showPulse = false
    
    var body: some View {
        ZStack {
            // Pulse rings (all rarities)
            if showPulse {
                ForEach(0..<3, id: \.self) { index in
                    PulseRing(color: rarity.color, size: 100)
                        .opacity(Double(3 - index) / 3)
                        .animation(.easeOut(duration: 1.5).delay(Double(index) * 0.3), value: showPulse)
                }
            }
            
            // Sparkles (rare and above)
            if showSparkles && rarity != .common {
                SparklesView(sparkleCount: rarity == .legendary ? 30 : 20)
            }
            
            // Confetti (epic and legendary)
            if showConfetti && (rarity == .epic || rarity == .legendary) {
                AchievementConfettiView(
                    particleCount: rarity == .legendary ? 60 : 40,
                    colors: rarity.gradientColors
                )
            }
        }
        .onAppear {
            showPulse = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showSparkles = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Floating Stars (for legendary)

struct FloatingStars: View {
    let count: Int
    
    @State private var stars: [FloatingStar] = []
    
    var body: some View {
        ZStack {
            ForEach(stars) { star in
                FloatingStarView(star: star)
            }
        }
        .onAppear {
            generateStars()
        }
    }
    
    private func generateStars() {
        stars = (0..<count).map { index in
            FloatingStar(
                x: CGFloat.random(in: -120...120),
                y: CGFloat.random(in: -120...120),
                size: CGFloat.random(in: 8...16),
                delay: Double(index) * 0.15
            )
        }
    }
}

struct FloatingStar: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let delay: Double
}

struct FloatingStarView: View {
    let star: FloatingStar
    
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: star.size))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 1.0, green: 0.6, blue: 0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .offset(x: star.x, y: star.y + offsetY)
            .onAppear {
                // Pop in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(star.delay)) {
                    scale = 1.0
                    opacity = 1.0
                }
                
                // Float up and fade
                withAnimation(.easeOut(duration: 2.0).delay(star.delay + 0.5)) {
                    offsetY = -50
                    opacity = 0
                }
                
                // Rotate
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false).delay(star.delay)) {
                    rotation = 360
                }
            }
    }
}
