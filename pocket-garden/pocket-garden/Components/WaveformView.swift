//
//  WaveformView.swift
//  pocket-garden
//
//  Animated Waveform Visualization
//

import SwiftUI

struct WaveformView: View {
    @State private var phases: [CGFloat] = Array(repeating: 0, count: 5)
    @State private var isAnimating = false

    let barCount = 5
    let barColor: Color
    let animated: Bool

    init(barColor: Color = .primaryGreen, animated: Bool = true) {
        self.barColor = barColor
        self.animated = animated
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [barColor, barColor.opacity(0.6)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 6, height: barHeight(for: index))
                    .animation(
                        animated ? .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1) : .default,
                        value: isAnimating
                    )
            }
        }
        .frame(height: 60)
        .onAppear {
            if animated {
                isAnimating = true
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeights: [CGFloat] = [20, 35, 50, 35, 20]

        if !animated || !isAnimating {
            return baseHeights[index % baseHeights.count]
        }

        // Animated heights
        let animatedHeights: [CGFloat] = [40, 55, 60, 45, 30]
        return animatedHeights[index % animatedHeights.count]
    }
}

// MARK: - Audio Level Waveform

struct AudioLevelWaveform: View {
    let audioLevel: CGFloat // 0.0 to 1.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [.primaryGreen, .accentGold],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: barHeight(for: index))
            }
        }
        .frame(height: 40)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let normalizedIndex = CGFloat(index) / 20.0
        let waveValue = sin(normalizedIndex * .pi * 2 + audioLevel * 10)
        return max(4, (waveValue + 1) * 15 * audioLevel)
    }
}

// MARK: - Circular Waveform

struct CircularWaveform: View {
    @State private var isAnimating = false

    let isRecording: Bool

    var body: some View {
        ZStack {
            // Outer pulse rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        Color.primaryGreen.opacity(0.3),
                        lineWidth: 2
                    )
                    .scaleEffect(isAnimating ? 1.5 + (CGFloat(index) * 0.3) : 1.0)
                    .opacity(isAnimating ? 0 : 0.6)
                    .animation(
                        .easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.3),
                        value: isAnimating
                    )
            }

            // Center circle with waveform
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.primaryGreen.opacity(0.3),
                            Color.primaryGreen.opacity(0.1)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    WaveformView(barColor: .primaryGreen, animated: isRecording)
                )
        }
        .frame(width: 200, height: 200)
        .onAppear {
            isAnimating = isRecording
        }
        .onChange(of: isRecording) { _, newValue in
            isAnimating = newValue
        }
    }
}

// MARK: - Previews

#Preview("Basic Waveform") {
    VStack(spacing: Spacing.xl) {
        WaveformView()

        WaveformView(barColor: .accentGold)

        WaveformView(animated: false)
    }
    .padding()
    .background(Color.backgroundCream)
}

#Preview("Audio Level Waveform") {
    struct AudioLevelDemo: View {
        @State private var audioLevel: CGFloat = 0.5

        var body: some View {
            VStack(spacing: Spacing.xl) {
                AudioLevelWaveform(audioLevel: audioLevel)

                Slider(value: $audioLevel, in: 0...1)
                    .padding()

                Text("Audio Level: \(audioLevel, specifier: "%.2f")")
                    .font(Typography.caption)
            }
            .padding()
            .background(Color.backgroundCream)
        }
    }

    return AudioLevelDemo()
}

#Preview("Circular Waveform") {
    VStack(spacing: Spacing.xxxl) {
        CircularWaveform(isRecording: true)

        CircularWaveform(isRecording: false)
    }
    .padding()
    .background(Color.backgroundCream)
}
