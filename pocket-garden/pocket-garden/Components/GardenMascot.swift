//
//  GardenMascot.swift
//  pocket-garden
//
//  Cute Mascot Character (like Duolingo's Duo)
//

import SwiftUI
import SwiftData

// MARK: - Mascot Character

struct GardenMascot: View {
    let emotion: MascotEmotion
    let size: CGFloat

    @State private var isAnimating = false
    @State private var bounce = false

    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.primaryGreen.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.8
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0.3 : 0.6)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)

            // Body
            mascotBody
                .frame(width: size, height: size)
                .scaleEffect(bounce ? 1.05 : 1.0)
                .offset(y: bounce ? -5 : 0)
        }
        .onAppear {
            isAnimating = true
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                bounce = true
            }
        }
    }

    private var mascotBody: some View {
        Image(mascotImageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }

    private var mascotImageName: String {
        switch emotion {
        case .happy:
            return "panda_happy"
        case .supportive:
            return "panda_supportive"
        case .concerned:
            return "panda_sad"
        case .proud:
            return "panda_happy"
        case .thinking:
            return "panda_thinking"
        case .sleeping:
            return "panda_sleep"
        case .neutral:
            return "panda_welcome"
        }
    }

}

// MARK: - Mascot Emotion

enum MascotEmotion {
    case happy      // For positive entries (8-10)
    case supportive // For moderate entries (5-7)
    case concerned  // For low entries (1-4)
    case proud      // For achievements
    case thinking   // For transcription/loading
    case sleeping   // For idle/empty states
    case neutral    // For welcome/default

    static func from(rating: Int) -> MascotEmotion {
        switch rating {
        case 8...10: return .happy
        case 5...7: return .supportive
        case 1...4: return .concerned
        default: return .supportive
        }
    }
}

// MARK: - Animated Feedback Screen

struct MascotFeedbackView: View {
    let entry: EmotionEntry
    let onDismiss: () -> Void
    /// True when this is the user's first journal entry today.
    /// First entry → watering animation on Sanctuary deep-link tap.
    /// Second+ entry → bee animation (tree already watered today).
    let isFirstEntryToday: Bool

