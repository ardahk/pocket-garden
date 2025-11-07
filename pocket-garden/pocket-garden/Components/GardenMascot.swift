//
//  GardenMascot.swift
//  pocket-garden
//
//  Cute Mascot Character (like Duolingo's Duo)
//

import SwiftUI

// MARK: - Mascot Character

struct GardenMascot: View {
    let emotion: MascotEmotion
    let size: CGFloat

    @State private var isAnimating = false
    @State private var bounce = false

    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.primaryGreen.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.8
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0.3 : 0.6)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)

            // Body
            mascotBody
                .frame(width: size, height: size)
                .scaleEffect(bounce ? 1.05 : 1.0)
                .offset(y: bounce ? -5 : 0)
        }
        .onAppear {
            isAnimating = true
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                bounce = true
            }
        }
    }

    private var mascotBody: some View {
        ZStack {
            // Main body (cute sprout character)
            VStack(spacing: 0) {
                // Leaves (head)
                HStack(spacing: -8) {
                    LeafShape()
                        .fill(Color.primaryGreen)
                        .frame(width: size * 0.35, height: size * 0.45)
                        .rotationEffect(.degrees(-25))

                    LeafShape()
                        .fill(Color.primaryGreen.opacity(0.9))
                        .frame(width: size * 0.35, height: size * 0.45)
                        .rotationEffect(.degrees(25))
                }
                .offset(y: size * 0.05)

                // Face
                ZStack {
                    // Face circle
                    Circle()
                        .fill(Color.backgroundCream)
                        .frame(width: size * 0.5, height: size * 0.5)
                        .overlay(
                            Circle()
                                .stroke(Color.primaryGreen, lineWidth: 3)
                        )

                    // Eyes
                    HStack(spacing: size * 0.15) {
                        ForEach(0..<2) { _ in
                            mascotEye
                        }
                    }

                    // Mouth
                    mascotMouth
                        .offset(y: size * 0.1)
                }
                .offset(y: -size * 0.05)
            }
        }
    }

    private var mascotEye: some View {
        ZStack {
            // Eye white
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.12, height: size * 0.12)

            // Pupil
            Circle()
                .fill(Color.textPrimary)
                .frame(width: size * 0.06, height: size * 0.06)
                .offset(x: 1, y: 1)

            // Shine
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.03, height: size * 0.03)
                .offset(x: -1, y: -1)
        }
    }

    private var mascotMouth: some View {
        Group {
            switch emotion {
            case .happy, .proud:
                // Big smile
                Path { path in
                    path.move(to: CGPoint(x: -size * 0.12, y: 0))
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.12, y: 0),
                        control: CGPoint(x: 0, y: size * 0.08)
                    )
                }
                .stroke(Color.textPrimary, lineWidth: 2)
                .frame(width: size * 0.24, height: size * 0.1)

            case .supportive:
                // Gentle smile
                Path { path in
                    path.move(to: CGPoint(x: -size * 0.1, y: 0))
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.1, y: 0),
                        control: CGPoint(x: 0, y: size * 0.05)
                    )
                }
                .stroke(Color.textPrimary, lineWidth: 2)
                .frame(width: size * 0.2, height: size * 0.08)

            case .concerned:
                // Empathetic expression
                Path { path in
                    path.move(to: CGPoint(x: -size * 0.1, y: size * 0.02))
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.1, y: size * 0.02),
                        control: CGPoint(x: 0, y: -size * 0.02)
                    )
                }
                .stroke(Color.textPrimary, lineWidth: 2)
                .frame(width: size * 0.2, height: size * 0.08)
            }
        }
    }
}

// MARK: - Mascot Emotion

enum MascotEmotion {
    case happy      // For positive entries (8-10)
    case supportive // For moderate entries (5-7)
    case concerned  // For low entries (1-4)
    case proud      // For achievements

    static func from(rating: Int) -> MascotEmotion {
        switch rating {
        case 8...10: return .happy
        case 5...7: return .supportive
        case 1...4: return .concerned
        default: return .supportive
        }
    }
}

// MARK: - Animated Feedback Screen

struct MascotFeedbackView: View {
    let entry: EmotionEntry
    let onDismiss: () -> Void

    @State private var mascotScale: CGFloat = 0
    @State private var feedbackOpacity: Double = 0
    @State private var speechBubbleScale: CGFloat = 0
    @State private var showSparkles = false

    private let mascotEmotion: MascotEmotion

    init(entry: EmotionEntry, onDismiss: @escaping () -> Void) {
        self.entry = entry
        self.onDismiss = onDismiss
        self.mascotEmotion = MascotEmotion.from(rating: entry.emotionRating)
    }

    var body: some View {
        ZStack {
            // Background
            Color.peacefulGradient
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Sparkles for high ratings
            if showSparkles && entry.emotionRating >= 8 {
                SparklesView(sparkleCount: 20)
            }

            VStack(spacing: Spacing.xxxl) {
                Spacer()

                // Mascot character
                GardenMascot(emotion: mascotEmotion, size: 140)
                    .scaleEffect(mascotScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                            mascotScale = 1.0
                        }

                        // Show sparkles for high ratings
                        if entry.emotionRating >= 8 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    showSparkles = true
                                }
                            }
                        }

                        // Show speech bubble after mascot appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                speechBubbleScale = 1.0
                            }
                            Theme.Haptics.light()
                        }

                        // Fade in text
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(.easeIn(duration: 0.5)) {
                                feedbackOpacity = 1.0
                            }
                        }
                    }

                // Speech bubble with feedback
                SpeechBubble {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(mascotGreeting)
                            .font(Typography.title3)
                            .foregroundColor(.textPrimary)

                        Text(entry.aiFeedback ?? "You're doing great!")
                            .font(Typography.body)
                            .foregroundColor(.textSecondary)
                    }
                }
                .scaleEffect(speechBubbleScale)
                .opacity(feedbackOpacity)

                Spacer()

                // Continue button
                PrimaryButton("Continue", icon: "arrow.right") {
                    dismiss()
                }
                .padding(.horizontal, Layout.screenPadding)
                .opacity(feedbackOpacity)
            }
            .padding(.vertical, Spacing.xl)
        }
    }

    private var mascotGreeting: String {
        switch mascotEmotion {
        case .happy:
            return "Amazing energy today! 🌟"
        case .supportive:
            return "I'm here with you! 💚"
        case .concerned:
            return "Sending you support! 🤗"
        case .proud:
            return "You're incredible! ✨"
        }
    }

    private func dismiss() {
        Theme.Haptics.medium()
        withAnimation {
            mascotScale = 0.8
            feedbackOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Speech Bubble

struct SpeechBubble<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Bubble tail
            Triangle()
                .fill(Color.white)
                .frame(width: 20, height: 15)
                .rotationEffect(.degrees(180))
                .offset(y: 1)

            // Bubble content
            content
                .padding(Spacing.xl)
                .background(Color.white)
                .cornerRadius(CornerRadius.lg)
                .cardShadow()
        }
        .padding(.horizontal, Layout.screenPadding)
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Previews

#Preview("Happy Mascot") {
    ZStack {
        Color.backgroundCream
            .ignoresSafeArea()

        GardenMascot(emotion: .happy, size: 140)
    }
}

#Preview("Feedback Screen") {
    MascotFeedbackView(
        entry: .sample(rating: 9, includeTranscription: true, includeFeedback: true)
    ) {
        print("Dismissed")
    }
}
