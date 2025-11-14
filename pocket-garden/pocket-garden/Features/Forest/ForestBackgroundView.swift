//
//  ForestBackgroundView.swift
//  pocket-garden
//
//  Parallax Forest Background with Weather
//

import SwiftUI

struct ForestBackgroundView: View {
    let weather: ForestWeather
    let scrollOffset: CGFloat
    
    @Environment(\.colorScheme) private var colorScheme

    @State private var cloudOffset1: CGFloat = -450
    @State private var cloudOffset2: CGFloat = -500
    @State private var stars: [Star] = []
    
    private var isNightMode: Bool {
        colorScheme == .dark
    }

    var body: some View {
        ZStack {
            // Sky gradient
            skyGradient
            
            // Stars (only in dark mode)
            if isNightMode {
                starsLayer
            }

            // Clouds (only in day mode, behind everything)
            if !isNightMode {
                cloudsLayer
            }
            
            // Sun in day mode, moon in night mode
            if isNightMode {
                moonLayer
            } else {
                sunLayer
            }

            // Mountains (back layer)
            mountainsLayer

            // Hills (middle layer)
            hillsLayer

            // Grass (front layer)
            grassLayer
        }
        .ignoresSafeArea()
        .onAppear {
            animateClouds()
            if isNightMode {
                generateStars()
            }
        }
        .onChange(of: colorScheme) { _, newScheme in
            if newScheme == .dark {
                generateStars()
            } else {
                stars = []
            }
        }
    }

    // MARK: - Sky Gradient

