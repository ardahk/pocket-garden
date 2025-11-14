//
//  GardenMascot.swift
//  pocket-garden
//
//  Cute Mascot Character (like Duolingo's Duo)
//

import SwiftUI
import SwiftData
import NaturalLanguage
#if canImport(FoundationModels)
import FoundationModels
#endif

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
        Image(pandaImageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
    
    private var pandaImageName: String {
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

    @State private var mascotScale: CGFloat = 0
    @State private var feedbackOpacity: Double = 0
    @State private var speechBubbleScale: CGFloat = 0
    @State private var showSparkles = false
    @State private var generatedText: String?
    @State private var emotionOverride: MascotEmotion?
    @State private var isGenerating = false
    @State private var showAINotice = false
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EmotionEntry.date, order: .reverse) private var allEntries: [EmotionEntry]

    private let mascotEmotion: MascotEmotion

    init(entry: EmotionEntry, onDismiss: @escaping () -> Void) {
        self.entry = entry
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

            VStack(spacing: Spacing.xxxl) {
                Spacer()

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

                        Task { await generateFeedback() }
                    }

                // Speech bubble with feedback
                SpeechBubble {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(mascotGreeting)
                            .font(Typography.title3)
                            .foregroundColor(.textPrimary)

                        if isGenerating {
                            HStack(spacing: Spacing.sm) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .font(Typography.body)
                                    .foregroundColor(.textSecondary)
                            }
                        } else {
                            Text(generatedText ?? entry.aiFeedback ?? "You're doing great!")
                                .font(Typography.body)
                                .foregroundColor(.textSecondary)
                        }
                        
                        if showAINotice {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                Text("Enable Apple Intelligence for richer feedback")
                                    .font(Typography.caption)
                            }
                            .foregroundColor(.primaryGreen.opacity(0.7))
                            .padding(.top, Spacing.xs)
                        }
                    }
                }
                .scaleEffect(speechBubbleScale)
                .opacity(feedbackOpacity)

                Spacer()

                // Continue button
                PrimaryButton("Continue", icon: "arrow.right") {
                    dismiss()
                }
                .padding(.horizontal, Layout.screenPadding)
                .opacity(feedbackOpacity)
            }
            .padding(.vertical, Spacing.xl)
        }
    }

    private var mascotGreeting: String {
        switch activeEmotion {
        case .happy:
            return "Amazing energy today! 🌟"
        case .supportive:
            return "I'm here with you! 💚"
        case .concerned:
            return "Sending you support! 🤗"
        case .proud:
            return "You're incredible! ✨"
        case .thinking:
            return "Processing your thoughts... 🤔"
        case .sleeping:
            return "Time to rest! 😴"
        case .neutral:
            return "Welcome! 👋"
        }
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

// MARK: - Panda Feedback Integration (on-device)

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
        
        if entry.aiFeedback != result.text {
            entry.aiFeedback = result.text
            try? modelContext.save()
        }
    }
}

fileprivate struct PandaFeedback: Codable {
    let text: String
    let emotionHint: String
    let tags: [String]?
}

