import SwiftUI
import SwiftData
import Inject

struct WorryTreeView: View {
    @ObserveInjection var inject
    
    let onComplete: () -> Void
    
    @State private var showIntro: Bool = true
    @State private var showContent: Bool = false
    @State private var currentStep: WorryTreeStep = .identify
    @State private var worryText: String = ""
    @State private var canControl: Bool? = nil
    @State private var actionPlan: String = ""
    @State private var letGoReason: String = ""
    @State private var showHistory: Bool = false
    @State private var pandaFeedback: String? = nil
    @State private var isLoadingPanda: Bool = false
    @State private var hasRequestedPanda: Bool = false
    @State private var currentEntry: WorryTreeEntry? = nil
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorryTreeEntry.date, order: .reverse) private var previousEntries: [WorryTreeEntry]
    @Environment(\.dismiss) private var dismiss
    @State private var showInfoSheet: Bool = false
    
    // Animation states for thinking animation
    @State private var breatheScale: CGFloat = 1.0
    @State private var ringRotation: Double = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.backgroundCream,
                    Color.orange.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showIntro {
                worryTreeIntroView
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Progress indicator at top
                        HStack(spacing: 12) {
                            ForEach(WorryTreeStep.allCases, id: \.self) { step in
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(step.rawValue <= currentStep.rawValue ? Color.orange : Color.borderColor.opacity(0.5))
                                            .frame(width: 10, height: 10)
                                        
                                        if step.rawValue == currentStep.rawValue {
                                            Circle()
                                                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                                                .frame(width: 18, height: 18)
                                        }
                                    }
                                    .frame(width: 20, height: 20)
                                    
                                    if step.rawValue < WorryTreeStep.allCases.count - 1 {
                                        Rectangle()
                                            .fill(step.rawValue < currentStep.rawValue ? Color.orange : Color.borderColor.opacity(0.3))
                                            .frame(width: 24, height: 2)
                                            .offset(x: 18)
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
                        
                        // Current step content
                        stepContent
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, showPrimaryBottomButton ? 140 : 40)
                }
                .safeAreaInset(edge: .bottom) {
                    if showPrimaryBottomButton {
                        VStack(spacing: 0) {
                            primaryBottomButton
                                .padding(.horizontal, 24)
                                .padding(.bottom, 20)
                                .padding(.top, 12)
                        }
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.backgroundCream.opacity(0),
                                    Color.backgroundCream
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .sheet(isPresented: $showHistory) {
            WorryTreeHistoryView(entries: previousEntries)
        }
        .sheet(isPresented: $showInfoSheet) {
            worryTreeInfoSheet
        }
        .enableInjection()
    }
    
    // MARK: - Intro View
    
    private var worryTreeIntroView: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Icon with glow - properly sized
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.orange.opacity(0.2),
                                        Color.orange.opacity(0.05),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "tree.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.top, geometry.safeAreaInsets.top > 50 ? 20 : 12)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.8)
                    
                    // Title and description
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Text("Worry Tree")
                                .font(.system(size: 26, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textPrimary)
                            
                            Button {
                                showInfoSheet = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundStyle(Color.orange.opacity(0.9))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text("A structured way to process worries\nand decide what to do with them")
                            .font(.body)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    
                    // How it works
                    VStack(alignment: .leading, spacing: 14) {
                        Text("How it works")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                        
                        WorryTreeHowItWorksRow(number: 1, text: "Name the worry that's on your mind")
                        WorryTreeHowItWorksRow(number: 2, text: "Decide if you can do something about it")
                        WorryTreeHowItWorksRow(number: 3, text: "Make a plan or practice letting go")
                        WorryTreeHowItWorksRow(number: 4, text: "Get a gentle reflection from Bumblebee")
                    }
                    .padding(18)
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
                            .frame(width: 40, height: 40)
                        
                        Text("Worries are normal. Let's sort through this one together and find some clarity.")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.cardBackground.opacity(0.8))
                    )
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 40)
                    
                    // Previous worries button (centered)
                    Button(action: { showHistory = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 14, weight: .medium))
                            Text("View Previous Worries")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 24)
                    .padding(.top, 4)
                    
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
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.orange)
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .buttonStyle(.plain)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .identify:
            identifyWorryView
        case .canControl:
            canControlView
        case .actionable:
            actionableView
        case .letGo:
            letGoView
        case .complete:
            completionView
        }
    }

    // MARK: - Persistence & Panda

    private func saveEntry() {
        let entry = WorryTreeEntry(
            worryText: worryText,
            canControl: canControl,
            actionPlan: actionPlan.isEmpty ? nil : actionPlan,
            letGoNote: letGoReason.isEmpty ? nil : letGoReason,
            pandaFeedback: pandaFeedback
        )
        modelContext.insert(entry)
        currentEntry = entry
    }

    @MainActor
    private func generatePandaFeedbackIfNeeded() async {
        guard !hasRequestedPanda else { return }
        guard !worryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        hasRequestedPanda = true
        isLoadingPanda = true
        defer { isLoadingPanda = false }

        let historySummary = previousEntries.prefix(5).map { entry in
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            let dateString = formatter.string(from: entry.date)
            let snippet = entry.worryText.prefix(140)
            return "- [\(dateString)] \(snippet)"
        }.joined(separator: "\n")

        let result = await PandaWorryTreeService.shared.generate(
            worryText: worryText,
            canControl: canControl,
            actionPlan: actionPlan.isEmpty ? nil : actionPlan,
            letGoNote: letGoReason.isEmpty ? nil : letGoReason,
            historySummary: historySummary
        )

        pandaFeedback = result.text
        currentEntry?.pandaFeedback = result.text
    }
    
    private var identifyWorryView: some View {
        VStack(spacing: 20) {
            // Compact header with icon
            HStack(spacing: 12) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.orange.opacity(0.8))
                
                Text("What's worrying you?")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(.top, 8)
            
            // Text entry with placeholder
            ZStack(alignment: .topLeading) {
                TextEditor(text: $worryText)
                    .font(.body)
                    .padding(14)
                    .frame(minHeight: 140)
                    .scrollContentBackground(.hidden)
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(worryText.isEmpty ? Color.borderColor : Color.orange.opacity(0.5), lineWidth: 1.5)
                    )
                    .onChange(of: worryText) { _, newValue in
                        guard currentStep == .identify, newValue.last == "\n" else { return }
                        worryText = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if primaryBottomButtonEnabled {
                            handlePrimaryBottomButtonTap()
                        }
                    }
                
                if worryText.isEmpty {
                    Text("Describe what's on your mind...")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary.opacity(0.6))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 22)
                        .allowsHitTesting(false)
                }
            }
            
            // Gentle encouragement
            HStack(spacing: 10) {
                Image("panda_supportive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                
                Text("Take your time. There's no right or wrong way to express this.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground.opacity(0.7))
            )
        }
    }
    
    private var canControlView: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.orange.opacity(0.8))
                
                Text("Can you take action?")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(.top, 8)
            
            // Show the worry they entered
            VStack(alignment: .leading, spacing: 8) {
                Text("Your worry:")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.textSecondary)
                
                Text(worryText)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBackground)
                    .cornerRadius(12)
            }
            
            Text("Is there something you can do about this right now?")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Button(action: {
                    canControl = true
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .actionable
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("Yes, I can do something")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primaryGreen)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    canControl = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .letGo
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 20))
                        Text("No, it's outside my control")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var actionableView: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "list.clipboard.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.primaryGreen.opacity(0.8))
                
                Text("What's your plan?")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(.top, 8)
            
            // Text entry with placeholder
            ZStack(alignment: .topLeading) {
                TextEditor(text: $actionPlan)
                    .font(.body)
                    .padding(14)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(actionPlan.isEmpty ? Color.borderColor : Color.primaryGreen.opacity(0.5), lineWidth: 1.5)
                    )
                    .onChange(of: actionPlan) { _, newValue in
                        guard currentStep == .actionable, newValue.last == "\n" else { return }
                        actionPlan = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if primaryBottomButtonEnabled {
                            handlePrimaryBottomButtonTap()
                        }
                    }
                
                if actionPlan.isEmpty {
                    Text("What small steps can you take?")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary.opacity(0.6))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 22)
                        .allowsHitTesting(false)
                }
            }
            
            // Tips
            VStack(alignment: .leading, spacing: 10) {
                Text("Quick tips:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                
                VStack(alignment: .leading, spacing: 6) {
                    bulletPoint("Start with the smallest possible step")
                    bulletPoint("Be specific about what and when")
                    bulletPoint("Focus on what you can control")
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground.opacity(0.7))
            )
        }
    }
    
    private var letGoView: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.blue.opacity(0.8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Let it go")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("This is outside your control")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.top, 8)
            
            // Acceptance message
            Text("That's okay. Recognizing what you can't control is wisdom, not weakness.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            
            // Text entry with placeholder
            ZStack(alignment: .topLeading) {
                TextEditor(text: $letGoReason)
                    .font(.body)
                    .padding(14)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(letGoReason.isEmpty ? Color.borderColor : Color.blue.opacity(0.5), lineWidth: 1.5)
                    )
                    .onChange(of: letGoReason) { _, newValue in
                        guard currentStep == .letGo, newValue.last == "\n" else { return }
                        letGoReason = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if primaryBottomButtonEnabled {
                            handlePrimaryBottomButtonTap()
                        }
                    }
                
                if letGoReason.isEmpty {
                    Text("What helps you accept and release this?")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary.opacity(0.6))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 22)
                        .allowsHitTesting(false)
                }
            }
            
            // Tips
            VStack(alignment: .leading, spacing: 10) {
                Text("Ways to let go:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textSecondary)
                
                VStack(alignment: .leading, spacing: 6) {
                    bulletPoint("Focus on what you can control")
                    bulletPoint("Practice self-compassion")
                    bulletPoint("Return to the present moment")
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground.opacity(0.7))
            )
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 20) {
            if isLoadingPanda {
                // Bumblebee thinking animation
                thinkingAnimationView
            } else {
                // Completion content
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.primaryGreen)
                .padding(.top, 8)
            
            VStack(spacing: 10) {
                Text("Well Done!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                
                if canControl == true {
                    Text("You have a plan to address your worry")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("You've acknowledged and released your worry")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image("panda_happy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    
                    Text("Bumblebee's suggestion")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textSecondary)
                }
                
                if let feedback = pandaFeedback {
                    Text(cleanedPandaFeedback(feedback))
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("Remember: It's okay to have worries. What matters is how you respond to them.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.leading)
                }
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
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primaryGreen)
                    )
            }
            .padding(.horizontal, 24)
            .buttonStyle(.plain)
            .padding(.bottom, 8)
            }
        }
        .padding(.top, 24)
        .task {
            await generatePandaFeedbackIfNeeded()
        }
    }
    
    // MARK: - Thinking Animation View
    
    private var thinkingAnimationView: some View {
        VStack(spacing: 24) {
            // Animated mascot with glow
            ZStack {
                // Outer pulsing glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.orange.opacity(0.2),
                                Color.orange.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(breatheScale)
                
                // Rotating ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.orange.opacity(0.4),
                                Color.orange.opacity(0.1),
                                Color.orange.opacity(0.4)
                            ],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(ringRotation))
                
                // Mascot
                GardenMascot(emotion: .thinking, size: 120)
            }
            .onAppear {
                startThinkingAnimations()
            }
            .onDisappear {
                stopThinkingAnimations()
            }
            
            // Status text
            VStack(spacing: 8) {
                Text("Bumblebee is thinking...")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                
                Text("Creating a personalized suggestion for you")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 40)
    }
    
    private func startThinkingAnimations() {
        // Breathing animation
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            breatheScale = 1.08
        }
        
        // Ring rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
    }
    
    private func stopThinkingAnimations() {
        breatheScale = 1.0
        ringRotation = 0
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(Color.textSecondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Primary Bottom Button

    private var showPrimaryBottomButton: Bool {
        switch currentStep {
        case .identify, .actionable, .letGo:
            return true
        default:
            return false
        }
    }

    private var primaryBottomButtonTitle: String {
        switch currentStep {
        case .identify:
            return "Continue"
        case .actionable:
            return "Done"
        case .letGo:
            return "Release This Worry"
        default:
            return ""
        }
    }

    private var primaryBottomButtonEnabled: Bool {
        switch currentStep {
        case .identify:
            return !worryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .actionable:
            return !actionPlan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .letGo:
            return !letGoReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return false
        }
    }

    private var primaryBottomButton: some View {
        Button(action: handlePrimaryBottomButtonTap) {
            Text(primaryBottomButtonTitle)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(primaryBottomButtonEnabled ? Color.orange : Color.gray.opacity(0.5))
                )
        }
        .disabled(!primaryBottomButtonEnabled)
        .buttonStyle(.plain)
    }

    private func handlePrimaryBottomButtonTap() {
        guard primaryBottomButtonEnabled else { return }
        
        // Dismiss keyboard immediately before transitioning
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Small delay to let keyboard start dismissing before animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            switch currentStep {
            case .identify:
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentStep = .canControl
                }
            case .actionable:
                saveEntry()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentStep = .complete
                }
            case .letGo:
                saveEntry()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentStep = .complete
                }
            default:
                break
            }
        }
    }

    private var stepDescription: String {
        switch currentStep {
        case .identify:
            return "Name the worry that's on your mind"
        case .canControl:
            return "Decide if you can take action"
        case .actionable:
            return "Create a plan to address it"
        case .letGo:
            return "Practice acceptance and release"
        case .complete:
            return "You've processed your worry"
        }
    }

    // MARK: - Science Sheet

    private var worryTreeInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Why this exercise helps")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)

                    Text("The Worry Tree is a cognitive-behavioral tool that helps you sort worries into two groups: things you can do something about and things you can’t control. Walking through clear questions reduces rumination and nudges you toward either a small action plan or a conscious decision to let go.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("CBT programs for generalized anxiety often include step-by-step worry flowcharts like this one. Studies show that learning to postpone, problem-solve, or release chronic worry can lower anxiety symptoms and make worries feel more manageable in daily life.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)

                        if let url = URL(string: "https://www.getselfhelp.co.uk/worry-tree/") {
                            Link("Getselfhelp.co.uk – CBT Worry Tree worksheet and rationale", destination: url)
                                .font(.subheadline)
                                .foregroundStyle(Color.orange)
                                .buttonStyle(.plain)
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
                    .foregroundStyle(Color.orange)
                }
            }
        }
    }
}

