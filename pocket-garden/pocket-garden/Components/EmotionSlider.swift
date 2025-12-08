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
            // Ambient background glow
            Circle()
                .fill(Color.emotionColor(for: rating).opacity(0.15))
                .frame(width: 200, height: 200)
                .blur(radius: 30)

            // Inner vibrant glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.emotionColor(for: rating).opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 180, height: 180)
                .blur(radius: 10)
                .scaleEffect(isDragging ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isDragging)

            // Emoji
            Text(Theme.emoji(for: rating))
                .font(.system(size: 90))
                .scaleEffect(emojiScale)
                .shadow(color: Color.emotionColor(for: rating).opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .frame(height: 140)
    }

    // MARK: - Slider

    private var sliderView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 12)

                // Progress gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: progressWidth(in: geometry.size.width), height: 12)

                // Thumb
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)

                    Circle()
                        .fill(Color.emotionColor(for: rating))
                        .frame(width: 20, height: 20)
                }
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
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: rating)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
            }
        }
        .frame(height: 44)
    }

    // MARK: - Rating Labels

    private var ratingLabels: some View {
        HStack {
            ForEach(1...10, id: \.self) { number in
                ZStack {
                    if rating == number {
                        Circle()
                            .fill(Color.emotionColor(for: rating).opacity(0.2))
                            .frame(width: 24, height: 24)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Text("\(number)")
                        .font(.system(size: 12, weight: rating == number ? .bold : .medium, design: .rounded))
                        .foregroundColor(rating == number ? Color.emotionColor(for: rating) : .textSecondary.opacity(0.6))
                        .scaleEffect(rating == number ? 1.2 : 1.0)
                }
                .frame(maxWidth: .infinity)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: rating)
                .onTapGesture {
                    rating = number
                    Theme.Haptics.selection()
                }
            }
        }
    }

    // MARK: - Emotion Label

    private var emotionLabelView: some View {
        HStack(spacing: Spacing.sm) {
            Text(Theme.emotionLabel(for: rating))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color.emotionColor(for: rating))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: Color.emotionColor(for: rating).opacity(0.15), radius: 10, x: 0, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(Color.emotionColor(for: rating).opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: rating)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isDragging)
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