fileprivate final class PandaFeedbackService {
    static let shared = PandaFeedbackService()
    private init() {}

    func generate(for entry: EmotionEntry, recentHints: [String]) async -> (text: String, emotion: MascotEmotion, usedAFM: Bool) {
        if #available(iOS 26.0, *), PandaFoundationManager.shared.isAvailable {
            if let afm = await generateWithAFM(entry: entry, recentHints: recentHints) {
                let mapped = mapEmotion(hint: afm.emotionHint, rating: entry.emotionRating)
                let clamped = clampEmotion(mapped, rating: entry.emotionRating)
                return (afm.text, clamped, true)
            }
        }
        let local = PandaLocalFeedbackEngine.shared.generate(entry: entry)
        return (local.text, local.emotion, false)
    }

    private func mapEmotion(hint: String, rating: Int) -> MascotEmotion {
        let h = hint.lowercased()
        if h.contains("happy") || h.contains("proud") { return .happy }
        if h.contains("support") || h.contains("encourage") { return .supportive }
        if h.contains("concern") || h.contains("tough") || h.contains("hard") { return .concerned }
        if h.contains("thinking") { return .thinking }
        if h.contains("sleep") { return .sleeping }
        if h.contains("neutral") { return .neutral }
        return MascotEmotion.from(rating: rating)
    }

    private func clampEmotion(_ emotion: MascotEmotion, rating: Int) -> MascotEmotion {
        // For very positive check-ins, always show a clearly positive mascot
        guard rating >= 8 else { return emotion }

        switch emotion {
        case .happy, .proud:
            return emotion
        default:
            // Prefer a joyful mascot over supportive/concerned when the rating is high
            return .happy
        }
    }

    private func minimizeMarkdown(_ s: String) -> String {
        var out = s
        ["#", "##", "###", "####", "---"].forEach { out = out.replacingOccurrences(of: $0, with: "") }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildPrompt(entry: EmotionEntry, recentHints: [String]) -> String {
        var lines: [String] = []
        lines.append("User's emotion rating: \(entry.emotionRating)/10")
        if let t = entry.transcription, !t.isEmpty {
            lines.append("\nUser's journal entry:")
            lines.append("\"\(t.prefix(1200))\"")
        }
        if !recentHints.isEmpty {
            lines.append("\nYour recent replies (vary your wording and avoid repeating these):")
            recentHints.prefix(3).forEach { lines.append("- \($0.prefix(150))") }
        }
        lines.append("\nRespond with valid JSON: {\"text\": \"...\", \"emotionHint\": \"...\", \"tags\": [...]}")
        return lines.joined(separator: "\n")
    }

    private func instructionsText() -> String {
        "You are Panda, a warm and thoughtful emotional wellness companion. Read the user's emotion rating and journal entry carefully. In your response (3–5 sentences, max 75 words):\n1. Always take the emotion rating into account together with the text.\n2. If the rating is 8, 9, or 10 out of 10, the overall tone MUST be clearly celebratory and proud. You may briefly acknowledge remaining stress, but focus mainly on what went well and why the user feels capable or hopeful.\n3. If the rating is 4–7, use a balanced, supportive tone that recognizes both difficulties and strengths.\n4. If the rating is 1–3, use a very gentle, compassionate tone and avoid minimizing their experience.\n5. Acknowledge at least one concrete detail they mentioned so it feels specific.\n6. Offer exactly one gentle, actionable suggestion (no long lists).\n7. Use warm, conversational language and vary your phrasing each time.\n8. Never diagnose, give medical advice, or repeat recent responses.\n\nMake it feel personal and genuine, not scripted."
    }

    @MainActor
    private func generateWithAFM(entry: EmotionEntry, recentHints: [String]) async -> PandaFeedback? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = PandaSessionManager.shared.getSession()
            let promptText = buildPrompt(entry: entry, recentHints: recentHints)
            do {
                let response = try await session.respond(to: promptText)
                let rawText = response.content
                
                // Try to parse JSON from response
                if let data = rawText.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(PandaFeedback.self, from: data) {
                    return PandaFeedback(
                        text: minimizeMarkdown(decoded.text),
                        emotionHint: decoded.emotionHint,
                        tags: decoded.tags
                    )
                }
                
                // Fallback: extract text from non-JSON response
                let cleaned = extractTextFromResponse(rawText)
                return PandaFeedback(
                    text: minimizeMarkdown(cleaned),
                    emotionHint: "supportive",
                    tags: nil
                )
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }
    
    private func extractTextFromResponse(_ raw: String) -> String {
        // Remove JSON artifacts if present
        var cleaned = raw
        if let start = cleaned.range(of: "\"text\":"), let end = cleaned.range(of: "\",", range: start.upperBound..<cleaned.endIndex) {
            let textRange = start.upperBound..<end.lowerBound
            cleaned = String(cleaned[textRange]).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "")
        }
        return cleaned
    }
}

