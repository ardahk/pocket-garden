import SwiftUI
import Inject

struct BreathingExerciseView: View {
    @ObserveInjection var inject

    let pattern: BreathingPattern
    let duration: Int // Total duration in minutes
    let onComplete: () -> Void

    @State private var currentPhase: BreathPhase = .inhale
    @State private var phaseProgress: CGFloat = 0
    @State private var cyclesCompleted: Int = 0
    @State private var timeRemaining: Int = 0
    @State private var isAnimating = false

    @Environment(\.dismiss) private var dismiss

    private let circleMinSize: CGFloat = 120
    private let circleMaxSize: CGFloat = 240

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.backgroundCream,
                    currentPhase.color.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                // Header
                VStack(spacing: 8) {
                    Text("You're Safe Here")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)

                    Text("Take all the time you need")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 40)

                Spacer()

                // Breathing circle with instruction
                VStack(spacing: 32) {
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        currentPhase.color.opacity(0.3),
                                        currentPhase.color.opacity(0.0)
                                    ],
                                    center: .center,
                                    startRadius: circleSize / 2,
                                    endRadius: circleSize / 2 + 60
                                )
                            )
                            .frame(width: circleSize + 120, height: circleSize + 120)

                        // Main breathing circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        currentPhase.color.opacity(0.6),
                                        currentPhase.color.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: circleSize, height: circleSize)
                            .shadow(color: currentPhase.color.opacity(0.3), radius: 20)

                        // Instruction text
                        Text(currentPhase.instruction)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textPrimary)
                    }

                    // Panda mascot
                    Image("panda_supportive")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .background(
                            Circle()
                                .fill(Color.cardBackground)
                                .frame(width: 100, height: 100)
                        )
                        .shadow(color: Color.shadowColor, radius: 8, y: 4)
                }

                Spacer()

                // Pattern info and timer
                VStack(spacing: 24) {
                    // Pattern name
                    Text(pattern.name)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)

                    // Time remaining
                    Text(timeRemainingText)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)

                    // Close button
                    Button(action: {
                        stopBreathing()
                        dismiss()
                    }) {
                        Text("Feeling better?")
                            .font(.subheadline)
                            .foregroundStyle(Color.primaryGreen)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startBreathing()
        }
        .onDisappear {
            stopBreathing()
        }
        .enableInjection()
    }

    // MARK: - Computed Properties

    private var circleSize: CGFloat {
        let progress = phaseProgress
        return circleMinSize + (circleMaxSize - circleMinSize) * progress
    }

    private var timeRemainingText: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d remaining", minutes, seconds)
    }

    // MARK: - Breathing Logic

    private func startBreathing() {
        timeRemaining = duration * 60
        isAnimating = true
        cyclesCompleted = 0
        startPhase(.inhale)
        startTimer()
    }

    private func stopBreathing() {
        isAnimating = false
    }

    private func startPhase(_ phase: BreathPhase) {
        guard isAnimating else { return }

        currentPhase = phase
        let phaseDuration = currentPhase.duration(for: pattern)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Animate circle
        withAnimation(.easeInOut(duration: Double(phaseDuration))) {
            phaseProgress = currentPhase == .inhale || currentPhase == .hold1 ? 1.0 : 0.0
        }

        // Schedule next phase
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(phaseDuration)) {
            nextPhase()
        }
    }

    private func nextPhase() {
        guard isAnimating else { return }

        switch currentPhase {
        case .inhale:
            if pattern.hold1 > 0 {
                startPhase(.hold1)
            } else {
                startPhase(.exhale)
            }
        case .hold1:
            startPhase(.exhale)
        case .exhale:
            if pattern.hold2 > 0 {
                startPhase(.hold2)
            } else {
                completeCycle()
            }
        case .hold2:
            completeCycle()
        }
    }

    private func completeCycle() {
        cyclesCompleted += 1
        startPhase(.inhale)
    }

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard isAnimating else {
                timer.invalidate()
                return
            }

            timeRemaining -= 1

            if timeRemaining <= 0 {
                timer.invalidate()
                isAnimating = false
                onComplete()
                dismiss()
            }
        }
    }
}

// MARK: - Breath Phase

enum BreathPhase {
    case inhale, hold1, exhale, hold2

    var instruction: String {
        switch self {
        case .inhale: return "Breathe In"
        case .hold1: return "Hold"
        case .exhale: return "Breathe Out"
        case .hold2: return "Hold"
        }
    }

    var color: Color {
        switch self {
        case .inhale: return .blue.opacity(0.7)
        case .hold1: return .green.opacity(0.7)
        case .exhale: return .orange.opacity(0.7)
        case .hold2: return .green.opacity(0.7)
        }
    }

    func duration(for pattern: BreathingPattern) -> Int {
        switch self {
        case .inhale: return pattern.inhale
        case .hold1: return pattern.hold1
        case .exhale: return pattern.exhale
        case .hold2: return pattern.hold2
        }
    }
}

#Preview {
    BreathingExerciseView(
        pattern: .boxBreathing,
        duration: 2
    ) {
        print("Breathing exercise completed")
    }
}
