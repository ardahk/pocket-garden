import SwiftUI
import Inject

struct BodyScanView: View {
    @ObserveInjection var inject

    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var isInstructionPhase = true // Tense or release
    @State private var progress: CGFloat = 0
    @State private var countdown: Int = 5 // Live countdown timer
    @State private var phaseColor: Color = .green
    @Environment(\.dismiss) private var dismiss

    private let bodyParts: [BodyPart] = [
        BodyPart(name: "Feet & Toes", icon: "figure.walk", position: .bottom),
        BodyPart(name: "Legs", icon: "figure.walk", position: .lower),
        BodyPart(name: "Hips & Glutes", icon: "figure.stand", position: .middle),
        BodyPart(name: "Stomach", icon: "figure.stand", position: .middle),
        BodyPart(name: "Chest & Back", icon: "figure.stand", position: .upper),
        BodyPart(name: "Hands & Arms", icon: "hand.raised.fill", position: .upper),
        BodyPart(name: "Shoulders", icon: "figure.stand", position: .upper),
        BodyPart(name: "Neck", icon: "figure.stand", position: .top),
        BodyPart(name: "Face", icon: "face.smiling", position: .top)
    ]

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.backgroundCream,
                    Color.emotionCalm.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Body Scan")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)

                    Text("Progressive muscle relaxation")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    Text("Step \(min(currentStep + 1, bodyParts.count)) of \(bodyParts.count)")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary.opacity(0.8))
                }
                .padding(.top, 40)
                .padding(.bottom, 24)

                // Progress bar
                ProgressView(value: progress, total: Double(bodyParts.count * 2))
                    .tint(Color.primaryGreen)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)

                if currentStep < bodyParts.count {
                    let bodyPart = bodyParts[currentStep]

                    VStack(spacing: 32) {
                        // Body part icon
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            phaseColor.opacity(0.3),
                                            phaseColor.opacity(0.0)
                                        ],
                                        center: .center,
                                        startRadius: 50,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 200, height: 200)

                            Circle()
                                .fill(phaseColor.opacity(0.2))
                                .frame(width: 120, height: 120)

                            Image(systemName: bodyPart.icon)
                                .font(.system(size: 50))
                                .foregroundStyle(phaseColor)
                        }
                        .scaleEffect(isInstructionPhase ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isInstructionPhase)

                        // Instructions with integrated countdown
                        VStack(spacing: 16) {
                            Text(bodyPart.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.textPrimary)

                            VStack(spacing: 12) {
                                Text(currentInstructionBase)
                                    .font(.body)
                                    .foregroundStyle(Color.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                // Prominent countdown
                                Text("\(countdown)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(phaseColor)
                                    .frame(minWidth: 60)
                                    .contentTransition(.numericText())
                            }
                        }

                        Spacer()
                    }
                } else {
                    completionView
                }
            }
        }
        .onAppear {
            startBodyScan()
        }
        .enableInjection()
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryGreen.opacity(0.3),
                                Color.primaryGreen.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.primaryGreen)
            }

            VStack(spacing: 12) {
                Text("Body Scan Complete")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Text("Your body is relaxed and at ease")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Panda
            HStack(spacing: 12) {
                Image("panda_supportive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)

                Text("Notice how calm your body feels now.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
            )
            .padding(.horizontal, 24)

            Spacer()

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
            .padding(.bottom, 40)
            .buttonStyle(.plain)
        }
    }

    // MARK: - Computed Properties

    private var currentInstructionBase: String {
        if isInstructionPhase {
            return "Tense your \(bodyParts[currentStep].name.lowercased())..."
        } else {
            return "Now release... let all the tension go"
        }
    }

    // MARK: - Body Scan Logic

    private func startBodyScan() {
        updatePhaseColor()
        performNextPhase()
    }

    private func performNextPhase() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Reset countdown
        countdown = 5
        updatePhaseColor()

        // Start countdown timer
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdown -= 1
            updatePhaseColor()

            if countdown <= 0 {
                timer.invalidate()

                // Move to next phase
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    progress += 1

                    if isInstructionPhase {
                        // Move to release phase
                        isInstructionPhase = false
                        performNextPhase()
                    } else {
                        // Move to next body part
                        isInstructionPhase = true
                        currentStep += 1

                        if currentStep < bodyParts.count {
                            performNextPhase()
                        } else {
                            // Complete
                            let completionGenerator = UINotificationFeedbackGenerator()
                            completionGenerator.notificationOccurred(.success)
                        }
                    }
                }
            }
        }
    }

    private func updatePhaseColor() {
        // Smooth color progression synchronized with countdown
        withAnimation(.easeInOut(duration: 1.0)) {
            switch countdown {
            case 5:
                phaseColor = Color.green
            case 4:
                phaseColor = Color(red: 0.4, green: 0.8, blue: 0.6)
            case 3:
                phaseColor = Color(red: 0.8, green: 0.8, blue: 0.3)
            case 2:
                phaseColor = Color.orange
            case 1:
                phaseColor = Color(red: 1.0, green: 0.4, blue: 0.3)
            default:
                phaseColor = Color.red
            }
        }
    }
}

// MARK: - Supporting Types

struct BodyPart {
    let name: String
    let icon: String
    let position: BodyPosition
}

enum BodyPosition {
    case bottom, lower, middle, upper, top

    var color: Color {
        switch self {
        case .bottom: return .blue
        case .lower: return .cyan
        case .middle: return .green
        case .upper: return .orange
        case .top: return .purple
        }
    }
}

#Preview {
    BodyScanView {
        print("Body scan completed")
    }
}