    @State private var mascotScale: CGFloat = 0
    @State private var feedbackOpacity: Double = 0
    @State private var speechBubbleScale: CGFloat = 0
    @State private var showSparkles = false
    @State private var generatedText: String?
    @State private var emotionOverride: MascotEmotion?
    @State private var isGenerating = false
    @State private var showContinueButton = false
    @State private var showAINotice = false
    @AppStorage("userFirstName") private var userFirstName = ""
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EmotionEntry.date, order: .reverse) private var allEntries: [EmotionEntry]

    private let mascotEmotion: MascotEmotion

    init(entry: EmotionEntry, isFirstEntryToday: Bool = true, onDismiss: @escaping () -> Void) {
        self.entry = entry
        self.isFirstEntryToday = isFirstEntryToday
        self.onDismiss = onDismiss
        self.mascotEmotion = MascotEmotion.from(rating: entry.emotionRating)
    }

    var body: some View {
        ZStack {
            // Background
            Color.peacefulGradient
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Sparkles for high ratings
            if showSparkles && entry.emotionRating >= 8 {
                SparklesView(sparkleCount: 20)
            }

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    Spacer(minLength: Spacing.xl)

                    // Mascot character
                    GardenMascot(emotion: activeEmotion, size: 140)
                        .scaleEffect(mascotScale)
                        .onAppear {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                                mascotScale = 1.0
                            }

                            if entry.emotionRating >= 8 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation { showSparkles = true }
                                }
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    speechBubbleScale = 1.0
                                }
                                Theme.Haptics.light()
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                withAnimation(.easeIn(duration: 0.5)) { feedbackOpacity = 1.0 }
                            }

                            showContinueButton = false
                            Task { await generateFeedback() }
                        }

                    // Speech bubble with feedback
                    SpeechBubble {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text(mascotGreeting)
                                .font(Typography.title3)
                                .foregroundColor(.textPrimary)

                            if isGenerating {
                                ThinkingIndicatorView()
                            } else {
                                LinkedFeedbackText(
                                    text: generatedText ?? entry.aiFeedback ?? "You're doing great!",
                                    onDeepLinkTapped: { deepLink in
                                        handleDeepLinkTap(deepLink)
                                    }
                                )
                            }

                            if showAINotice {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    HStack(spacing: Spacing.xs) {
                                        Image(systemName: "sparkles")
                                            .font(.caption)
                                        Text("Using local on-device support mode")
                                            .font(Typography.caption)
                                    }

                                    Text(aiUnavailableDetail)
                                        .font(Typography.caption)

                                    Text("To enable richer responses: Settings > Apple Intelligence & Siri, then return here.")
                                        .font(Typography.caption)
                                }
                                .foregroundColor(.primaryGreen.opacity(0.7))
                                .padding(.top, Spacing.xs)
                            }
                        }
                    }
                    .scaleEffect(speechBubbleScale)
                    .opacity(feedbackOpacity)

                    Spacer(minLength: Spacing.xl)

                    if showContinueButton {
                        // Continue button
                        PrimaryButton("Continue", icon: "arrow.right") {
                            dismiss()
                        }
                        .padding(.horizontal, Layout.screenPadding)
                        .opacity(feedbackOpacity)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                                removal: .opacity
                            )
                        )
                    }

                    Spacer(minLength: Spacing.xl)
                }
                .frame(minHeight: UIScreen.main.bounds.height - 100)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var mascotGreeting: String {
        let preferredName = sanitizeName(userFirstName)
        switch activeEmotion {
        case .happy:
            return preferredName.isEmpty ? "Amazing energy today! 🌟" : "Amazing energy today, \(preferredName)! 🌟"
        case .supportive:
            return preferredName.isEmpty ? "I'm here with you! 💚" : "I'm here with you, \(preferredName)! 💚"
        case .concerned:
            return preferredName.isEmpty ? "Sending you support! 🤗" : "Sending you support, \(preferredName)! 🤗"
        case .proud:
            return preferredName.isEmpty ? "You're incredible! ✨" : "You're incredible, \(preferredName)! ✨"
        case .thinking:
            return "Processing your thoughts... 🤔"
        case .sleeping:
            return "Time to rest! 😴"
        case .neutral:
            return "Welcome! 👋"
        }
    }

    private var aiUnavailableDetail: String {
        let reason = PandaFoundationManager.shared.notAvailableReason
        if reason.isEmpty {
            return "Your reflections are still generated privately on this device."
        }
        return "\(reason) Your reflections are still generated privately on this device."
    }

    private func dismiss() {
        Theme.Haptics.medium()
        withAnimation {
            mascotScale = 0.8
            feedbackOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }

    /// Called when user taps a Sanctuary practice hyperlink in the feedback text.
    /// Dismisses the feedback screen and posts a notification so the Garden screen
    /// can show the bee animation first, then navigate to the correct Sanctuary activity.
    private func handleDeepLinkTap(_ deepLink: SanctuaryDeepLink) {
        Theme.Haptics.medium()
        withAnimation {
            mascotScale = 0.8
            feedbackOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Store the deepLink in the shared singleton before posting the notification,
            // so ForestGardenViewRedesigned can read it reliably after the bee animation.
            PendingDeepLink.shared.pendingLink = deepLink
            NotificationCenter.default.post(name: .navigateToGardenThenSanctuary, object: nil)
            onDismiss()
        }
    }

    private func sanitizeName(_ raw: String) -> String {
        sanitizeUserName(raw)
    }
}

// MARK: - Speech Bubble

struct SpeechBubble<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Bubble tail
            Triangle()
                .fill(Color.cardBackground)
                .frame(width: 20, height: 15)
                .rotationEffect(.degrees(180))
                .offset(y: 1)

            // Bubble content
            content
                .padding(Spacing.xl)
                .background(Color.cardBackground)
                .cornerRadius(CornerRadius.lg)
                .cardShadow()
        }
        .padding(.horizontal, Layout.screenPadding)
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Linked Feedback Text

