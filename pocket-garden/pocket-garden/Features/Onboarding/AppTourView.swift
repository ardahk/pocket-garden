import SwiftUI

// MARK: - Tour Prompt (Bumblebee asks if user wants a tour)

struct AppTourPromptView: View {
    @DevObserveInjection var inject: DevInjectionToken
    
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    @State private var mascotFloat: CGFloat = 0
    @State private var cardOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.9
    
    var body: some View {
        ZStack {
            // Strong dimmed background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { }
            
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                // Bumblebee mascot
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.accentGold.opacity(0.25),
                                    Color.accentGold.opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)
                    
                    Image("panda_welcome")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 130)
                        .offset(y: mascotFloat)
                }
                
                // Short speech
                VStack(spacing: Spacing.md) {
                    Text("Hey! Want a quick tour?")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("I'll show you around in 30 seconds.")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Buttons
                VStack(spacing: Spacing.md) {
                    Button(action: {
                        Theme.Haptics.medium()
                        onAccept()
                    }) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 15, weight: .medium))
                            Text("Show me around")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.primaryGreen)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        Theme.Haptics.light()
                        onDecline()
                    }) {
                        Text("No thanks, I'll explore")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.vertical, Spacing.sm)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Spacing.xxl)
                
                Spacer()
            }
            .opacity(cardOpacity)
            .scaleEffect(cardScale)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                mascotFloat = -8
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                cardOpacity = 1.0
                cardScale = 1.0
            }
        }
        .devEnableInjection()
    }
}

// MARK: - Interactive Tour Overlay (sits on top of real app)

struct AppTourOverlay: View {
    @DevObserveInjection var inject: DevInjectionToken
    
    @Binding var tourSelectedTab: Int?
    let onComplete: () -> Void
    
    @State private var currentStep = 0
    @State private var mascotFloat: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.9
    @State private var dimAmount: Double = 0.85
    @State private var isPeeking = false
    
    private let totalSteps = 4
    
    private var stepData: TourStepData {
        switch currentStep {
        case 0:
            return TourStepData(
                tab: 0,
                mascotImage: "panda_welcome",
                title: "Your Home",
                message: "This is where it all starts! Check in daily — rate your mood, then speak or type how you feel.",
                buttonText: "Next",
                accentColor: .primaryGreen,
                tabName: "Home"
            )
        case 1:
            return TourStepData(
                tab: 1,
                mascotImage: "panda_happy",
                title: "Your Forest",
                message: "Each journal entry grows a tree. Watch your forest fill up over time!",
                buttonText: "Next",
                accentColor: .primaryGreen,
                tabName: "Garden"
            )
        case 2:
            return TourStepData(
                tab: 2,
                mascotImage: "panda_sleep",
                title: "Your Sanctuary",
                message: "A calm space with breathing exercises, grounding, affirmations, and more.",
                buttonText: "Next",
                accentColor: .emotionCalm,
                tabName: "Sanctuary"
            )
        default:
            return TourStepData(
                tab: 0,
                mascotImage: "panda_happy",
                title: "You're Ready!",
                message: "I'll be here after each entry with a reflection just for you. Let's grow together!",
                buttonText: "Let's go!",
                accentColor: .accentGold,
                tabName: "Home"
            )
        }
    }
    
    var body: some View {
        let data = stepData
        
        ZStack {
            // Strong dimming overlay — blocks underlying content
            Color.black.opacity(dimAmount)
                .ignoresSafeArea()
                .allowsHitTesting(true)
            
            VStack(spacing: 0) {
                // Top bar: progress dots + skip
                HStack {
                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<totalSteps, id: \.self) { index in
                            Circle()
                                .fill(index <= currentStep ? data.accentColor : Color.white.opacity(0.3))
                                .frame(width: index == currentStep ? 10 : 8, height: index == currentStep ? 10 : 8)
                                .animation(.spring(response: 0.3), value: currentStep)
                        }
                    }
                    
                    Spacer()
                    
                    if currentStep < totalSteps - 1 {
                        Button(action: {
                            Theme.Haptics.light()
                            onComplete()
                        }) {
                            Text("Skip")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, Spacing.lg)
                
                Spacer()
                
                // Centered content block: mascot + bubble + button
                VStack(spacing: Spacing.lg) {
                    // Bumblebee mascot
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        data.accentColor.opacity(0.3),
                                        data.accentColor.opacity(0.05),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 90
                                )
                            )
                            .frame(width: 180, height: 180)
                        
                        Image(data.mascotImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .offset(y: mascotFloat)
                    }
                    
                    // Tab label (shows which screen we're on)
                    if currentStep < totalSteps - 1 {
                        HStack(spacing: 6) {
                            Image(systemName: tabIcon(for: data.tab))
                                .font(.system(size: 12, weight: .semibold))
                            Text(data.tabName)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(data.accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(data.accentColor.opacity(0.15))
                        )
                    }
                    
                    // Speech bubble
                    VStack(spacing: Spacing.sm) {
                        Text(data.title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(data.message)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, Spacing.xl)
                    
                    // Peek button — briefly reveals the tab behind
                    if currentStep < totalSteps - 1 {
                        Button(action: {
                            peekAtTab()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "eye")
                                    .font(.system(size: 13, weight: .medium))
                                Text("Peek at \(data.tabName)")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Action button
                    Button(action: {
                        advanceStep()
                    }) {
                        HStack(spacing: Spacing.sm) {
                            Text(data.buttonText)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                            if currentStep < totalSteps - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(data.accentColor)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.xxl)
                }
                .opacity(contentOpacity)
                .scaleEffect(contentScale)
                
                Spacer()
                
                // Step counter
                Text("\(currentStep + 1) / \(totalSteps)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, Spacing.xxl)
                    .opacity(contentOpacity)
            }
        }
        .onAppear {
            tourSelectedTab = 0
            showStep()
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                mascotFloat = -8
            }
        }
        .devEnableInjection()
    }
    
    // MARK: - Helpers
    
    private func tabIcon(for tab: Int) -> String {
        switch tab {
        case 0: return "house.fill"
        case 1: return "leaf.fill"
        case 2: return "moon.stars.fill"
        default: return "house.fill"
        }
    }
    
    private func peekAtTab() {
        guard !isPeeking else { return }
        isPeeking = true
        Theme.Haptics.light()
        
        // Fade out content, reduce dimming
        withAnimation(.easeOut(duration: 0.3)) {
            contentOpacity = 0
            dimAmount = 0.15
        }
        
        // Hold peek for 1.5s, then restore
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.3)) {
                dimAmount = 0.85
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.15)) {
                contentOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPeeking = false
            }
        }
    }
    
    // MARK: - Navigation
    
    private func advanceStep() {
        Theme.Haptics.medium()
        
        if currentStep >= totalSteps - 1 {
            onComplete()
            return
        }
        
        // Animate out
        withAnimation(.easeOut(duration: 0.2)) {
            contentOpacity = 0
            contentScale = 0.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentStep += 1
            
            // Switch tab
            tourSelectedTab = stepData.tab
            
            // Animate in new content
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showStep()
            }
        }
    }
    
    private func showStep() {
        contentOpacity = 0
        contentScale = 0.9
        dimAmount = 0.85
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05)) {
            contentOpacity = 1.0
            contentScale = 1.0
        }
    }
}

// MARK: - Tour Step Data

private struct TourStepData {
    let tab: Int
    let mascotImage: String
    let title: String
    let message: String
    let buttonText: String
    let accentColor: Color
    let tabName: String
}
