import SwiftUI
import Inject

struct BodyScanView: View {
    @ObserveInjection var inject

    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var isInstructionPhase = true // Tense or release
    @State private var progress: CGFloat = 0
    @State private var countdown: Int = 7 // Live countdown timer
    @State private var phaseColor: Color = Color(red: 0.60, green: 0.52, blue: 0.92)
    
    // Lavender accent color for body scan theme
    private let lavenderAccent = Color(red: 0.60, green: 0.52, blue: 0.92)
    @State private var hasStarted = false
    @State private var showInfoSheet = false
    @Environment(\.dismiss) private var dismiss
    
    // Animation states
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var ringRotation: Double = 0
    @State private var particleOffset: CGFloat = 0
    @State private var bodyHighlightY: CGFloat = 0
    @State private var phaseTransition: Bool = false

    private let bodyParts: [BodyPart] = [
        BodyPart(name: "Feet & Toes", icon: "figure.walk", position: .bottom, highlightY: 0.85),
        BodyPart(name: "Legs", icon: "figure.walk", position: .lower, highlightY: 0.7),
        BodyPart(name: "Hips & Glutes", icon: "figure.stand", position: .middle, highlightY: 0.55),
        BodyPart(name: "Stomach", icon: "figure.stand", position: .middle, highlightY: 0.45),
        BodyPart(name: "Chest & Back", icon: "figure.stand", position: .upper, highlightY: 0.42),
        BodyPart(name: "Hands & Arms", icon: "hand.raised.fill", position: .upper, highlightY: 0.50),
        BodyPart(name: "Shoulders", icon: "figure.stand", position: .upper, highlightY: 0.32),
        BodyPart(name: "Neck", icon: "figure.stand", position: .top, highlightY: 0.28),
        BodyPart(name: "Face", icon: "face.smiling", position: .top, highlightY: 0.26)
    ]

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground(
                phase: isInstructionPhase ? .tense : .release,
                progress: CGFloat(countdown) / 7.0
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with title and info button
                VStack(spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        Spacer()
                        
                        Text("Muscle Relaxation")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.textPrimary)

                        Button {
                            showInfoSheet = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(Color.textSecondary.opacity(0.8))
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }

                    Text("Progressive muscle relaxation")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    
                    if hasStarted && currentStep < bodyParts.count {
                        // Animated step indicator
                        HStack(spacing: 4) {
                            ForEach(0..<bodyParts.count, id: \.self) { index in
                                Capsule()
                                    .fill(index <= currentStep ? phaseColor : Color.textSecondary.opacity(0.2))
                                    .frame(width: index == currentStep ? 20 : 8, height: 4)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStep)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 24)

                if !hasStarted {
                    introView
                } else if currentStep < bodyParts.count {
                    let bodyPart = bodyParts[currentStep]
                    
                    // Main visualization area
                    ZStack {
                        // Human silhouette with highlight
                        BodySilhouetteView(
                            highlightY: bodyPart.highlightY,
                            highlightColor: phaseColor,
                            isTensing: isInstructionPhase,
                            pulseScale: pulseScale
                        )
                        .frame(height: 280)
                        .padding(.horizontal, 60)
                        
                        // Floating particles during release
                        if !isInstructionPhase {
                            FloatingParticlesView(color: phaseColor)
                                .opacity(0.6)
                        }
                    }
                    .padding(.bottom, 16)

                    // Breathing ring with countdown
                    ZStack {
                        // Outer pulsing rings
                        ForEach(0..<3, id: \.self) { ring in
                            Circle()
                                .stroke(
                                    phaseColor.opacity(0.15 - Double(ring) * 0.05),
                                    lineWidth: 2
                                )
                                .frame(width: 140 + CGFloat(ring) * 30, height: 140 + CGFloat(ring) * 30)
                                .scaleEffect(pulseScale + CGFloat(ring) * 0.05)
                        }
                        
                        // Main countdown ring
                        Circle()
                            .stroke(Color.textSecondary.opacity(0.1), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(countdown) / 7.0)
                            .stroke(
                                AngularGradient(
                                    colors: [phaseColor, phaseColor.opacity(0.5)],
                                    center: .center,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(270)
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.8), value: countdown)
                        
                        // Countdown number
                        Text("\(countdown)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(phaseColor)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: countdown)
                    }
                    .padding(.vertical, 20)

                    // Instructions card
                    VStack(spacing: 12) {
                        Text(bodyPart.name)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.textPrimary)
                            .id("name-\(currentStep)")
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))

                        HStack(spacing: 8) {
                            Image(systemName: isInstructionPhase ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(phaseColor)
                                .rotationEffect(.degrees(isInstructionPhase ? 0 : 180))
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isInstructionPhase)
                            
                            Text(currentInstructionBase)
                                .font(.body)
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(phaseColor.opacity(0.1))
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                } else {
                    completionView
                }
            }
        }
        .onChange(of: isInstructionPhase) { _, _ in
            startPulseAnimation()
        }
        .sheet(isPresented: $showInfoSheet) {
            muscleRelaxationInfoSheet
        }
        .enableInjection()
    }
    
    private func startPulseAnimation() {
        // Reset and start pulse
        pulseScale = 1.0
        withAnimation(
            .easeInOut(duration: isInstructionPhase ? 0.6 : 1.2)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = isInstructionPhase ? 1.15 : 0.95
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        CompletionCelebrationView(onComplete: {
            onComplete()
            dismiss()
        })
    }

    // MARK: - Intro View

    private var introView: some View {
        IntroAnimatedView(onStart: {
            hasStarted = true
            startBodyScan()
        })
    }

    // MARK: - Info Sheet

    private var muscleRelaxationInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Why this exercise helps")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)

                    Text("Progressive muscle relaxation asks you to gently tense and then release different muscle groups. This pattern sends a clear \"safety\" signal to your nervous system, lowering physical tension and helping the brain register calm.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("A 2023 systematic review of 46 studies (over 3,400 adults) found that progressive muscle relaxation can meaningfully reduce stress, anxiety, and depression when practiced regularly.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)

                        Link(
                            "Efficacy of Progressive Muscle Relaxation in Adults for Stress, Anxiety, and Depression: A Systematic Review",
                            destination: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC10844009/")!
                        )
                        .font(.subheadline)
                        .foregroundStyle(Color.primaryGreen)
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
                }
            }
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
        startPulseAnimation()
        performNextPhase()
    }

    private func performNextPhase() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Reset countdown
        countdown = 7
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
        // Smooth, calming color progression for 7-second countdown (lavender tones)
        withAnimation(.easeInOut(duration: 1.2)) {
            switch countdown {
            case 7, 6:
                // Deep lavender
                phaseColor = Color(red: 0.60, green: 0.52, blue: 0.92)
            case 5, 4:
                // Softer violet
                phaseColor = Color(red: 0.70, green: 0.58, blue: 0.96)
            case 3, 2:
                // Gentle lilac
                phaseColor = Color(red: 0.78, green: 0.64, blue: 0.97)
            case 1:
                // Very soft pastel purple
                phaseColor = Color(red: 0.86, green: 0.72, blue: 0.99)
            default:
                phaseColor = Color(red: 0.70, green: 0.58, blue: 0.96)
            }
        }
    }
}

