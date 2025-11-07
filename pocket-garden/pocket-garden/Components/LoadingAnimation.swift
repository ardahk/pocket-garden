//
//  LoadingAnimation.swift
//  pocket-garden
//
//  Beautiful Loading Animations
//

import SwiftUI

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
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.primaryGreen)
                    .frame(width: 12, height: 12)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
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
