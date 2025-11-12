//
//  TranscriptionLoadingView.swift
//  pocket-garden
//
//  Sophisticated loading animation for transcription processing
//

import SwiftUI

struct TranscriptionLoadingView: View {
    @State private var isAnimating = false
    @State private var dotOpacity: [Double] = [0.3, 0.3, 0.3]
    @State private var wavePhase: CGFloat = 0

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Animated waveform
            ZStack {
                // Glow effect
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
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0.6 : 0.3)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                // Circular audio waves
                ZStack {
                    ForEach(0..<8, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color.primaryGreen, Color.accentGold],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 4, height: barHeight(for: index))
                            .offset(y: -30)
                            .rotationEffect(.degrees(Double(index) * 45))
                    }
                }
                .rotationEffect(.degrees(wavePhase))
                .frame(width: 100, height: 100)
            }

            // Status text with animated dots
            HStack(spacing: 4) {
                Text("Transcribing")
                    .font(Typography.body)
                    .foregroundColor(.textPrimary)

                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.primaryGreen)
                            .frame(width: 6, height: 6)
                            .opacity(dotOpacity[index])
                    }
                }
            }

            // Helper text
            Text("Converting your voice to text...")
                .font(Typography.callout)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Spacing.xxxl)
        .frame(maxWidth: .infinity)
        .onAppear {
            startAnimations()
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 15
        let variation = sin(wavePhase / 20 + Double(index) * 0.5) * 15
        return baseHeight + variation
    }

    private func startAnimations() {
        isAnimating = true

        // Dot animation
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.3)) {
                // Rotate dot opacities
                let first = dotOpacity.removeFirst()
                dotOpacity.append(first)
                dotOpacity = dotOpacity.map { $0 == 0.3 ? 1.0 : 0.3 }
            }
        }

        // Wave rotation
        withAnimation(
            .linear(duration: 8)
                .repeatForever(autoreverses: false)
        ) {
            wavePhase = 360
        }
    }
}

// MARK: - Microphone Permission Loading

struct PermissionLoadingView: View {
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                // Pulsing background
                Circle()
                    .fill(Color.primaryGreen.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(scale)

                // Microphone icon
                Image(systemName: "mic.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.primaryGreen)
                    .rotationEffect(.degrees(rotation))
            }

            Text("Requesting Permission...")
                .font(Typography.callout)
                .foregroundColor(.textSecondary)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
            ) {
                scale = 1.3
            }

            withAnimation(
                .linear(duration: 2.0)
                    .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
}

// MARK: - Saving Entry Loading

struct SavingEntryLoadingView: View {
    @State private var offset: CGFloat = -100
    @State private var leafRotation: Double = 0

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                // Growing plant animation
                VStack(spacing: 0) {
                    // Leaf
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.primaryGreen)
                        .rotationEffect(.degrees(leafRotation))
                        .offset(y: offset)

                    // Stem
                    Rectangle()
                        .fill(Color.primaryGreen.opacity(0.6))
                        .frame(width: 3, height: max(0, 50 + offset))
                }

                // Sparkles
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundColor(.accentGold)
                        .offset(
                            x: cos(Double(index) * 0.4) * 40,
                            y: sin(Double(index) * 0.4) * 40 + offset / 2
                        )
                        .opacity(max(0, 1 - abs(offset) / 100))
                }
            }
            .frame(height: 100)

            VStack(spacing: Spacing.xs) {
                Text("Planting Your Tree")
                    .font(Typography.headline)
                    .foregroundColor(.textPrimary)

                Text("Generating AI feedback...")
                    .font(Typography.callout)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, Spacing.xxxl)
        .onAppear {
            withAnimation(
                .spring(response: 1.5, dampingFraction: 0.6)
            ) {
                offset = 0
                leafRotation = 360
            }
        }
    }
}

// MARK: - Previews

#Preview("Transcription Loading") {
    TranscriptionLoadingView()
        .padding()
        .background(Color.backgroundCream)
}

#Preview("Permission Loading") {
    PermissionLoadingView()
        .padding()
        .background(Color.backgroundCream)
}

#Preview("Saving Entry Loading") {
    SavingEntryLoadingView()
        .padding()
        .background(Color.backgroundCream)
}
