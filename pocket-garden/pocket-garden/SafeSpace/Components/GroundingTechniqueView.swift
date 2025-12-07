import SwiftUI
import Inject

struct GroundingTechniqueView: View {
    @ObserveInjection var inject

    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var completedSteps: Set<Int> = []
    @State private var itemsCompletedForStep: Int = 0
    @State private var iconPulse = false
    @State private var bubbleScales: [CGFloat] = []
    @State private var showIntro = true
    @State private var showContent = false
    @State private var showInfoSheet = false
    @Environment(\.dismiss) private var dismiss
    
    // Cohesive teal/cyan grounding theme
    private let groundingTeal = Color(hex: "5AC8C8")
    private let groundingTealLight = Color(hex: "7DD8D8")
    private let groundingTealDark = Color(hex: "3BA8A8")

    private let steps: [GroundingStep] = [
        GroundingStep(
            count: 5,
            sense: "See",
            icon: "eye.fill",
            prompt: "Name 5 things you can see"
        ),
        GroundingStep(
            count: 4,
            sense: "Touch",
            icon: "hand.raised.fill",
            prompt: "Name 4 things you can touch"
        ),
        GroundingStep(
            count: 3,
            sense: "Hear",
            icon: "ear.fill",
            prompt: "Name 3 things you can hear"
        ),
        GroundingStep(
            count: 2,
            sense: "Smell",
            icon: "nose.fill",
            prompt: "Name 2 things you can smell"
        ),
        GroundingStep(
            count: 1,
            sense: "Taste",
            icon: "mouth.fill",
            prompt: "Name 1 thing you can taste"
        )
    ]

    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: [
                    Color.backgroundCream,
                    groundingTeal.opacity(0.08),
                    Color.backgroundCream
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if showIntro {
                    introView
                } else {
                    // Header
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Spacer()
                            
                            Text("Grounding")
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textPrimary)
                            
                            Button {
                                showInfoSheet = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundStyle(groundingTeal.opacity(0.9))
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                        }

                        Text("5-4-3-2-1 technique")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 24)

