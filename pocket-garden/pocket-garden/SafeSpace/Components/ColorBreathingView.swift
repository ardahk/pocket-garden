import SwiftUI
import Inject

struct ColorBreathingView: View {
    @ObserveInjection var inject
    
    let duration: Int
    let onComplete: () -> Void
    
    @State private var currentPhase: ColorBreathPhase = .inhale
    @State private var phaseProgress: CGFloat = 0
    @State private var cyclesCompleted = 0
    @State private var timeRemaining: Int = 0
    @State private var isAnimating = false
    @State private var phaseSecondsRemaining = 0
    @Environment(\.dismiss) private var dismiss
    
    private let circleMinSize: CGFloat = 100
    private let circleMaxSize: CGFloat = 220
    
    private let calmColor = Color.blue
    private let stressColor = Color.red.opacity(0.6)
    
    var body: some View {
        ZStack {
            // Animated background
            LinearGradient(
                colors: [
                    Color.backgroundCream,
                    currentPhase.isInhale ? calmColor.opacity(0.15) : stressColor.opacity(0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: currentPhaseDuration), value: currentPhase)
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Color Breathing")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text(isAnimating ? currentPhase.instruction : "Breathe in calm, breathe out stress")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Color breathing circle
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    currentPhase.color(calm: calmColor, stress: stressColor).opacity(0.3),
                                    currentPhase.color(calm: calmColor, stress: stressColor).opacity(0.0)
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
                                    currentPhase.color(calm: calmColor, stress: stressColor).opacity(0.7),
                                    currentPhase.color(calm: calmColor, stress: stressColor).opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: circleSize, height: circleSize)
                        .clipShape(Circle())
                    
                    // Instruction and countdown
                    VStack(spacing: 8) {
                        Image(systemName: currentPhase.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                        
                        Text(currentPhase.colorName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        
                        if phaseSecondsRemaining > 0 {
                            Text("\(phaseSecondsRemaining)s")
                                .font(.headline)
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }
                
                Spacer()
                
                // Instructions card
                if !isAnimating {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image("panda_supportive")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                            
                            Text("Visualize breathing in calm blue energy and breathing out red stress")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                        )
                    }
                    .padding(.horizontal, 24)
                }
                
                // Stats
                VStack(spacing: 12) {
                    if isAnimating {
                        HStack(spacing: 24) {
                            VStack(spacing: 4) {
                                Text("\(cyclesCompleted)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.textPrimary)
                                Text("cycles")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            
                            VStack(spacing: 4) {
                                Text(timeRemainingText)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.textPrimary)
                                Text("remaining")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                    
                    Button(action: isAnimating ? stopBreathing : startBreathing) {
                        Text(isAnimating ? "Feeling better?" : "Start Color Breathing")
                            .font(.headline)
                            .foregroundStyle(isAnimating ? Color.primaryGreen : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isAnimating ? Color.clear : Color.purple)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isAnimating ? Color.primaryGreen : Color.clear, lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 24)
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 40)
            }
        }
        .enableInjection()
    }
    
    private var circleSize: CGFloat {
        circleMinSize + (circleMaxSize - circleMinSize) * phaseProgress
    }
    
    private var timeRemainingText: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var currentPhaseDuration: Double {
        Double(currentPhase.duration)
    }
    
    private func startBreathing() {
        isAnimating = true
        timeRemaining = duration * 60
        cyclesCompleted = 0
        startPhase(.inhale)
        startTimer()
    }
    
    private func stopBreathing() {
        isAnimating = false
        onComplete()
        dismiss()
    }
    
    private func startPhase(_ phase: ColorBreathPhase) {
        guard isAnimating else { return }
        
        currentPhase = phase
        phaseSecondsRemaining = phase.duration
        
        // Haptic
        let generator = UIImpactFeedbackGenerator(style: phase.isInhale ? .medium : .light)
        generator.impactOccurred()
        
        // Animate circle
        withAnimation(.easeInOut(duration: Double(phase.duration))) {
            phaseProgress = phase.isInhale ? 1.0 : 0.0
        }
    }
    
    private func nextPhase() {
        guard isAnimating else { return }
        
        switch currentPhase {
        case .inhale:
            startPhase(.hold1)
        case .hold1:
            startPhase(.exhale)
        case .exhale:
            startPhase(.hold2)
        case .hold2:
            cyclesCompleted += 1
            startPhase(.inhale)
        }
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
}

enum ColorBreathPhase {
    case inhale, hold1, exhale, hold2
    
    var duration: Int {
        switch self {
        case .inhale: return 4
        case .hold1: return 2
        case .exhale: return 6
        case .hold2: return 2
        }
    }
    
    var instruction: String {
        switch self {
        case .inhale: return "Breathe in calm blue energy"
        case .hold1: return "Hold the calm"
        case .exhale: return "Breathe out red stress"
        case .hold2: return "Rest and release"
        }
    }
    
    var icon: String {
        switch self {
        case .inhale: return "arrow.down.circle.fill"
        case .hold1: return "pause.circle.fill"
        case .exhale: return "arrow.up.circle.fill"
        case .hold2: return "pause.circle.fill"
        }
    }
    
    var colorName: String {
        switch self {
        case .inhale, .hold1: return "Calm Blue"
        case .exhale, .hold2: return "Release Red"
        }
    }
    
    var isInhale: Bool {
        self == .inhale || self == .hold1
    }
    
    func color(calm: Color, stress: Color) -> Color {
        isInhale ? calm : stress
    }
}

#Preview {
    ColorBreathingView(duration: 3) {
        print("Color breathing completed")
    }
}
