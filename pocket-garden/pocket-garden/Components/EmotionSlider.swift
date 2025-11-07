//
//  EmotionSlider.swift
//  pocket-garden
//
//  Beautiful Emotion Rating Slider (1-10)
//

import SwiftUI

struct EmotionSlider: View {
    @Binding var rating: Int
    @State private var isDragging = false
    @State private var emojiScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Emoji Feedback
            emojiDisplay

            // Custom Slider
            sliderView

            // Rating Labels
            ratingLabels

            // Emotion Label
            emotionLabelView
        }
        .onChange(of: rating) { _, _ in
            withAnimation(Theme.Animation.bouncySpring) {
                emojiScale = 1.2
            }
            Theme.Haptics.selection()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(Theme.Animation.spring) {
                    emojiScale = 1.0
                }
            }
        }
    }

    // MARK: - Emoji Display

    private var emojiDisplay: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.emotionColor(for: rating).opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 20)

            // Emoji
            Text(Theme.emoji(for: rating))
                .font(.system(size: 80))
                .scaleEffect(emojiScale)
        }
        .frame(height: 120)
    }

    // MARK: - Slider

    private var sliderView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color.borderColor)
                    .frame(height: 8)

                // Progress gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: progressWidth(in: geometry.size.width), height: 8)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.emotionColor(for: rating).opacity(0.5), radius: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.emotionColor(for: rating), lineWidth: 3)
                    )
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .offset(x: thumbOffset(in: geometry.size.width))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                if !isDragging {
                                    isDragging = true
                                    Theme.Haptics.light()
                                }
                                updateRating(from: gesture, in: geometry.size.width)
                            }
                            .onEnded { _ in
                                isDragging = false
                                Theme.Haptics.medium()
                            }
                    )
            }
        }
        .frame(height: 44)
    }

    // MARK: - Rating Labels

    private var ratingLabels: some View {
        HStack {
            ForEach(1...10, id: \.self) { number in
                Text("\(number)")
                    .font(Typography.caption)
                    .foregroundColor(rating == number ? Color.emotionColor(for: rating) : .textSecondary)
                    .fontWeight(rating == number ? .bold : .regular)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Emotion Label

    private var emotionLabelView: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(Color.emotionColor(for: rating))
                .frame(width: 12, height: 12)

            Text(Theme.emotionLabel(for: rating))
                .font(Typography.title3)
                .foregroundColor(.textPrimary)
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.lg)
        .background(
            Capsule()
                .fill(Color.emotionColor(for: rating).opacity(0.1))
        )
    }

    // MARK: - Helper Methods

    private var gradientColors: [Color] {
        [
            Color.emotionSad,
            Color.emotionMelancholy,
            Color.emotionNeutral,
            Color.emotionContent,
            Color.emotionJoy
        ]
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        let normalizedValue = CGFloat(rating - 1) / 9.0
        return totalWidth * normalizedValue
    }

    private func thumbOffset(in totalWidth: CGFloat) -> CGFloat {
        let normalizedValue = CGFloat(rating - 1) / 9.0
        return (totalWidth - 32) * normalizedValue
    }

    private func updateRating(from gesture: DragGesture.Value, in width: CGFloat) {
        let normalizedValue = max(0, min(1, gesture.location.x / width))
        let newRating = Int(normalizedValue * 9) + 1
        if newRating != rating {
            rating = max(1, min(10, newRating))
        }
    }
}

// MARK: - Preview

#Preview("Emotion Slider") {
    struct EmotionSliderPreview: View {
        @State private var rating = 7

        var body: some View {
            VStack(spacing: Spacing.xxxl) {
                Text("How are you feeling today?")
                    .font(Typography.title)
                    .foregroundColor(.textPrimary)

                EmotionSlider(rating: $rating)
                    .padding(.horizontal, Spacing.lg)

                Text("Current Rating: \(rating)")
                    .font(Typography.callout)
                    .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.backgroundCream)
        }
    }

    return EmotionSliderPreview()
}
