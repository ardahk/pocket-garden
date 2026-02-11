//
//  LoadingAnimation.swift
//  pocket-garden
//
//  Beautiful Loading Animations
//

import SwiftUI
internal import Combine

// MARK: - Growing Plant Loader

struct GrowingPlantLoader: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                // Pot
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondaryTerracotta.opacity(0.3))
                    .frame(width: 60, height: 40)
                    .offset(y: 20)

                // Plant stem
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.primaryGreen.opacity(0.6), Color.primaryGreen],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 6, height: isAnimating ? 50 : 20)
                    .offset(y: isAnimating ? -10 : 10)

                // Leaves
                ForEach(0..<3) { index in
                    LeafShape()
                        .fill(Color.primaryGreen)
                        .frame(width: 20, height: 30)
                        .rotationEffect(.degrees(Double(index) * 30 - 30))
                        .offset(y: -20)
                        .scaleEffect(isAnimating ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.6)
                            .delay(Double(index) * 0.1),
                            value: isAnimating
                        )
                }
            }
            .frame(height: 100)

            Text("Growing...")
                .font(Typography.callout)
                .foregroundColor(.textSecondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Pulsing Dots Loader

struct PulsingDotsLoader: View {
    @State private var activeDot: Int = 0
    
    let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.primaryGreen)
                    .frame(width: 12, height: 12)
                    .scaleEffect(activeDot == index ? 1.2 : 0.6)
                    .opacity(activeDot == index ? 1.0 : 0.35)
                    .animation(.easeInOut(duration: 0.3), value: activeDot)
            }
        }
        .onReceive(timer) { _ in
            activeDot = (activeDot + 1) % 3
        }
    }
}

// MARK: - Bouncing Dots View (Honey-themed)

struct BouncingDotsView: View {
    @State private var activeDot: Int = 0
    
    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentGold, Color.accentGold.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 12, height: 12)
                    .scaleEffect(activeDot == index ? 1.4 : 0.7)
                    .offset(y: activeDot == index ? -6 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: activeDot)
            }
        }
        .onReceive(timer) { _ in
            activeDot = (activeDot + 1) % 3
        }
    }
}

// MARK: - Thinking Indicator (Bumblebee feedback generation)

struct ThinkingIndicatorView: View {
    @State private var activeDot: Int = 0
    @State private var messageIndex: Int = 0
    @State private var messageOpacity: Double = 1.0
    
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    private let messages = [
        "Reflecting on your words...",
        "Thinking of something thoughtful...",
        "Buzzing through my thoughts...",
        "Finding the right words for you...",
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Animated message
            HStack(spacing: 6) {
                Text("🐝")
                    .font(.system(size: 14))
                
                Text(messages[messageIndex])
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .opacity(messageOpacity)
            }
            
            // Honey-colored bouncing dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentGold, Color.accentGold.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 10, height: 10)
                        .scaleEffect(activeDot == index ? 1.3 : 0.6)
                        .offset(y: activeDot == index ? -4 : 0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: activeDot)
                }
            }
        }
        .onReceive(timer) { _ in
            activeDot = (activeDot + 1) % 3
        }
        .onAppear {
            cycleMessage()
        }
    }
    
    private func cycleMessage() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.2)) { messageOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                messageIndex = (messageIndex + 1) % messages.count
                withAnimation(.easeIn(duration: 0.2)) { messageOpacity = 1.0 }
                cycleMessage()
            }
        }
    }
}

// MARK: - Spinning Leaf Loader

struct SpinningLeafLoader: View {
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 40))
            .foregroundColor(.primaryGreen)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Leaf Shape

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: 0))

        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control: CGPoint(x: width, y: height * 0.5)
        )

        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control: CGPoint(x: 0, y: height * 0.5)
        )

        return path
    }
}

// MARK: - Preview

#Preview("Loaders") {
    VStack(spacing: Spacing.xxxl) {
        GrowingPlantLoader()

        PulsingDotsLoader()

        SpinningLeafLoader()
    }
    .padding()
    .background(Color.backgroundCream)
}