/// Renders Bumblebee's feedback text with detected Sanctuary practice names highlighted
/// in green. A small "Open in Sanctuary" button appears below the text when a link is found.
struct LinkedFeedbackText: View {
    let text: String
    let onDeepLinkTapped: (SanctuaryDeepLink) -> Void

    /// The first detected deep-link in the text.
    private var detectedLink: SanctuaryDeepLink? {
        firstDeepLink(in: text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Styled text with sanctuary phrases highlighted in green
            buildStyledText(from: text)
                .fixedSize(horizontal: false, vertical: true)

            // "Open in Sanctuary" button — only shown when a link is detected
            if let link = detectedLink {
                Button {
                    onDeepLinkTapped(link)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 12))
                        Text("Open in Sanctuary")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(Color.primaryGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primaryGreen.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Builds a `Text` with sanctuary phrases rendered in the accent colour.
    private func buildStyledText(from text: String) -> Text {
        var result = Text("")
        var remaining = text

        while !remaining.isEmpty {
            guard let (matchRange, _) = earliestMatch(in: remaining) else {
                result = result + Text(remaining)
                    .foregroundColor(.textSecondary)
                    .font(Typography.body)
                break
            }

            // Plain text before the match
            let before = String(remaining[remaining.startIndex..<matchRange.lowerBound])
            if !before.isEmpty {
                result = result + Text(before)
                    .foregroundColor(.textSecondary)
                    .font(Typography.body)
            }

            // The matched link phrase — highlighted in primaryGreen, bold
            let matched = String(remaining[matchRange])
            result = result + Text(matched)
                .foregroundColor(Color.primaryGreen)
                .font(Typography.body.weight(.semibold))

            remaining = String(remaining[matchRange.upperBound...])
        }

        return result
    }

    /// Returns the (range, deepLink) for the earliest leftmost match in `text`.
    private func earliestMatch(in text: String) -> (Range<String.Index>, SanctuaryDeepLink)? {
        var bestRange: Range<String.Index>? = nil
        var bestLink: SanctuaryDeepLink? = nil

        for deepLink in allSanctuaryDeepLinks {
            guard let range = text.range(of: deepLink.mentionPhrase, options: .caseInsensitive) else { continue }
            if let current = bestRange {
                if range.lowerBound < current.lowerBound {
                    bestRange = range; bestLink = deepLink
                } else if range.lowerBound == current.lowerBound,
                          deepLink.mentionPhrase.count > (bestLink?.mentionPhrase.count ?? 0) {
                    bestRange = range; bestLink = deepLink
                }
            } else {
                bestRange = range; bestLink = deepLink
            }
        }

        guard let r = bestRange, let l = bestLink else { return nil }
        return (r, l)
    }

    /// Returns the first (earliest) detected deep-link in the text.
    private func firstDeepLink(in text: String) -> SanctuaryDeepLink? {
        earliestMatch(in: text)?.1
    }
}

// MARK: - Watering Transition Overlay

/// Full-screen overlay shown briefly when the user taps a Sanctuary deep-link.
/// Displays falling water drops over a semi-transparent background to signal
/// "we're heading to your garden first" before opening the Sanctuary exercise.
struct WateringTransitionOverlay: View {
    @State private var drops: [OverlayWaterDrop] = []
    @State private var messageOpacity: Double = 0

    struct OverlayWaterDrop: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var opacity: Double
        var size: CGFloat
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            // Water drops
            ForEach(drops) { drop in
                Text("💧")
                    .font(.system(size: drop.size))
                    .position(x: drop.x, y: drop.y)
                    .opacity(drop.opacity)
            }

            // Message
            VStack(spacing: 16) {
                Text("🌿")
                    .font(.system(size: 56))

                Text("Heading to Sanctuary...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("Let's water your garden first")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .opacity(messageOpacity)
        }
        .onAppear {
            startDrops()
            withAnimation(.easeIn(duration: 0.4)) {
                messageOpacity = 1
            }
        }
    }

    private func startDrops() {
        let screenWidth = UIScreen.main.bounds.width
        // Spawn drops in waves over 3 seconds
        for i in 0..<18 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.18) {
                let drop = OverlayWaterDrop(
                    x: CGFloat.random(in: 40...(screenWidth - 40)),
                    y: -40,
                    opacity: Double.random(in: 0.7...1.0),
                    size: CGFloat.random(in: 22...38)
                )
                drops.append(drop)

                withAnimation(.easeIn(duration: Double.random(in: 0.9...1.3))) {
                    if let idx = drops.firstIndex(where: { $0.id == drop.id }) {
                        drops[idx].y = UIScreen.main.bounds.height + 60
                        drops[idx].opacity = 0
                    }
                }
            }
        }
    }
}

// MARK: - Bee Transition Overlay

/// Shown on the Garden screen when the user has already journaled today (tree already
/// watered). Four bees drift lazily around the tree area — no dark overlay, no message
/// card, bees cluster within ~100 pt of the tree which sits near the vertical centre
/// of the *safe-area content area* (not the full screen), so they track the tree
/// correctly on all device sizes regardless of nav bar / tab bar height.
struct BeeTransitionOverlay: View {