// MARK: - Supporting Types

struct BodyPart {
    let name: String
    let icon: String
    let position: BodyPosition
    let highlightY: CGFloat // 0 = top, 1 = bottom
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

// MARK: - Animated Gradient Background

enum BodyScanPhase {
    case tense, release
}

struct AnimatedGradientBackground: View {
    let phase: BodyScanPhase
    let progress: CGFloat
    
    @State private var animateGradient = false
    
    // Lavender accent
    private let lavenderAccent = Color(red: 0.60, green: 0.52, blue: 0.92)
    
    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: animateGradient ? .topLeading : .top,
            endPoint: animateGradient ? .bottomTrailing : .bottom
        )
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
        .onAppear {
            animateGradient = true
        }
    }
    
    private var gradientColors: [Color] {
        // Dark mode compatible lavender theme
        switch phase {
        case .tense:
            return [
                Color(UIColor.systemBackground),
                Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(red: 0.18, green: 0.14, blue: 0.24, alpha: 1.0)
                        : UIColor(red: 0.96, green: 0.94, blue: 1.0, alpha: 1.0)
                }),
                lavenderAccent.opacity(0.08)
            ]
        case .release:
            return [
                Color(UIColor.systemBackground),
                Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(red: 0.14, green: 0.16, blue: 0.22, alpha: 1.0)
                        : UIColor(red: 0.94, green: 0.96, blue: 1.0, alpha: 1.0)
                }),
                Color(red: 0.70, green: 0.58, blue: 0.96).opacity(0.1)
            ]
        }
    }
}

// MARK: - Body Silhouette View

struct BodySilhouetteView: View {
    let highlightY: CGFloat
    let highlightColor: Color
    let isTensing: Bool
    let pulseScale: CGFloat
    
    @State private var glowAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base silhouette
                Image(systemName: "figure.stand")
                    .font(.system(size: 180, weight: .ultraLight))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.textSecondary.opacity(0.15),
                                Color.textSecondary.opacity(0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Highlight glow at body part
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                highlightColor.opacity(isTensing ? 0.6 : 0.4),
                                highlightColor.opacity(isTensing ? 0.3 : 0.15),
                                highlightColor.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: isTensing ? 50 : 70
                        )
                    )
                    .frame(width: isTensing ? 80 : 100, height: isTensing ? 80 : 100)
                    .scaleEffect(glowAnimation ? (isTensing ? 1.2 : 1.0) : (isTensing ? 1.0 : 0.9))
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * highlightY
                    )
                    .animation(.easeInOut(duration: isTensing ? 0.5 : 1.0).repeatForever(autoreverses: true), value: glowAnimation)
                
                // Pulsing ring around highlight
                Circle()
                    .stroke(highlightColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 60, height: 60)
                    .scaleEffect(pulseScale)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height * highlightY
                    )
            }
        }
        .onAppear {
            glowAnimation = true
        }
        .onChange(of: isTensing) { _, _ in
            glowAnimation = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                glowAnimation = true
            }
        }
    }
}

