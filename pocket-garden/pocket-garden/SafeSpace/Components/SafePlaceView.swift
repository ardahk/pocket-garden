import SwiftUI
import Inject

struct SafePlaceView: View {
    @ObserveInjection var inject
    
    let duration: Int
    let onComplete: () -> Void
    
    @State private var currentStep = 0
    @State private var isPlaying = false
    @State private var breathScale: CGFloat = 1.0
    @Environment(\.dismiss) private var dismiss
    
    private let visualizationSteps = [
        VisualizationStep(
            icon: "location.fill",
            title: "Choose Your Place",
            prompt: "Imagine a place where you feel completely safe and at peace. It could be real or imaginary."
        ),
        VisualizationStep(
            icon: "eye.fill",
            title: "What Do You See?",
            prompt: "Notice the colors, the light, the shapes around you. What catches your eye?"
        ),
        VisualizationStep(
            icon: "ear.fill",
            title: "What Do You Hear?",
            prompt: "Listen to the sounds of your safe place. Maybe birds, waves, silence, or gentle music."
        ),
        VisualizationStep(
            icon: "hand.raised.fill",
            title: "What Do You Feel?",
            prompt: "Notice the temperature, textures, the ground beneath you. Feel the comfort."
        ),
        VisualizationStep(
            icon: "nose.fill",
            title: "What Do You Smell?",
            prompt: "Perhaps fresh air, flowers, ocean breeze, or your favorite scent."
        ),
        VisualizationStep(
            icon: "heart.fill",
            title: "How Do You Feel?",
            prompt: "Notice the sense of peace, safety, and calm flowing through you."
        ),
        VisualizationStep(
            icon: "star.fill",
            title: "Anchor This Feeling",
            prompt: "Take a deep breath and remember: you can return here whenever you need."
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.backgroundCream,
                    Color.teal.opacity(0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Safe Place Visualization")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("Journey to your inner sanctuary")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 24)
                
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<visualizationSteps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.teal : Color.borderColor)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 32)
                
                Spacer()
                
                if currentStep < visualizationSteps.count {
                    let step = visualizationSteps[currentStep]
                    
                    VStack(spacing: 32) {
                        // Icon with breathing animation
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.teal.opacity(0.3),
                                            Color.teal.opacity(0.0)
                                        ],
                                        center: .center,
                                        startRadius: 50,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .scaleEffect(breathScale)
                            
                            Circle()
                                .fill(Color.teal.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .scaleEffect(breathScale)
                            
                            Image(systemName: step.icon)
                                .font(.system(size: 50))
                                .foregroundStyle(Color.teal)
                        }
                        
                        // Step content
                        VStack(spacing: 16) {
                            Text(step.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.textPrimary)
                            
                            Text(step.prompt)
                                .font(.body)
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        if isPlaying {
                            Text("Take your time...")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary.opacity(0.7))
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                } else {
                    completionView
                }
                
                Spacer()
                
                // Controls
                VStack(spacing: 16) {
                    if !isPlaying && currentStep < visualizationSteps.count {
                        Button(action: startVisualization) {
                            Text("Begin Journey")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.teal)
                                )
                        }
                        .padding(.horizontal, 24)
                        .buttonStyle(.plain)
                    } else if isPlaying {
                        Button(action: nextStep) {
                            Text(currentStep == visualizationSteps.count - 1 ? "Complete" : "Next")
                                .font(.headline)
                                .foregroundStyle(Color.teal)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.teal, lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, 24)
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onDisappear {
            isPlaying = false
            breathScale = 1.0
        }
        .enableInjection()
    }
    
    private var completionView: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.teal)
            
            VStack(spacing: 12) {
                Text("Journey Complete")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                
                Text("You can return to your safe place anytime")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 12) {
                Image("panda_happy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                
                Text("Carry this feeling of peace with you throughout your day.")
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
    }
    
    private func startVisualization() {
        isPlaying = true
        startBreathingAnimation()
    }
    
    private func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            breathScale = 1.15
        }
    }
    
    private func nextStep() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation {
            if currentStep < visualizationSteps.count - 1 {
                currentStep += 1
            } else {
                currentStep = visualizationSteps.count
                isPlaying = false
            }
        }
    }
    
}

struct VisualizationStep {
    let icon: String
    let title: String
    let prompt: String
}

#Preview {
    SafePlaceView(duration: 4) {
        print("Visualization completed")
    }
}