fileprivate final class PandaLocalFeedbackEngine {
    static let shared = PandaLocalFeedbackEngine()
    private init() {}

    func generate(entry: EmotionEntry) -> (text: String, emotion: MascotEmotion) {
        let text = entry.transcription ?? ""
        let sentiment = sentimentScore(for: text)
        let emotion = blendedEmotion(rating: entry.emotionRating, sentiment: sentiment)
        let msg = message(for: emotion, topics: keywords(from: text))
        return (msg, emotion)
    }

    private func sentimentScore(for text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let tag = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0
        return Double(tag?.rawValue ?? "0") ?? 0
    }

    private func blendedEmotion(rating: Int, sentiment: Double) -> MascotEmotion {
        if rating <= 4 || sentiment < -0.5 { return .concerned }
        if rating >= 8 || sentiment > 0.5 { return .happy }
        return .supportive
    }

    private func keywords(from text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
        tagger.string = text
        var nouns = Set<String>()
        let range = text.startIndex..<text.endIndex
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            if let tag = tag, tag == .noun {
                let lemmaTag = tagger.tag(at: tokenRange.lowerBound, unit: .word, scheme: .lemma)
                let lemma = lemmaTag.0?.rawValue ?? String(text[tokenRange])
                nouns.insert(lemma.lowercased())
            }
            return true
        }
        return Array(nouns.prefix(3))
    }

    private func message(for emotion: MascotEmotion, topics: [String]) -> String {
        let topic = topics.first ?? "what you're experiencing"
        let variations: [[String]] = [
            ["Love this energy! ", "This is wonderful! ", "So glad to hear this! "],
            ["I hear how \(topic) is affecting you. ", "It sounds like \(topic) has been on your mind. ", "I can sense \(topic) is important right now. "],
            ["That sounds really tough with \(topic). ", "I can feel the weight of \(topic) in your words. ", "\(topic.capitalized) can be so challenging. "]
        ]
        
        switch emotion {
        case .happy:
            let opening = variations[0].randomElement()!
            return "\(opening)It's clear something positive happened today. Consider jotting down what made this moment special—it helps us recreate these feelings. What small thing brought you joy? 🌟"
        case .supportive:
            let opening = variations[1].randomElement()!
            return "\(opening)Your feelings are completely valid. When things feel uncertain, try this: take three slow breaths, then name one thing you can control right now. Sometimes the smallest step forward is enough. 💚"
        case .concerned:
            let opening = variations[2].randomElement()!
            return "\(opening)I'm right here with you. When everything feels heavy, let's ground together: place your feet flat, take a slow breath, and name five things you can see. You don't have to carry this alone. 🤗"
        default:
            return "Thanks for sharing your thoughts with me. Taking time to check in with yourself matters, and I'm here for every step of your journey."
        }
    }
}

@available(iOS 26.0, *)
fileprivate final class PandaSessionManager {
    static let shared = PandaSessionManager()
    private var session: LanguageModelSession?
    private init() {}
    
    func getSession() -> LanguageModelSession {
        if let existing = session {
            return existing
        }
        let instructions = "You are Panda, a warm and thoughtful emotional wellness companion. Read the user's journal entry carefully. In your response (3–5 sentences, max 75 words):\n1. Acknowledge something specific they mentioned to show you're listening\n2. Validate their feelings with empathy\n3. Offer one gentle, actionable suggestion\n4. Use warm, conversational language and vary your phrasing each time\n5. Never diagnose, give medical advice, or repeat recent responses\n\nMake it feel personal and genuine, not scripted."
        let newSession = LanguageModelSession(instructions: instructions)
        session = newSession
        return newSession
    }
    
    func resetSession() {
        session = nil
    }
}

fileprivate final class PandaFoundationManager {
    static let shared = PandaFoundationManager()
    private init() {}

    private(set) var notAvailableReason: String = ""

    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                notAvailableReason = ""
                return true
            case .unavailable(.deviceNotEligible):
                notAvailableReason = "This device is not eligible for Apple Intelligence."
                return false
            case .unavailable(.appleIntelligenceNotEnabled):
                notAvailableReason = "Enable Apple Intelligence in Settings to get richer Panda feedback."
                return false
            case .unavailable(.modelNotReady):
                notAvailableReason = "Apple Intelligence is downloading models. Connect to power and Wi‑Fi, then try again."
                return false
            case .unavailable(let other):
                notAvailableReason = "Apple Intelligence unavailable: \(String(describing: other))."
                return false
            }
        }
        #endif
        notAvailableReason = "Apple Intelligence requires iOS 26 or later."
        return false
    }
}
