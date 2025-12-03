import SwiftUI
import Inject

// MARK: - Step Enum

enum ThreeGoodMomentsStep: Int, CaseIterable {
    case intro = 0
    case moment1 = 1
    case moment2 = 2
    case moment3 = 3
    case savor = 4
    case reflection = 5
    case complete = 6
}

struct ThreeGoodMomentsView: View {
    @ObserveInjection var inject

    let duration: Int
    let onComplete: () -> Void

    @State private var currentStep: ThreeGoodMomentsStep = .intro
    @State private var moments: [String] = ["", "", ""]
    @State private var savorIndex: Int = 0
    @State private var savorDetail: String = ""
    @State private var savorFeeling: String = ""
    
    @State private var pandaText: String? = nil
    @State private var isGeneratingPanda: Bool = false
    @State private var usedAFM: Bool = false
    @State private var showContent = false

    @Environment(\.dismiss) private var dismiss

    private var nonEmptyMoments: [String] {
        moments.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    
    private var currentMomentIndex: Int {
        switch currentStep {
        case .moment1: return 0
        case .moment2: return 1
        case .moment3: return 2
        default: return 0
        }
    }
    
    private var progressValue: CGFloat {
        CGFloat(currentStep.rawValue) / CGFloat(ThreeGoodMomentsStep.allCases.count - 1)
    }

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedMomentsBackground(step: currentStep)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar (hidden on intro and complete)
                if currentStep != .intro && currentStep != .complete {
                    progressBar
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                }
                
                // Content
                ScrollView(showsIndicators: false) {
                    stepContent
                        .padding(.horizontal, 24)
                        .padding(.top, currentStep == .intro ? 60 : 32)
                        .padding(.bottom, 120)
                }
                
                Spacer()
            }
            