fileprivate func cleanedPandaFeedback(_ text: String) -> String {
    // Trim whitespace/newlines and collapse excessive blank lines so Panda's
    // suggestions read cleanly in the UI.
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

    // Replace runs of 3+ newlines with just 2 to avoid huge gaps.
    let collapsed = trimmed.replacingOccurrences(
        of: "\n{3,}",
        with: "\n\n",
        options: .regularExpression
    )

    return collapsed
}

enum WorryTreeStep: Int, CaseIterable {
    case identify = 0
    case canControl = 1
    case actionable = 2
    case letGo = 3
    case complete = 4
}

struct WorryTreeHistoryView: View {
    let entries: [WorryTreeEntry]
    
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Warm gradient background matching Worry Tree
                LinearGradient(
                    colors: [
                        Color.backgroundCream,
                        Color.orange.opacity(0.08),
                        Color.backgroundCream
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with tree icon
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color.orange.opacity(0.15),
                                                Color.orange.opacity(0.05),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 20,
                                            endRadius: 60
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "tree.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.orange, Color.orange.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.8)
                            
                            VStack(spacing: 6) {
                                Text("Your Worry Journal")
                                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.textPrimary)
                                
                                Text("\(entries.count) \(entries.count == 1 ? "worry" : "worries") processed")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 10)
                        }
                        .padding(.top, 20)
                        
