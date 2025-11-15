import SwiftUI
import Inject

struct AffirmationsView: View {
    @ObserveInjection var inject

    let duration: Int // minutes
    let onComplete: () -> Void

    @State private var currentIndex = 0
    @State private var affirmations: [Affirmation] = []
    @State private var timeRemaining: Int = 0
    @State private var dragOffset: CGSize = .zero
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.backgroundCream,
                    Color.primaryGreen.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Gentle Affirmations")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)

                    Text("Speak kindly to yourself")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 40)

                Spacer()

                // Affirmation cards
                ZStack {
                    // Show next 2 cards in background for depth
                    ForEach(Array(affirmations.enumerated()), id: \.element.id) { index, affirmation in
                        if index >= currentIndex && index < currentIndex + 3 {
                            AffirmationCard(
                                affirmation: affirmation,
                                offset: index - currentIndex
                            )
                            .offset(dragOffset)
                            .rotationEffect(.degrees(Double(dragOffset.width) / 20))
                            .opacity(index == currentIndex ? 1.0 : 0.5)
                            .scaleEffect(index == currentIndex ? 1.0 : 0.95 - CGFloat(index - currentIndex) * 0.05)
                            .offset(y: CGFloat(index - currentIndex) * 10)
                            .zIndex(Double(affirmations.count - index))
                            .gesture(
                                index == currentIndex ? DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation
                                    }
                                    .onEnded { value in
                                        handleSwipe(value: value)
                                    }
                                : nil
                            )
                        }
                    }
                }
                .frame(height: 400)
                .padding(.horizontal, 24)

                Spacer()

                // Instructions
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image("panda_supportive") // Switched to underscore style
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)

                        Text("Swipe to see more affirmations")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBackground)
                            .shadow(color: Color.shadowColor, radius: 4, y: 2)
                    )
                    .padding(.horizontal, 24)

                    // Progress
                    Text("\(currentIndex + 1) of \(affirmations.count)")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)

                    // Done button
                    Button(action: {
                        onComplete()
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.primaryGreen)
                            )
                    }
                    .padding(.horizontal, 24)
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            setupAffirmations()
            startTimer()
        }
        .enableInjection()
    }

    // MARK: - Setup

    private func setupAffirmations() {
        // Shuffle affirmations for variety
        affirmations = Affirmation.defaultAffirmations.shuffled()
        timeRemaining = duration * 60
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            timeRemaining -= 1

            if timeRemaining <= 0 {
                timer.invalidate()
                onComplete()
                dismiss()
            }
        }
    }

    // MARK: - Swipe Handling

    private func handleSwipe(value: DragGesture.Value) {
        let swipeThreshold: CGFloat = 100

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if abs(value.translation.width) > swipeThreshold {
                // Swipe detected
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()

                // Move to next affirmation
                if currentIndex < affirmations.count - 1 {
                    currentIndex += 1
                }
            }
            dragOffset = .zero
        }
    }
}

// MARK: - Affirmation Card

struct AffirmationCard: View {
    let affirmation: Affirmation
    let offset: Int

    var body: some View {
        VStack(spacing: 24) {
            // Category badge
            Text(affirmation.category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(categoryColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(categoryColor.opacity(0.15))
                )

            // Affirmation text
            Text(affirmation.text)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 32)

            Spacer()

            // Decorative element
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [categoryColor.opacity(0.6), categoryColor.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowColor, radius: 20, y: 10)
        )
    }

    private var categoryColor: Color {
        switch affirmation.category {
        case .safety: return .blue
        case .strength: return .orange
        case .peace: return .green
        case .selfCompassion: return .pink
        case .present: return .purple
        case .resilience: return .red
        }
    }
}

#Preview {
    AffirmationsView(duration: 2) {
        print("Affirmations completed")
    }
}