    // Each bee has an offset from the content-area centre and two independent drift
    // animations (X and Y with different periods) that produce a natural lazy float.
    struct BeeConfig: Identifiable {
        let id = UUID()
        /// Fixed offset from content-area centre in points.
        let offsetX: CGFloat
        let offsetY: CGFloat
        /// Max drift amplitude in each axis.
        let driftX: CGFloat
        let driftY: CGFloat
        /// Period for each drift axis (seconds).
        let durationX: Double
        let durationY: Double
        /// Emoji font size.
        let fontSize: CGFloat
        /// Fade-in delay (seconds).
        let delay: Double
        /// Initial travel direction for each axis.
        let startsPositiveX: Bool
        let startsPositiveY: Bool
        /// Per-bee phase shift so movement is not synchronized.
        let phaseShift: Double
        /// Subtle roll and pulse values for extra life.
        let tiltDegrees: CGFloat
        let tiltDuration: Double
        let pulseScale: CGFloat
        let pulseDuration: Double
    }

    // Four bees in distinct quadrants around the tree. The tree lives inside a VStack
    // with two Spacers so it sits very close to the vertical centre of the safe-area
    // content area. By NOT using .ignoresSafeArea(), the GeometryReader measures only
    // that content area, so cx/cy are automatically correct on every device size.
    private let beeConfigs: [BeeConfig] = [
        // Upper-left
        BeeConfig(offsetX: -95, offsetY: -110, driftX: 20, driftY: 16, durationX: 5.2, durationY: 3.9, fontSize: 28, delay: 0.0, startsPositiveX: true, startsPositiveY: false, phaseShift: 0.15, tiltDegrees: 5, tiltDuration: 1.8, pulseScale: 0.06, pulseDuration: 2.4),
        // Upper-right
        BeeConfig(offsetX:  90, offsetY: -120, driftX: 16, driftY: 20, durationX: 4.4, durationY: 5.7, fontSize: 26, delay: 0.2, startsPositiveX: false, startsPositiveY: true, phaseShift: 0.35, tiltDegrees: 4, tiltDuration: 2.2, pulseScale: 0.04, pulseDuration: 2.8),
        // Lower-left
        BeeConfig(offsetX: -80, offsetY:  40, driftX: 18, driftY: 14, durationX: 6.0, durationY: 4.1, fontSize: 24, delay: 0.4, startsPositiveX: true, startsPositiveY: true, phaseShift: 0.5, tiltDegrees: 6, tiltDuration: 1.6, pulseScale: 0.05, pulseDuration: 2.1),
        // Lower-right
        BeeConfig(offsetX:  85, offsetY:  30, driftX: 14, driftY: 18, durationX: 4.7, durationY: 6.3, fontSize: 26, delay: 0.6, startsPositiveX: false, startsPositiveY: false, phaseShift: 0.25, tiltDegrees: 5, tiltDuration: 2.0, pulseScale: 0.045, pulseDuration: 2.6),
    ]