            // Bottom button
            VStack {
                Spacer()
                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .enableInjection()
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primaryGreen.opacity(0.15))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primaryGreen)
                    .frame(width: geometry.size.width * progressValue, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progressValue)
            }
        }
        .frame(height: 6)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .intro:
            introView
        case .moment1, .moment2, .moment3:
            momentInputView
        case .savor:
            savorView
        case .reflection:
            reflectionView
        case .complete:
            completionView
        }
    }
    
    // MARK: - Intro View
    
    private var introView: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.primaryGreen.opacity(0.2),
                                Color.primaryGreen.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.primaryGreen, Color.mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)
            
            VStack(spacing: 12) {
                Text("Three Good Moments")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                
                Text("A simple practice to train your brain to notice the good, even on hard days")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            // How it works
            VStack(alignment: .leading, spacing: 16) {
                Text("How it works")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                
                HowItWorksRow(number: 1, text: "Recall three small moments that felt okay")
                HowItWorksRow(number: 2, text: "Savor one moment in more detail")
                HowItWorksRow(number: 3, text: "Receive a personalized reflection from Panda")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            )
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
            
            // Panda encouragement
            HStack(spacing: 12) {
                Image("panda_supportive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                
                Text("Even tiny moments of okayness matter. Let's find some together.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground.opacity(0.8))
            )
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 40)
        }
    }
    
    // MARK: - Moment Input View
    
    private var momentInputView: some View {
        VStack(spacing: 28) {
            // Moment number indicator
            ZStack {
                Circle()
                    .fill(Color.primaryGreen.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Text("\(currentMomentIndex + 1)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primaryGreen)
            }
            
            VStack(spacing: 8) {
                Text("Moment \(currentMomentIndex + 1) of 3")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                
                Text(momentPrompt)
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Input field
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $moments[currentMomentIndex])
                    .frame(minHeight: 120)
                    .padding(16)
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primaryGreen.opacity(0.3), lineWidth: 2)
                    )
                    .onChange(of: moments[currentMomentIndex]) { _, newValue in
                        guard currentStep == .moment1 || currentStep == .moment2 || currentStep == .moment3,
                              newValue.last == "\n" else { return }
                        moments[currentMomentIndex] = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if buttonEnabled {
                            handleButtonTap()
                        }
                    }
                
                Text("Examples: A warm cup of coffee, a kind text, sunlight through a window...")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary.opacity(0.7))
                    .padding(.horizontal, 4)
            }
            
            // Skip option
            if moments[currentMomentIndex].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: { advanceStep() }) {
                    Text("Skip this one")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    private var momentPrompt: String {
        switch currentMomentIndex {
        case 0: return "Think of something small from today that felt even a little bit good or okay."
        case 1: return "What's another moment, even tiny, that brought a hint of calm or comfort?"
        case 2: return "One more—anything that made you feel a bit lighter, even briefly."
        default: return ""
        }
    }
    
    // MARK: - Savor View
    
    private var savorView: some View {
        VStack(spacing: 28) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.mint.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "eye.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Color.mint)
            }
            
            VStack(spacing: 8) {
                Text("Savor One Moment")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                
                Text("Choose one moment to linger on. This helps your brain really absorb the good.")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Moment selector
            if nonEmptyMoments.count > 1 {
                VStack(spacing: 12) {
                    ForEach(Array(nonEmptyMoments.enumerated()), id: \.offset) { index, moment in
                        Button(action: { savorIndex = index }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(savorIndex == index ? Color.primaryGreen : Color.borderColor, lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    if savorIndex == index {
                                        Circle()
                                            .fill(Color.primaryGreen)
                                            .frame(width: 14, height: 14)
                                    }
                                }
                                
                                Text(moment)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textPrimary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(savorIndex == index ? Color.primaryGreen.opacity(0.08) : Color.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(savorIndex == index ? Color.primaryGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else if let moment = nonEmptyMoments.first {
                Text("\"\(moment)\"")
                    .font(.body.italic())
                    .foregroundStyle(Color.textPrimary)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primaryGreen.opacity(0.08))
                    )
            }
            
            // Detail questions
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What did you notice?")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("A sound, a color, a smell, a feeling in your body...")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    
                    TextEditor(text: $savorDetail)
                        .frame(minHeight: 80)
                        .padding(12)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                        .onChange(of: savorDetail) { _, newValue in
                            guard currentStep == .savor, newValue.last == "\n" else { return }
                            savorDetail = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("How did it make you feel?")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                    
                    TextEditor(text: $savorFeeling)
                        .frame(minHeight: 60)
                        .padding(12)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                        .onChange(of: savorFeeling) { _, newValue in
                            guard currentStep == .savor, newValue.last == "\n" else { return }
                            savorFeeling = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            if buttonEnabled {
                                handleButtonTap()
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Reflection View
    
    private var reflectionView: some View {
        VStack(spacing: 24) {
            if isGeneratingPanda {
                // Loading state
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.primaryGreen.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image("panda_supportive")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Panda is reflecting...")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.textPrimary)
                        
                        Text("Creating a personalized reflection on your moments")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(Color.primaryGreen)
                }
                .padding(.top, 40)
            } else if let text = pandaText {
                // Reflection content
                VStack(spacing: 24) {
                    HStack(spacing: 12) {
                        Image("panda_happy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Panda's Reflection")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.textPrimary)
                            
                            if usedAFM {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.caption2)
                                    Text("Powered by Apple Intelligence")
                                        .font(.caption2)
                                }
                                .foregroundStyle(Color.primaryGreen)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Text(text)
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                    
                    // Your moments summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your moments today")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textSecondary)
                        
                        ForEach(Array(nonEmptyMoments.enumerated()), id: \.offset) { index, moment in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.primaryGreen)
                                    .padding(.top, 3)
                                
                                Text(moment)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textPrimary)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primaryGreen.opacity(0.06))
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cardBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 12, y: 4)
                )
            }
        }
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 32) {
            // Celebration icon
            ZStack {
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(Color.primaryGreen.opacity(0.15 - Double(ring) * 0.04), lineWidth: 2)
                        .frame(width: 120 + CGFloat(ring) * 30, height: 120 + CGFloat(ring) * 30)
                }
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.primaryGreen.opacity(0.25),
                                Color.primaryGreen.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(Color.primaryGreen)
            }
            
            VStack(spacing: 12) {
                Text("Beautiful Work")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                
                Text("You've trained your brain to notice the good today. This small practice builds resilience over time.")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Panda message
            HStack(spacing: 12) {
                Image("panda_happy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                
                Text("Each time you do this, you're rewiring your brain to find more moments like these. See you next time!")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            )
        }
    }
    
    // MARK: - Bottom Button
    
    private var bottomButton: some View {
        Button(action: handleButtonTap) {
            HStack(spacing: 8) {
                Text(buttonTitle)
                    .font(.headline)
                
                if currentStep != .complete && currentStep != .intro {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(buttonEnabled ? Color.mint : Color.mint.opacity(0.5))
            )
        }
        .disabled(!buttonEnabled)
        .buttonStyle(.plain)
    }
    
    private var buttonTitle: String {
        switch currentStep {
        case .intro: return "Begin"
        case .moment1, .moment2, .moment3: return "Next"
        case .savor: return "Get Panda's Reflection"
        case .reflection: return isGeneratingPanda ? "Please wait..." : "Continue"
        case .complete: return "Done"
        }
    }
    
    private var buttonEnabled: Bool {
        switch currentStep {
        case .intro: return true
        case .moment1, .moment2, .moment3:
            return !moments[currentMomentIndex].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .savor: return true
        case .reflection: return !isGeneratingPanda
        case .complete: return true
        }
    }
    
    // MARK: - Actions
    
    private func handleButtonTap() {
        switch currentStep {
        case .intro:
            advanceStep()
        case .moment1, .moment2, .moment3:
            advanceStep()
        case .savor:
            generatePandaReflection()
            advanceStep()
        case .reflection:
            advanceStep()
        case .complete:
            finish()
        }
    }
    
    private func advanceStep() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if let nextStep = ThreeGoodMomentsStep(rawValue: currentStep.rawValue + 1) {
                // Skip savor if no moments entered
                if nextStep == .savor && nonEmptyMoments.isEmpty {
                    currentStep = .complete
                } else {
                    currentStep = nextStep
                }
            }
        }
    }
    
    private func generatePandaReflection() {
        guard !nonEmptyMoments.isEmpty else { return }
        
        let focusMoment = nonEmptyMoments.indices.contains(savorIndex) ? nonEmptyMoments[savorIndex] : nonEmptyMoments.first ?? ""
        
        isGeneratingPanda = true
        pandaText = nil
        
        Task {
            let result = await PandaSavoringService.shared.generate(
                moments: nonEmptyMoments,
                focusMoment: focusMoment,
                detail: "\(savorDetail) \(savorFeeling)".trimmingCharacters(in: .whitespacesAndNewlines)
            )
            await MainActor.run {
                pandaText = result.text
                usedAFM = result.usedAFM
                isGeneratingPanda = false
            }
        }
    }

    private func finish() {
        onComplete()
        dismiss()
    }
}

// MARK: - Supporting Views

struct HowItWorksRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.primaryGreen.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Text("\(number)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primaryGreen)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
        }
    }
}

struct AnimatedMomentsBackground: View {
    let step: ThreeGoodMomentsStep
    
    @State private var animateGradient = false
    
    private var colors: [Color] {
        switch step {
        case .intro, .complete:
            return [Color.backgroundCream, Color.primaryGreen.opacity(0.08), Color.mint.opacity(0.06)]
        case .moment1, .moment2, .moment3:
            return [Color.backgroundCream, Color.mint.opacity(0.1), Color.backgroundCream]
        case .savor:
            return [Color.backgroundCream, Color.mint.opacity(0.12), Color.primaryGreen.opacity(0.05)]
        case .reflection:
            return [Color.backgroundCream, Color.primaryGreen.opacity(0.1), Color.mint.opacity(0.08)]
        }
    }
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .top,
            endPoint: animateGradient ? .bottomTrailing : .bottom
        )
        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateGradient)
        .onAppear {
            animateGradient = true
        }
    }
}

#Preview {
    ThreeGoodMomentsView(duration: 3) {
        print("Three Good Moments completed")
    }
}
