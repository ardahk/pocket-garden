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
    @State private var ringProgress: CGFloat = 0

    @Environment(\.dismiss) private var dismiss

    private let circleMinSize: CGFloat = 120
    private let circleMaxSize: CGFloat = 220

    // Calm, unified color palette
    private var breathColor: Color {
        switch currentPhase {
        case .inhale: return Color(red: 0.4, green: 0.7, blue: 0.9)
        case .hold1, .hold2: return Color(red: 0.5, green: 0.8, blue: 0.75)
        case .exhale: return Color(red: 0.6, green: 0.75, blue: 0.85)
        }
    }
    
    // Primary accent for breathing theme
    private let breathingAccent = Color(red: 0.25, green: 0.62, blue: 0.96)

    var body: some View {
        ZStack {
            // Clean, minimal background with soft blue tint (dark mode compatible)
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground),
                    Color(UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark
                            ? UIColor(red: 0.12, green: 0.15, blue: 0.22, alpha: 1.0)
                            : UIColor(red: 0.90, green: 0.95, blue: 1.0, alpha: 1.0)
                    })
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Minimal header
                HStack {
                    Button(action: {
                        stopBreathing()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color(.tertiaryLabel))
                            .frame(width: 32, height: 32)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if hasStarted {
                        Text(timeRemainingText)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Phase label above the circle
                Text(currentPhase.instruction.uppercased())
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.bottom, 8)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: currentPhase.instruction)

                // Main breathing visualization
                ZStack {
                    // Subtle outer ring (progress indicator when active)
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 4)
                        .frame(width: circleMaxSize + 40, height: circleMaxSize + 40)

                    if hasStarted {
                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(
                                breathColor.opacity(0.6),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: circleMaxSize + 40, height: circleMaxSize + 40)
                            .rotationEffect(.degrees(-90))
                    }

                    // Main breathing circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    breathColor.opacity(0.5),
                                    breathColor.opacity(0.25)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: circleSize / 2
                            )
                        )
                        .frame(width: circleSize, height: circleSize)

                    // Countdown number in center (only during session)
                    if hasStarted && phaseSecondsRemaining > 0 {
                        Text("\(phaseSecondsRemaining)")
                            .font(.system(size: 72, weight: .ultraLight, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color(.label))
                            .contentTransition(.numericText())
                    }
                }
                .frame(height: circleMaxSize + 100)

                Spacer()

                // Bottom controls
                VStack(spacing: 24) {
                    if !hasStarted {
                        // Pattern selector (native segmented style)
                        VStack(spacing: 20) {
                            Picker("Pattern", selection: $selectedPattern) {
                                ForEach(BreathingPattern.allPatterns) { option in
                                    Text(option.shortName).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 20)

                            // Pattern details - fixed height so pills don't jump
                            VStack(spacing: 8) {
                                Text(selectedPattern.name)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color(.label))

                                Text(selectedPattern.description)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color(.secondaryLabel))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .padding(.horizontal, 32)
                            }
                            .frame(height: 70) // Fixed height for consistent pill placement

                            // Phase timing pills
                            HStack(spacing: 6) {
                                BreathingPhasePill(label: "In", value: selectedPattern.inhale)
                                if selectedPattern.hold1 > 0 {
                                    BreathingPhasePill(label: "Hold", value: selectedPattern.hold1)
                                }
                                BreathingPhasePill(label: "Out", value: selectedPattern.exhale)
                                if selectedPattern.hold2 > 0 {
                                    BreathingPhasePill(label: "Hold", value: selectedPattern.hold2)
                                }
                            }
                        }

                        // Start button
                        Button(action: startBreathing) {
                            Text("Begin")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(breathingAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    } else {
                        // During session: show current pattern info
                        VStack(spacing: 12) {
                            Text(selectedPattern.name)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Color(.label))

                            HStack(spacing: 6) {
                                BreathingPhasePill(
                                    label: "In",
                                    value: selectedPattern.inhale,
                                    isActive: currentPhase == .inhale
                                )
                                if selectedPattern.hold1 > 0 {
                                    BreathingPhasePill(
                                        label: "Hold",
                                        value: selectedPattern.hold1,
                                        isActive: currentPhase == .hold1
                                    )
                                }
                                BreathingPhasePill(
                                    label: "Out",
                                    value: selectedPattern.exhale,
                                    isActive: currentPhase == .exhale
                                )
                                if selectedPattern.hold2 > 0 {
                                    BreathingPhasePill(
                                        label: "Hold",
                                        value: selectedPattern.hold2,
                                        isActive: currentPhase == .hold2
                                    )
                                }
                            }
                        }

                        // End session button
                        Button(action: {
                            stopBreathing()
                            onComplete()
                            dismiss()
                        }) {
                            Text("End Session")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(breathingAccent)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom, 40)
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
        return String(format: "%d:%02d", minutes, seconds)
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

        // Animate circle size
        withAnimation(.easeInOut(duration: Double(phaseDuration))) {
            phaseProgress = currentPhase == .inhale || currentPhase == .hold1 ? 1.0 : 0.0
        }

        // Animate ring progress from 0 to 1 over the phase duration
        ringProgress = 0
        withAnimation(.linear(duration: Double(phaseDuration))) {
            ringProgress = 1.0
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

struct BreathingPhasePill: View {
    let label: String
    let value: Int
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isActive ? Color(.label) : Color(.secondaryLabel))

            Text("\(value)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isActive ? Color(.label) : Color(.tertiaryLabel))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isActive ? Color(.systemGray5) : Color(.tertiarySystemFill))
        )
    }
}

// MARK: - Breath Phase

enum BreathPhase {
    case inhale, hold1, exhale, hold2

    var instruction: String {
        switch self {
        case .inhale: return "Inhale"
        case .hold1: return "Hold"
        case .exhale: return "Exhale"
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