    var body: some View {
        // No .ignoresSafeArea() — GeometryReader measures the safe-area content area.
        // This makes cx/cy align with the tree's actual centre on every device.
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2

            ZStack {
                ForEach(beeConfigs) { config in
                    FloatingBeeView(
                        config: config,
                        baseX: cx + config.offsetX,
                        baseY: cy + config.offsetY
                    )
                }
            }
        }
    }
}

/// A single bee that drifts lazily using two independent easeInOut animations,
/// fading in on appear and staying visible until the parent removes it.
private struct FloatingBeeView: View {
    let config: BeeTransitionOverlay.BeeConfig
    /// Absolute position (from GeometryReader) where the bee sits at rest.
    let baseX: CGFloat
    let baseY: CGFloat

    @State private var opacity: Double = 0
    @State private var driftXPhase = false
    @State private var driftYPhase = false
    @State private var tiltPhase = false
    @State private var pulsePhase = false

    var body: some View {
        Text("🐝")
            .font(.system(size: config.fontSize))
            .opacity(opacity)
            .rotationEffect(.degrees(tiltPhase ? config.tiltDegrees : -config.tiltDegrees))
            .scaleEffect(pulsePhase ? (1 + config.pulseScale) : (1 - config.pulseScale))
            .offset(
                x: driftXPhase ?  config.driftX : -config.driftX,
                y: driftYPhase ?  config.driftY : -config.driftY
            )
            .position(x: baseX, y: baseY)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + config.delay) {
                    driftXPhase = config.startsPositiveX
                    driftYPhase = config.startsPositiveY
                    tiltPhase = config.startsPositiveX
                    pulsePhase = config.startsPositiveY

                    // Fade in gently
                    withAnimation(.easeIn(duration: 0.8)) { opacity = 1 }
                    // Independent X drift
                    withAnimation(
                        .easeInOut(duration: config.durationX)
                        .repeatForever(autoreverses: true)
                        .delay(config.phaseShift)
                    ) { driftXPhase = true }
                    // Independent Y drift, offset in phase so path feels organic
                    withAnimation(
                        .easeInOut(duration: config.durationY)
                        .repeatForever(autoreverses: true)
                        .delay(config.durationY * 0.4 + config.phaseShift)
                    ) { driftYPhase = true }
                    // Subtle rotational flutter
                    withAnimation(
                        .easeInOut(duration: config.tiltDuration)
                        .repeatForever(autoreverses: true)
                        .delay(config.phaseShift * 0.5)
                    ) { tiltPhase.toggle() }
                    // Gentle breathing pulse
                    withAnimation(
                        .easeInOut(duration: config.pulseDuration)
                        .repeatForever(autoreverses: true)
                        .delay(config.phaseShift * 0.8)
                    ) { pulsePhase.toggle() }
                }
            }
    }
}

// MARK: - Previews

#Preview("Happy Mascot") {
    ZStack {
        Color.backgroundCream
            .ignoresSafeArea()

        GardenMascot(emotion: .happy, size: 140)
    }
}

#Preview("Feedback Screen") {
    MascotFeedbackView(
        entry: .sample(rating: 9, includeTranscription: true, includeFeedback: true)
    ) {
        print("Dismissed")
    }
}

// MARK: - Bumblebee Feedback Integration (on-device)

extension MascotFeedbackView {
    private var activeEmotion: MascotEmotion { emotionOverride ?? mascotEmotion }

    private func generateFeedback() async {
        guard !isGenerating else { return }
        isGenerating = true
        defer { isGenerating = false }

        // Get recent feedbacks to avoid repetition
        let recentFeedbacks = allEntries
            .prefix(5)
            .compactMap { $0.aiFeedback }
            .filter { !$0.isEmpty }

        let result = await PandaFeedbackService.shared.generate(for: entry, recentHints: recentFeedbacks)
        generatedText = result.text
        emotionOverride = result.emotion
        showAINotice = !result.usedAFM

        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            showContinueButton = true
        }

        if entry.aiFeedback != result.text {
            entry.aiFeedback = result.text
            try? modelContext.save()
        }
    }
}
