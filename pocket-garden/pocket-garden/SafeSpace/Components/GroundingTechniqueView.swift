import SwiftUI
import Inject

struct GroundingTechniqueView: View {
    @ObserveInjection var inject

    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var completedSteps: Set<Int> = []
    @State private var itemsCompletedForStep: Int = 0
    @Environment(\.dismiss) private var dismiss

    private let steps: [GroundingStep] = [
        GroundingStep(
            count: 5,
            sense: "See",
            icon: "eye.fill",
            color: .blue,
            prompt: "Name 5 things you can see around you"
        ),
        GroundingStep(
            count: 4,
            sense: "Touch",
            icon: "hand.raised.fill",
            color: .green,
            prompt: "Name 4 things you can touch"
        ),
        GroundingStep(
            count: 3,
            sense: "Hear",
            icon: "ear.fill",
            color: .purple,
            prompt: "Name 3 things you can hear"
        ),
        GroundingStep(
            count: 2,
            sense: "Smell",
            icon: "nose.fill",
            color: .orange,
            prompt: "Name 2 things you can smell"
        ),
        GroundingStep(
            count: 1,
            sense: "Taste",
            icon: "mouth.fill",
            color: .pink,
            prompt: "Name 1 thing you can taste"
        )
    ]

    var body: some View {
        ZStack {
            Color.backgroundCream
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Grounding Exercise")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)

                    Text("Reconnect with the present moment")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    Text("Step \(currentStep + 1) of \(steps.count)")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary.opacity(0.8))
                }
                .padding(.top, 40)
                .padding(.bottom, 32)

                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Capsule()
                            .fill(completedSteps.contains(index) ? Color.primaryGreen : Color.borderColor)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)

                // Current step
                if currentStep < steps.count {
                    let step = steps[currentStep]

                    VStack(spacing: 32) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            step.color.opacity(0.3),
                                            step.color.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 140, height: 140)

                            Image(systemName: step.icon)
                                .font(.system(size: 50))
                                .foregroundStyle(step.color)
                        }
                        .padding(.top, 20)

                        // Prompt
                        VStack(spacing: 16) {
                            Text(step.prompt)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.textPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("Take your time")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)

                            HStack(spacing: 12) {
                                ForEach(0..<step.count, id: \.self) { index in
                                    Circle()
                                        .fill(index < itemsCompletedForStep ? Color.primaryGreen : Color.clear)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primaryGreen.opacity(0.4), lineWidth: 2)
                                        )
                                        .onTapGesture {
                                            handleGroundingTap()
                                        }
                                }
                            }
                        }

                        Spacer()

                        // Panda encouragement
                        HStack(spacing: 12) {
                            Image("panda_supportive")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)

                            Text(encouragementText)
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

                        // Tap anywhere hint
                        Text("Tap anywhere to continue")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary.opacity(0.7))
                            .padding(.bottom, 40)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleGroundingTap()
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                } else {
                    // Completion view
                    completionView
                }
            }
        }
        .enableInjection()
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success icon
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

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.primaryGreen)
            }

            VStack(spacing: 12) {
                Text("Well Done!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Text("You're more grounded now")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }

            // Panda celebration
            HStack(spacing: 12) {
                Image("panda_happy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)

                Text("You did great! Notice how you feel right now.")
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

    private var encouragementText: String {
        switch currentStep {
        case 0: return "Great start! Look around you."
        case 1: return "You're doing well. Feel the textures."
        case 2: return "Listen carefully to your surroundings."
        case 3: return "Almost there! Notice the scents."
        case 4: return "Last one! What can you taste?"
        default: return "You're amazing!"
        }
    }

    // MARK: - Actions

    private func nextStep() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        completedSteps.insert(currentStep)
        itemsCompletedForStep = 0
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            currentStep += 1
        }
    }

    private func handleGroundingTap() {
        guard currentStep < steps.count else { return }

        let step = steps[currentStep]

        if itemsCompletedForStep < step.count {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            itemsCompletedForStep += 1

            if itemsCompletedForStep >= step.count {
                nextStep()
            }
        }
    }
}

// MARK: - Supporting Types

struct GroundingStep {
    let count: Int
    let sense: String
    let icon: String
    let color: Color
    let prompt: String
}

#Preview {
    GroundingTechniqueView {
        print("Grounding completed")
    }
}
