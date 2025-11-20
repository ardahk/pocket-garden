import SwiftUI
import Inject

struct BreathingExerciseView: View {
    @ObserveInjection var inject

    let pattern: BreathingPattern
    let duration: Int // Total duration in minutes
    let onComplete: () -> Void

    @State private var selectedPattern: BreathingPattern = .boxBreathing
    @State private var currentPhase: BreathPhase = .inhale
    @State private var phaseProgress: CGFloat = 0
    @State private var cyclesCompleted: Int = 0
    @State private var timeRemaining: Int = 0
    @State private var isAnimating = false
    @State private var hasStarted = false
    @State private var phaseSecondsRemaining: Int = 0

    @Environment(\.dismiss) private var dismiss

    private let circleMinSize: CGFloat = 100
    private let circleMaxSize: CGFloat = 200

    var body: some View {
        ZStack {
            // Background gradient (kept static so only the circle feels like it moves)
            LinearGradient(
                colors: [
                    Color.backgroundCream,
                    Color.emotionCalm.opacity(0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Guided Breathing")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textPrimary)

                        Text("Choose a rhythm that feels right for you")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.top, 16)

                    // Breathing circle with instruction
                    VStack(spacing: 16) {
                    ZStack {
                        // Outer glow (fixed size so layout stays stable)
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        currentPhase.color.opacity(0.3),
                                        currentPhase.color.opacity(0.0)
                                    ],
                                    center: .center,
                                    startRadius: circleMaxSize / 2,
                                    endRadius: circleMaxSize / 2 + 60
                                )
                            )
                            .frame(width: circleMaxSize + 120, height: circleMaxSize + 120)

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
                            .clipShape(Circle())

                        // Instruction + per-phase countdown
                        VStack(spacing: 6) {
                            Text(currentPhase.instruction)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.textPrimary)

                            if phaseSecondsRemaining > 0 {
                                Text("\(phaseSecondsRemaining)s")
                                    .font(.headline)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                }

                // Pattern info and timer
                VStack(spacing: 16) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(BreathingPattern.allPatterns) { option in
                                BreathingPatternChip(
                                    pattern: option,
                                    isSelected: option == selectedPattern
                                ) {
                                    switchToPattern(option)
                                }
                            }
                        }
                        .disabled(hasStarted)
                        .opacity(hasStarted ? 0.6 : 1.0)
                        .padding(.horizontal, 24)
                    }

                    VStack(spacing: 6) {
                        Text(selectedPattern.name)
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)

                        Text(selectedPattern.description)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .lineLimit(3)
                            .minimumScaleFactor(0.9)
                    }

                    HStack(spacing: 8) {
                        if selectedPattern.inhale > 0 {
                            BreathingPhaseBadge(label: "Inhale", value: selectedPattern.inhale)
                        }
                        if selectedPattern.hold1 > 0 {
                            BreathingPhaseBadge(label: "Hold", value: selectedPattern.hold1)
                        }
                        if selectedPattern.exhale > 0 {
                            BreathingPhaseBadge(label: "Exhale", value: selectedPattern.exhale)
                        }
                        if selectedPattern.hold2 > 0 {
                            BreathingPhaseBadge(label: "Hold", value: selectedPattern.hold2)
                        }
                    }

                    // Time remaining
                    if hasStarted {
                        Text(timeRemainingText)
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }

                    if !hasStarted {
                        Button(action: {
                            startBreathing()
                        }) {
                            Text("Start \(selectedPattern.name)")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.primaryGreen)
                                )
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                    }

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
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
        }
        }
        .onAppear {
            selectedPattern = pattern
            timeRemaining = duration * 60
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
        guard !hasStarted else { return }

        timeRemaining = duration * 60
        phaseSecondsRemaining = 0
        cyclesCompleted = 0
        hasStarted = true
        isAnimating = true
        startPhase(.inhale)
        startTimer()
    }

    private func stopBreathing() {
        isAnimating = false
    }

    private func startPhase(_ phase: BreathPhase) {
        guard isAnimating else { return }

        currentPhase = phase
        let phaseDuration = currentPhase.duration(for: selectedPattern)

        // Haptic feedback
        generateHaptic(for: phase)

        // Animate circle
        withAnimation(.easeInOut(duration: Double(phaseDuration))) {
            phaseProgress = currentPhase == .inhale || currentPhase == .hold1 ? 1.0 : 0.0
        }

        // Reset per-phase countdown
        phaseSecondsRemaining = phaseDuration
    }

    private func nextPhase() {
        guard isAnimating else { return }

        switch currentPhase {
        case .inhale:
            if selectedPattern.hold1 > 0 {
                startPhase(.hold1)
            } else {
                startPhase(.exhale)
            }
        case .hold1:
            startPhase(.exhale)
        case .exhale:
            if selectedPattern.hold2 > 0 {
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
            phaseSecondsRemaining -= 1

            if phaseSecondsRemaining <= 0 {
                nextPhase()
            }

            if timeRemaining <= 0 {
                timer.invalidate()
                isAnimating = false
                onComplete()
                dismiss()
            }
        }
    }

    private func generateHaptic(for phase: BreathPhase) {
        let phaseDuration = phase.duration(for: selectedPattern)

        switch phase {
        case .inhale:
            // Strong, building taps through the inhale
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred(intensity: 1.0)

            let first = max(0.15, Double(phaseDuration) * 0.25)
            let second = max(0.3, Double(phaseDuration) * 0.5)
            let third = max(0.45, Double(phaseDuration) * 0.75)

            DispatchQueue.main.asyncAfter(deadline: .now() + first) {
                generator.impactOccurred(intensity: 1.0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + second) {
                generator.impactOccurred(intensity: 1.0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + third) {
                generator.impactOccurred(intensity: 1.0)
            }

        case .hold1, .hold2:
            // Firm "stretch" pulse while holding
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.prepare()
            generator.impactOccurred(intensity: 1.0)

            let mid = max(0.25, Double(phaseDuration) * 0.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + mid) {
                generator.impactOccurred(intensity: 0.9)
            }

        case .exhale:
            // Series of strong release taps as you breathe out
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.prepare()

            let first = max(0.1, Double(phaseDuration) * 0.2)
            let second = max(0.25, Double(phaseDuration) * 0.4)
            let third = max(0.4, Double(phaseDuration) * 0.7)

            generator.impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + first) {
                generator.impactOccurred(intensity: 0.9)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + second) {
                generator.impactOccurred(intensity: 0.8)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + third) {
                generator.impactOccurred(intensity: 0.7)
            }
        }
    }

    private func switchToPattern(_ newPattern: BreathingPattern) {
        // Allow choosing pattern freely before starting; lock once the session begins
        guard !hasStarted, newPattern != selectedPattern else { return }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        selectedPattern = newPattern
        phaseProgress = 0
    }
}

struct BreathingPatternChip: View {
    let pattern: BreathingPattern
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(pattern.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? Color.primaryGreen : Color.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.primaryGreen.opacity(0.15) : Color.cardBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.primaryGreen : Color.borderColor.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct BreathingPhaseBadge: View {
    let label: String
    let value: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)

            Text("\(value)s")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.cardBackground)
        )
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