    private var skyGradient: some View {
        LinearGradient(
            colors: isNightMode ? nightSkyGradient : weather.skyGradient,
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var nightSkyGradient: [Color] {
        [
            Color(hex: "1a1a2e"),  // Deep night blue
            Color(hex: "16213e"),  // Darker blue
            Color(hex: "0f3460")   // Deep blue at horizon
        ]
    }
    
    // MARK: - Stars Layer
    
    private var starsLayer: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white.opacity(star.opacity))
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x * geometry.size.width, y: star.y * geometry.size.height)
                        .blur(radius: star.blur)
                }
            }
        }
    }
    
    // MARK: - Sun Layer
    
    private var sunLayer: some View {
        GeometryReader { geometry in
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "FDB813"),  // Bright yellow
                            Color(hex: "FDCB6E")   // Softer yellow
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .position(
                    x: geometry.size.width * 0.8,
                    y: geometry.size.height * 0.15
                )
                .shadow(color: Color(hex: "FDB813").opacity(0.4), radius: 25)
                .offset(x: scrollOffset * 0.05)
        }
    }
    
    // MARK: - Moon Layer
    
    private var moonLayer: some View {
        GeometryReader { geometry in
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "F4F1DE"),
                            Color(hex: "E8E4D0")
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .position(
                    x: geometry.size.width * 0.8,
                    y: geometry.size.height * 0.15
                )
                .shadow(color: Color(hex: "F4F1DE").opacity(0.3), radius: 20)
                .offset(x: scrollOffset * 0.05)
        }
    }

    // MARK: - Clouds Layer

    private var cloudsLayer: some View {
        ZStack {
            // Cloud 1 - small and cute (upper left)
            CloudShape()
                .fill(Color.white.opacity(0.6))
                .frame(width: 140, height: 60)
                .offset(x: cloudOffset1, y: -140)
                .offset(x: scrollOffset * 0.08)

            // Cloud 2 - medium (upper middle)
            CloudShape()
                .fill(Color.white.opacity(0.5))
                .frame(width: 160, height: 70)
                .offset(x: cloudOffset2, y: -80)
                .offset(x: scrollOffset * 0.05)

            // Cloud 3 - small (upper right)
            CloudShape()
                .fill(Color.white.opacity(0.55))
                .frame(width: 130, height: 62)
                .offset(x: cloudOffset1 + 200, y: -110)
                .offset(x: scrollOffset * 0.02)
                
            // Cloud 4 - tiny and far (top)
            CloudShape()
                .fill(Color.white.opacity(0.4))
                .frame(width: 110, height: 52)
                .offset(x: cloudOffset2 - 120, y: -170)
                .offset(x: scrollOffset * 0.03)
        }
    }

    // MARK: - Mountains Layer

    private var mountainsLayer: some View {
        GeometryReader { geometry in
            ZStack {
                // Back mountains
                MountainShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: geometry.size.height * 0.4)
                    .offset(x: scrollOffset * 0.05, y: geometry.size.height * 0.3)

                // Front mountains
                MountainShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.4),
                                Color.gray.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: geometry.size.height * 0.35)
                    .offset(x: scrollOffset * 0.08, y: geometry.size.height * 0.4)
            }
        }
    }

    // MARK: - Hills Layer

    private var hillsLayer: some View {
        GeometryReader { geometry in
            ZStack {
                // Back hill - more subtle at night
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryGreen.opacity(isNightMode ? 0.15 : 0.3),
                                Color.primaryGreen.opacity(isNightMode ? 0.1 : 0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geometry.size.width * 1.5, height: 200)
                    .offset(x: scrollOffset * 0.15, y: geometry.size.height * 0.6)

                // Front hill - more subtle at night
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryGreen.opacity(isNightMode ? 0.2 : 0.4),
                                Color.primaryGreen.opacity(isNightMode ? 0.15 : 0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geometry.size.width * 1.2, height: 180)
                    .offset(x: scrollOffset * 0.2, y: geometry.size.height * 0.7)
            }
        }
    }

    // MARK: - Grass Layer

    private var grassLayer: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                // Grass ground
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryGreen.opacity(0.6),
                                Color.primaryGreen.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 120)
                    .overlay(
                        // Grass blades
                        HStack(spacing: 20) {
                            ForEach(0..<50, id: \.self) { index in
                                GrassBladeShape()
                                    .fill(
                                        Color.primaryGreen.opacity(
                                            Double.random(in: 0.4...0.8)
                                        )
                                    )
                                    .frame(
                                        width: CGFloat.random(in: 4...8),
                                        height: CGFloat.random(in: 20...40)
                                    )
                                    .offset(
                                        x: CGFloat(index) * 20,
                                        y: CGFloat.random(in: -5...5)
                                    )
                            }
                        }
                        .offset(x: scrollOffset * 0.3)
                        ,
                        alignment: .bottom
                    )
            }
        }
    }

    // MARK: - Animations

    private func animateClouds() {
        // Slower, more gentle cloud movement
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            cloudOffset1 = 500
        }

        withAnimation(.linear(duration: 50).repeatForever(autoreverses: false)) {
            cloudOffset2 = 500
        }
    }
    
    private func generateStars() {
        var newStars: [Star] = []
        
        // Generate 50-80 stars with random positions and properties
        let starCount = Int.random(in: 50...80)
        
        for _ in 0..<starCount {
            let star = Star(
                id: UUID(),
                x: Double.random(in: 0...1),
                y: Double.random(in: 0...0.4), // Only in upper 40% of sky (above mountains)
                size: CGFloat.random(in: 1...3),
                opacity: 0, // Start invisible
                blur: Double.random(in: 0...0.5),
                delay: Double.random(in: 0...3) // Random delay for appearing
            )
            newStars.append(star)
        }
        
        stars = newStars
        
        // Animate stars appearing slowly with random delays
        for (index, star) in stars.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + star.delay) {
                withAnimation(.easeIn(duration: Double.random(in: 2...4))) {
                    if index < stars.count {
                        stars[index].opacity = Double.random(in: 0.3...0.9)
                    }
                }
                
                // Make stars twinkle
                animateStarTwinkle(at: index)
            }
        }
    }
    
    private func animateStarTwinkle(at index: Int) {
        guard index < stars.count else { return }
        
        let duration = Double.random(in: 2...4)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard index < stars.count else { return }
            
            withAnimation(.easeInOut(duration: duration)) {
                stars[index].opacity = Double.random(in: 0.2...0.9)
            }
            
            // Continue twinkling
            animateStarTwinkle(at: index)
        }
    }
}

// MARK: - Star Model

struct Star: Identifiable {
    let id: UUID
    let x: Double
    let y: Double
    let size: CGFloat
    var opacity: Double
    let blur: Double
    let delay: Double
}

// MARK: - Preview

#Preview("Sunny Weather") {
    ForestBackgroundView(weather: .sunny, scrollOffset: 0)
}

#Preview("Cloudy Weather") {
    ForestBackgroundView(weather: .cloudy, scrollOffset: 0)
}

#Preview("Rainy Weather") {
    ForestBackgroundView(weather: .rainy, scrollOffset: 0)
}

#Preview("With Parallax") {
    struct ParallaxDemo: View {
        @State private var offset: CGFloat = 0

        var body: some View {
            ZStack {
                ForestBackgroundView(weather: .partlyCloudy, scrollOffset: offset)

                VStack {
                    Spacer()

                    Slider(value: $offset, in: -200...200)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
    }

    return ParallaxDemo()
}
