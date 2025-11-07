//
//  CustomShapes.swift
//  pocket-garden
//
//  Custom Shapes for Organic Design
//

import SwiftUI

// MARK: - Blob Shape

struct BlobShape: Shape {
    var randomSeed: Int = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let points = 8
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<points {
            let angle = (CGFloat(i) / CGFloat(points)) * 2 * .pi
            let randomOffset = CGFloat.random(in: 0.7...1.0)

            let x = center.x + cos(angle) * radius * randomOffset
            let y = center.y + sin(angle) * radius * randomOffset

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                let previousAngle = (CGFloat(i - 1) / CGFloat(points)) * 2 * .pi
                let previousX = center.x + cos(previousAngle) * radius * 0.85
                let previousY = center.y + sin(previousAngle) * radius * 0.85

                path.addQuadCurve(
                    to: CGPoint(x: x, y: y),
                    control: CGPoint(x: previousX, y: previousY)
                )
            }
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Cloud Shape

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Main cloud body
        path.addEllipse(in: CGRect(x: width * 0.1, y: height * 0.4, width: width * 0.4, height: height * 0.4))
        path.addEllipse(in: CGRect(x: width * 0.3, y: height * 0.2, width: width * 0.5, height: height * 0.5))
        path.addEllipse(in: CGRect(x: width * 0.5, y: height * 0.3, width: width * 0.4, height: height * 0.4))

        return path
    }
}

// MARK: - Mountain Shape

struct MountainShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.4))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.3))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

// MARK: - Wave Shape

struct WaveShape: Shape {
    var amplitude: CGFloat = 10
    var frequency: CGFloat = 1

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.midY))

        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin(relativeX * .pi * 2 * frequency)
            let y = rect.midY + sine * amplitude

            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}

// MARK: - Flower Petal Shape

struct FlowerPetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: height))

        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control: CGPoint(x: width, y: height * 0.5)
        )

        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control: CGPoint(x: 0, y: height * 0.5)
        )

        return path
    }
}

// MARK: - Flower View

struct FlowerView: View {
    let petalCount: Int
    let color: Color
    var size: CGFloat = 50

    var body: some View {
        ZStack {
            // Petals
            ForEach(0..<petalCount, id: \.self) { index in
                FlowerPetalShape()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.4, height: size * 0.6)
                    .rotationEffect(.degrees(Double(index) * (360.0 / Double(petalCount))))
            }

            // Center
            Circle()
                .fill(Color.accentGold)
                .frame(width: size * 0.3, height: size * 0.3)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Grass Blade Shape

struct GrassBladeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: height))

        path.addQuadCurve(
            to: CGPoint(x: width * 0.4, y: 0),
            control: CGPoint(x: width * 0.3, y: height * 0.5)
        )

        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control: CGPoint(x: width * 0.5, y: height * 0.3)
        )

        return path
    }
}

// MARK: - Preview

#Preview("Custom Shapes") {
    ScrollView {
        VStack(spacing: Spacing.xl) {
            // Blob
            BlobShape()
                .fill(Color.primaryGreen.opacity(0.3))
                .frame(width: 100, height: 100)

            // Cloud
            CloudShape()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 150, height: 80)

            // Mountain
            MountainShape()
                .fill(
                    LinearGradient(
                        colors: [Color.gray, Color.gray.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 200, height: 100)

            // Wave
            WaveShape(amplitude: 20, frequency: 3)
                .stroke(Color.primaryGreen, lineWidth: 3)
                .frame(width: 200, height: 60)

            // Flower
            FlowerView(petalCount: 5, color: .emotionJoy, size: 80)

            FlowerView(petalCount: 6, color: .emotionContent, size: 60)

            // Grass
            HStack(spacing: 4) {
                ForEach(0..<10) { _ in
                    GrassBladeShape()
                        .fill(Color.primaryGreen)
                        .frame(width: 8, height: 40)
                }
            }
        }
        .padding()
        .background(Color.backgroundCream)
    }
}