                // Progress indicators with step numbers
                HStack(spacing: 12) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        ZStack {
                            Circle()
                                .fill(
                                    index < currentStep ? groundingTeal :
                                    index == currentStep ? groundingTeal.opacity(0.2) :
                                    Color.borderColor.opacity(0.3)
                                )
                                .frame(width: 32, height: 32)
                            
                            if index < currentStep {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(steps[index].count)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(index == currentStep ? groundingTeal : Color.textSecondary.opacity(0.5))
                            }
                        }
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? groundingTeal : Color.borderColor.opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: 20)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)

                // Current step
                if currentStep < steps.count {
                    let step = steps[currentStep]

                    VStack(spacing: 24) {
                        // Animated icon with glow
                        ZStack {
                            // Outer glow ring
                            Circle()
                                .fill(groundingTeal.opacity(0.1))
                                .frame(width: 160, height: 160)
                                .scaleEffect(iconPulse ? 1.1 : 1.0)
                            
                            // Inner gradient circle
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            groundingTealLight.opacity(0.4),
                                            groundingTeal.opacity(0.2),
                                            groundingTeal.opacity(0.05)
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 70
                                    )
                                )
                                .frame(width: 140, height: 140)

                            // Icon with subtle animation
                            Image(systemName: step.icon)
                                .font(.system(size: 48, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [groundingTealLight, groundingTeal],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .scaleEffect(iconPulse ? 1.05 : 1.0)
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                                iconPulse = true
                            }
                        }

                        // Sense label
                        Text(step.sense.uppercased())
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(groundingTeal)
                            Spacer()
                        
                        // Prompt
                        Text(step.prompt)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        // Interactive bubbles
                        HStack(spacing: 16) {
                            ForEach(0..<step.count, id: \.self) { index in
                                GroundingBubble(
                                    isFilled: index < itemsCompletedForStep,
                                    accentColor: groundingTeal,
                                    size: 44
                                )
                                .scaleEffect(bubbleScales.indices.contains(index) ? bubbleScales[index] : 1.0)
                            }
                        }
                        .padding(.top, 8)

                        Text("Tap anywhere as you notice each one")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary.opacity(0.7))

                        Spacer()

                        // Bumblebee encouragement
                        HStack(spacing: 12) {
                            Image("panda_supportive")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)

                            Text(encouragementText)
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(groundingTeal.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                    .onAppear {
                        setupBubbleScales(for: step.count)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleGroundingTap()
                    }
                    .onChange(of: currentStep) { _, _ in
                        if currentStep < steps.count {
                            setupBubbleScales(for: steps[currentStep].count)
                        }
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
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            groundingInfoSheet
        }
        .enableInjection()
    }
    
    // MARK: - Intro View
    
    private var introView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                groundingTeal.opacity(0.2),
                                groundingTeal.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "hand.point.down.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [groundingTealLight, groundingTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)
            
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Spacer()
                    
                    Text("Grounding")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    
                    Button {
                        showInfoSheet = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(groundingTeal.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                
                Text("A quick way to anchor yourself\nin the present moment when overwhelmed")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineSpacing(2)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            // How it works
            VStack(alignment: .leading, spacing: 16) {
                Text("How it works")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                
                HowItWorksRow(number: 5, text: "Name 5 things you can see")
                HowItWorksRow(number: 4, text: "Name 4 things you can touch")
                HowItWorksRow(number: 3, text: "Name 3 things you can hear")
                HowItWorksRow(number: 2, text: "Name 2 things you can smell")
                HowItWorksRow(number: 1, text: "Name 1 thing you can taste")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            )
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
            
            // Bumblebee encouragement
            HStack(spacing: 12) {
                Image("panda_supportive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                
                Text("This simple technique can help calm your nervous system in just a few minutes.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground.opacity(0.8))
            )
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 40)
            
            Spacer()
            
            // Begin button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showIntro = false
                }
            }) {
                Text("Begin")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(groundingTeal)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Info Sheet
    
    private var groundingInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Why this exercise helps")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("The 5-4-3-2-1 grounding technique uses your five senses to shift attention away from anxious thoughts and back to the present moment. By systematically noticing what you can see, touch, hear, smell, and taste, you interrupt the worry cycle and activate your body's calming response.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Grounding exercises like this one are commonly used in trauma-informed care and anxiety treatment. Research shows that sensory-based techniques can reduce physiological arousal and help people feel more in control during moments of distress.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                        
                        if let url = URL(string: "https://www.urmc.rochester.edu/behavioral-health-partners/bhp-blog/april-2018/5-4-3-2-1-coping-technique-for-anxiety.aspx") {
                            Link("University of Rochester Medical Center – 5-4-3-2-1 Coping Technique for Anxiety", destination: url)
                                .font(.subheadline)
                                .foregroundStyle(groundingTeal)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Science behind this")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showInfoSheet = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(groundingTeal)
                }
            }
        }
    }
    
    private func setupBubbleScales(for count: Int) {
        bubbleScales = Array(repeating: 1.0, count: count)
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success icon with animation
            ZStack {
                // Outer glow
                Circle()
                    .fill(groundingTeal.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                groundingTealLight.opacity(0.4),
                                groundingTeal.opacity(0.2),
                                groundingTeal.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(groundingTeal)
            }

            VStack(spacing: 12) {
                Text("You're Grounded")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)

                Text("Take a moment to notice how you feel")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }

            // Bumblebee celebration
            HStack(spacing: 12) {
                Image("panda_happy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)

                Text("Wonderful! You've reconnected with the present moment.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(groundingTeal.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)

            Spacer()

            Button(action: {
                onComplete()
                dismiss()
            }) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(groundingTeal)
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
        // Distinct haptic for step transition - success notification
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.notificationOccurred(.success)

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
            // Light haptic for each bubble fill
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred(intensity: 0.6)
            
            // Animate the bubble
            let index = itemsCompletedForStep
            if bubbleScales.indices.contains(index) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    bubbleScales[index] = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        if bubbleScales.indices.contains(index) {
                            bubbleScales[index] = 1.0
                        }
                    }
                }
            }

            itemsCompletedForStep += 1

            if itemsCompletedForStep >= step.count {
                // Delay before moving to next step for visual feedback
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    nextStep()
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct GroundingStep {
    let count: Int
    let sense: String
    let icon: String
    let prompt: String
}

// MARK: - Grounding Bubble Component

struct GroundingBubble: View {
    let isFilled: Bool
    let accentColor: Color
    let size: CGFloat
    
    @State private var fillAnimation = false
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    isFilled ? accentColor : accentColor.opacity(0.3),
                    lineWidth: 2
                )
                .frame(width: size, height: size)
            
            // Fill circle with animation
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(0.9),
                            accentColor
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size - 8, height: size - 8)
                .scaleEffect(isFilled ? 1.0 : 0.0)
                .opacity(isFilled ? 1.0 : 0.0)
            
            // Checkmark when filled
            if isFilled {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isFilled)
    }
}

#Preview {
    GroundingTechniqueView {
        print("Grounding completed")
    }
}