                        if entries.isEmpty {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.orange.opacity(0.5))
                                
                                Text("No worries yet")
                                    .font(.headline)
                                    .foregroundStyle(Color.textPrimary)
                                
                                Text("Each time you complete a Worry Tree, your journey will be saved here for reflection.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .padding(.vertical, 40)
                            .opacity(showContent ? 1 : 0)
                        } else {
                            // Worry entries list
                            LazyVStack(spacing: 12) {
                                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                    NavigationLink {
                                        WorryTreeHistoryDetailView(entry: entry)
                                    } label: {
                                        WorryEntryCard(entry: entry)
                                    }
                                    .buttonStyle(.plain)
                                    .opacity(showContent ? 1 : 0)
                                    .offset(y: showContent ? 0 : 20)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05), value: showContent)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.orange)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }
}

// MARK: - Worry Entry Card

struct WorryEntryCard: View {
    let entry: WorryTreeEntry
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }
    
    private var statusInfo: (icon: String, color: Color, text: String) {
        if entry.canControl == true {
            return ("checkmark.circle.fill", .green, "Action planned")
        } else {
            return ("leaf.fill", .blue, "Released")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date and status row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: statusInfo.icon)
                        .font(.system(size: 12))
                    Text(statusInfo.text)
                        .font(.caption)
                }
                .foregroundStyle(statusInfo.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(statusInfo.color.opacity(0.12))
                )
            }
            
            // Worry text
            Text(entry.worryText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Bottom row with chevron
            HStack {
                if entry.pandaFeedback != nil {
                    HStack(spacing: 4) {
                        Image("panda_happy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        
                        Text("Bumblebee helped")
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textSecondary.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        )
    }
}

struct WorryTreeHistoryDetailView: View {
    let entry: WorryTreeEntry
    
    @State private var showContent = false
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }
    
    private var statusInfo: (icon: String, color: Color, text: String, description: String) {
        if entry.canControl == true {
            return ("checkmark.circle.fill", .green, "Action Planned", "You identified steps to address this worry")
        } else {
            return ("leaf.fill", .blue, "Released", "You chose to let go of what you can't control")
        }
    }
    
    var body: some View {
        ZStack {
            // Warm gradient background
            LinearGradient(
                colors: [
                    Color.backgroundCream,
                    statusInfo.color.opacity(0.06),
                    Color.backgroundCream
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Status header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            statusInfo.color.opacity(0.2),
                                            statusInfo.color.opacity(0.05),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 15,
                                        endRadius: 50
                                    )
                                )
                                .frame(width: 90, height: 90)
                            
                            Image(systemName: statusInfo.icon)
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(statusInfo.color)
                        }
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.8)
                        
                        VStack(spacing: 6) {
                            Text(statusInfo.text)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textPrimary)
                            
                            Text(formattedDate)
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                    }
                    .padding(.top, 20)
                    
                    // Content cards
                    VStack(spacing: 16) {
                        // The Worry
                        DetailCard(
                            icon: "cloud.fill",
                            iconColor: .orange,
                            title: "The Worry",
                            content: entry.worryText
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: showContent)
                        
                        // Action Plan or Let Go Note
                        if let plan = entry.actionPlan, !plan.isEmpty {
                            DetailCard(
                                icon: "list.clipboard.fill",
                                iconColor: .green,
                                title: "Your Action Plan",
                                content: plan
                            )
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: showContent)
                        }
                        
                        if let letGo = entry.letGoNote, !letGo.isEmpty {
                            DetailCard(
                                icon: "leaf.fill",
                                iconColor: .blue,
                                title: "What Helped You Let Go",
                                content: letGo
                            )
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: showContent)
                        }
                        
                        // Panda's Suggestion
                        if let feedback = entry.pandaFeedback, !feedback.isEmpty {
                            PandaSuggestionCard(feedback: cleanedPandaFeedback(feedback))
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: showContent)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Reflection prompt
                    VStack(spacing: 12) {
                        Text("Reflection")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textSecondary)
                        
                        Text(reflectionPrompt)
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 20)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: showContent)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }
    
    private var reflectionPrompt: String {
        if entry.canControl == true {
            return "How did taking action help you feel more in control?"
        } else {
            return "Remember: letting go is a practice, not a one-time event. Be gentle with yourself."
        }
    }
}

// MARK: - Detail Card Component

struct DetailCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            
            Text(content)
                .font(.system(size: 16))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        )
    }
}

// MARK: - Panda Suggestion Card

struct PandaSuggestionCard: View {
    let feedback: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image("panda_happy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bumblebee's Suggestion")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("A gentle reminder for you")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            
            Text(feedback)
                .font(.system(size: 15))
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cardBackground,
                            Color.orange.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Worry Tree How It Works Row

struct WorryTreeHowItWorksRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.orange)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
        }
    }
}

#Preview {
    WorryTreeView {
        print("Worry tree completed")
    }
}
