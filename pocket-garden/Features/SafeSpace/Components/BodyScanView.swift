import SwiftUI
import Inject

struct BodyScanView: View {
    @ObserveInjection var inject

    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var isInstructionPhase = true // Tense or release
    @State private var progress: CGFloat = 0
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
                                            bodyPart.position.color.opacity(0.3),
                                            bodyPart.position.color.opacity(0.0)
                                        ],
                                        center: .center,
                                        startRadius: 50,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 200, height: 200)

                            Circle()
                                .fill(bodyPart.position.color.opacity(0.2))
                                .frame(width: 120, height: 120)

                            Image(systemName: bodyPart.icon)
                                .font(.system(size: 50))
                                .foregroundStyle(bodyPart.position.color)
                        }
                        .scaleEffect(isInstructionPhase ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isInstructionPhase)

                        // Instructions
                        VStack(spacing: 16) {
                            Text(bodyPart.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.textPrimary)

                            Text(currentInstruction)
                                .font(.body)
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        // Timer indicator
                        Text(timerText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.cardBackground)
                            )

                        Spacer()

                        // Skip button
                        Button(action: skipToEnd) {
                            Text("Skip to End")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding(.bottom, 40)
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
                Image("panda-supportive")
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
                    .shadow(color: Color.shadowColor, radius: 4, y: 2)
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
                    .shadow(color: Color.primaryGreen.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Computed Properties

    private var currentInstruction: String {
        if isInstructionPhase {
            return "Tense your \(bodyParts[currentStep].name.lowercased()) for 5 seconds..."
        } else {
            return "Now release... let all the tension go"
        }
    }

    private var timerText: String {
        isInstructionPhase ? "Tense (5s)" : "Release (5s)"
    }

    // MARK: - Body Scan Logic

    private func startBodyScan() {
        performNextPhase()
    }

    private func performNextPhase() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Wait 5 seconds, then move to next phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
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

    private func skipToEnd() {
        withAnimation {
            currentStep = bodyParts.count
            progress = Double(bodyParts.count * 2)
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
