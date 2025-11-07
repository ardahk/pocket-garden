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

    @State private var cloudOffset1: CGFloat = 0
    @State private var cloudOffset2: CGFloat = 100

    var body: some View {
        ZStack {
            // Sky gradient
            skyGradient

            // Clouds
            if weather != .sunny {
                cloudsLayer
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
        }
    }

    // MARK: - Sky Gradient

    private var skyGradient: some View {
        LinearGradient(
            colors: weather.skyGradient,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Clouds Layer

    private var cloudsLayer: some View {
        ZStack {
            // Cloud 1
            CloudShape()
                .fill(Color.white.opacity(cloudOpacity))
                .frame(width: 120, height: 50)
                .offset(x: cloudOffset1, y: 60)
                .offset(x: scrollOffset * 0.1)

            // Cloud 2
            CloudShape()
                .fill(Color.white.opacity(cloudOpacity))
                .frame(width: 140, height: 60)
                .offset(x: cloudOffset2, y: 120)
                .offset(x: scrollOffset * 0.15)

            // Cloud 3
            CloudShape()
                .fill(Color.white.opacity(cloudOpacity))
                .frame(width: 100, height: 45)
                .offset(x: cloudOffset1 + 200, y: 90)
                .offset(x: scrollOffset * 0.12)
        }
    }

    private var cloudOpacity: Double {
        switch weather {
        case .sunny: return 0.0
        case .partlyCloudy: return 0.4
        case .cloudy: return 0.6
        case .rainy: return 0.7
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
                // Back hill
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryGreen.opacity(0.3),
                                Color.primaryGreen.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geometry.size.width * 1.5, height: 200)
                    .offset(x: scrollOffset * 0.15, y: geometry.size.height * 0.6)

                // Front hill
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryGreen.opacity(0.4),
                                Color.primaryGreen.opacity(0.3)
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
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            cloudOffset1 = 400
        }

        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            cloudOffset2 = 450
        }
    }
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