// MARK: - Floating Particles View

struct FloatingParticlesView: View {
    let color: Color
    
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(color.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .blur(radius: 1)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<12).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: size.height * 0.3...size.height * 0.8)
                ),
                size: CGFloat.random(in: 4...10),
                opacity: Double.random(in: 0.2...0.5)
            )
        }
    }
    
    private func animateParticles(in size: CGSize) {
        for index in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 2...4)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    particles[index].position.y -= CGFloat.random(in: 30...60)
                    particles[index].opacity = Double.random(in: 0.1...0.3)
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
}

// MARK: - Intro Animated View

struct IntroAnimatedView: View {
    let onStart: () -> Void
    
    // Lavender accent for body scan
    private let lavenderAccent = Color(red: 0.60, green: 0.52, blue: 0.92)
    private let lavenderLight = Color(red: 0.78, green: 0.64, blue: 0.97)
    
    @State private var showContent = false
    @State private var silhouetteGlow = false
    @State private var buttonPulse = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated body preview
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                lavenderAccent.opacity(0.25),
                                lavenderAccent.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(silhouetteGlow ? 1.2 : 1.0)
                
                // Body silhouette
                Image(systemName: "figure.stand")
                    .font(.system(size: 100, weight: .ultraLight))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                lavenderAccent.opacity(0.7),
                                lavenderLight.opacity(0.5)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Scanning line effect
                RoundedRectangle(cornerRadius: 2)
                    .fill(lavenderAccent.opacity(0.5))
                    .frame(width: 60, height: 4)
                    .offset(y: silhouetteGlow ? -50 : 50)
                    .blur(radius: 2)
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)
            .padding(.bottom, 8)
            
            // Panda card
            HStack(spacing: 12) {
                Image("panda_supportive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Why this helps")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)

                    Text("Body scans help you notice where you hold tension and gently teach your muscles how to let go.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            )
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            // What to expect
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundStyle(lavenderAccent)
                    Text("2–3 minutes")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14))
                        .foregroundStyle(lavenderAccent)
                    Text("Tense → Release each area")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "heart")
                        .font(.system(size: 14))
                        .foregroundStyle(lavenderAccent)
                    Text("Go at your own pace")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground.opacity(0.6))
            )
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)

            // Start button with pulse (lavender theme)
            Button(action: onStart) {
                HStack(spacing: 8) {
                    Text("Begin Relaxation")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(lavenderAccent)
                        
                        // Subtle pulse effect
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(lavenderAccent.opacity(0.5), lineWidth: 2)
                            .scaleEffect(buttonPulse ? 1.08 : 1.0)
                            .opacity(buttonPulse ? 0 : 0.5)
                    }
                )
            }
            .padding(.horizontal, 24)
            .buttonStyle(.plain)
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.95)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
            
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                silhouetteGlow = true
            }
            
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                buttonPulse = true
            }
        }
    }
}

// MARK: - Completion Celebration View

struct CompletionCelebrationView: View {
    let onComplete: () -> Void
    
    // Lavender accent for body scan
    private let lavenderAccent = Color(red: 0.60, green: 0.52, blue: 0.92)
    private let lavenderLight = Color(red: 0.78, green: 0.64, blue: 0.97)
    
    @State private var showContent = false
    @State private var celebrationScale: CGFloat = 0.5
    @State private var sparkleRotation: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var pandaOffset: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Celebration icon with animations (lavender theme)
            ZStack {
                // Outer expanding rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(
                            lavenderAccent.opacity(0.2 - Double(ring) * 0.06),
                            lineWidth: 2
                        )
                        .frame(width: 140 + CGFloat(ring) * 40, height: 140 + CGFloat(ring) * 40)
                        .scaleEffect(ringScale + CGFloat(ring) * 0.1)
                }
                
                // Main circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                lavenderAccent.opacity(0.3),
                                lavenderAccent.opacity(0.1),
                                lavenderAccent.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(celebrationScale)
                
                // Sparkles icon with rotation
                Image(systemName: "sparkles")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [lavenderAccent, lavenderLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(sparkleRotation))
                    .scaleEffect(celebrationScale)
            }
            .opacity(showContent ? 1 : 0)
            
            VStack(spacing: 12) {
                Text("Relaxation Complete")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                
                Text("Your body is relaxed and at ease")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            // Panda message
            HStack(spacing: 12) {
                Image("panda_supportive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                
                Text("Notice how calm your body feels now. You can carry this feeling with you.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
            )
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)
            .offset(y: pandaOffset)
            
            Spacer()
            
            Button(action: onComplete) {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(lavenderAccent)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .buttonStyle(.plain)
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.9)
        }
        .onAppear {
            // Staggered entrance animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
                celebrationScale = 1.0
            }
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                pandaOffset = 0
            }
            
            // Continuous animations
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                ringScale = 1.1
            }
            
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
        }
    }
}

#Preview {
    BodyScanView {
        print("Body scan completed")
    }
}
