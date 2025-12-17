//
//  GardenMascot.swift
//  pocket-garden
//
//  Cute Mascot Character (like Duolingo's Duo)
//

import SwiftUI
import SwiftData
import NaturalLanguage
import Foundation
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
                                    .fixedSize(horizontal: false, vertical: true)
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

                    Spacer(minLength: Spacing.xl)

                    // Continue button
                    PrimaryButton("Continue", icon: "arrow.right") {
                        dismiss()
                    }
                    .padding(.horizontal, Layout.screenPadding)
                    .opacity(feedbackOpacity)
                    
                    Spacer(minLength: Spacing.xl)
                }
                .frame(minHeight: UIScreen.main.bounds.height - 100)
            }
            .scrollIndicators(.hidden)
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

// MARK: - Language Detection Helper

/// Languages officially supported by Apple Foundation Models (iOS 26)
fileprivate let afmSupportedLanguages: Set<String> = [
    "en", "de", "es", "fr", "it", "ja", "ko", "pt", "zh-Hans", "zh-Hant", "tr"
]

fileprivate func detectLanguageCode(from text: String) -> String? {
    guard !text.isEmpty else { return nil }
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    return recognizer.dominantLanguage?.rawValue
}

fileprivate func detectLanguage(from text: String) -> String? {
    guard !text.isEmpty else { return nil }
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    guard let language = recognizer.dominantLanguage else { return nil }
    // Return the language name for use in prompts
    let locale = Locale(identifier: "en")
    return locale.localizedString(forLanguageCode: language.rawValue)
}

fileprivate func isLanguageSupportedByAFM(_ text: String) -> Bool {
    guard let langCode = detectLanguageCode(from: text) else { return true }
    // Check if the base language code is supported
    let baseCode = langCode.components(separatedBy: "-").first ?? langCode
    return afmSupportedLanguages.contains(langCode) || afmSupportedLanguages.contains(baseCode)
}

fileprivate func languageInstruction(for text: String?) -> String {
    guard let text = text, !text.isEmpty,
          let detectedLanguage = detectLanguage(from: text),
          detectedLanguage.lowercased() != "english" else {
        return ""
    }
    
    // Strong instruction to respond in the user's language with ACTUAL feedback
    return """
    
    CRITICAL LANGUAGE & RESPONSE RULES:
    - The user wrote in \(detectedLanguage). You MUST respond entirely in \(detectedLanguage).
    - DO NOT just paraphrase or summarize what the user wrote.
    - DO NOT restate their entry back to them.
    - You MUST provide ORIGINAL therapeutic feedback that:
      1. Validates their emotions with empathy
      2. Acknowledges specific details they mentioned
      3. Offers ONE helpful suggestion from the Sanctuary practices listed above
    - Your response should feel like a caring friend giving advice, NOT a summary of what they said.
    """
}

// MARK: - Sanctuary Items (centralized for easy updates)

/// Dictionary of all Sanctuary practices with descriptions for AFM prompts.
/// Update this single source when adding/removing Sanctuary features.
fileprivate let sanctuaryItems: [String: String] = [
    "Box Breathing": "A calming 4-4-4-4 breathing technique to steady anxiety and ground quickly",
    "4-7-8 Breath": "A relaxing pattern with a long exhale to wind down and prepare for sleep",
    "Coherent Breathing": "A smooth 5-5 rhythm that balances energy and eases stress",
    "Calming Breath": "A short inhale and long exhale technique to release tension quickly",
    "Body Scan": "A mindfulness meditation that brings awareness to each part of your body to release tension",
    "Three Good Moments": "A savoring exercise where you reflect on three positive moments from your day",
    "Worry Tree": "A guided decision tree to process worries by identifying what you can and cannot control",
    "Safe Place Visualization": "A calming visualization exercise to imagine a peaceful, secure place",
    "Grounding Exercise": "A 5-4-3-2-1 sensory grounding technique to anchor yourself in the present moment",
    "Affirmations": "Gentle positive self-compassion messages to nurture your inner voice"
]

/// Formats sanctuary items for inclusion in AFM prompts
fileprivate func sanctuaryItemsForPrompt() -> String {
    var lines: [String] = ["SANCTUARY PRACTICES (always mention 'in Sanctuary' when suggesting):"]
    for (name, description) in sanctuaryItems.sorted(by: { $0.key < $1.key }) {
        lines.append("- \(name): \(description)")
    }
    return lines.joined(separator: "\n")
}

/// Returns just the names of sanctuary items as a comma-separated list
fileprivate func sanctuaryItemNames() -> String {
    sanctuaryItems.keys.sorted().joined(separator: ", ")
}

fileprivate final class PandaFeedbackService {
    static let shared = PandaFeedbackService()
    private init() {}
    
    // Crisis indicators that should trigger special supportive response
    private let crisisIndicators = [
        "want to die", "kill myself", "end it all", "end my life",
        "no reason to live", "better off dead", "suicide",
        "don't want to be here", "can't go on", "give up on life",
        "hurt myself", "self harm", "cutting myself"
    ]
    
    private func detectCrisis(in text: String?) -> Bool {
        guard let text = text?.lowercased() else { return false }
        return crisisIndicators.contains { text.contains($0) }
    }
    
    private func crisisResponse() -> String {
        return "I hear you, and I'm really glad you're sharing this with me. What you're feeling is real and valid, and you don't have to carry it alone. Please consider reaching out to someone you trust - a friend, family member, or a professional who can support you right now. You matter, and there are people who want to help. If you're in crisis, please contact a crisis helpline in your area 💙"
    }

    func generate(for entry: EmotionEntry, recentHints: [String]) async -> (text: String, emotion: MascotEmotion, usedAFM: Bool) {
        // Check for crisis indicators first - provide supportive response with resources
        if detectCrisis(in: entry.transcription) {
            return (crisisResponse(), .concerned, false)
        }
        
        if #available(iOS 26.0, *), PandaFoundationManager.shared.isAvailable {
            if let afm = await generateWithAFM(entry: entry, recentHints: recentHints) {
                let mapped = mapEmotion(hint: afm.emotionHint, rating: entry.emotionRating)
                let clamped = clampEmotion(mapped, rating: entry.emotionRating)
                return (afm.text, clamped, true)
            }
        }
        let local = BumblebeeLocalFeedbackEngine.shared.generate(entry: entry)
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
            // Add language instruction if entry is not in English
            let langInstruction = languageInstruction(for: t)
            if !langInstruction.isEmpty {
                lines.append(langInstruction)
            }
        }
        if !recentHints.isEmpty {
            lines.append("\nYour recent replies (vary your wording and avoid repeating these):")
            recentHints.prefix(3).forEach { lines.append("- \($0.prefix(150))") }
        }
        lines.append("\nRespond with valid JSON: {\"text\": \"...\", \"emotionHint\": \"...\", \"tags\": [...]}")
        return lines.joined(separator: "\n")
    }

    private func instructionsText() -> String {
        let practices = sanctuaryItemNames()
        return "You are Bumblebee, a warm and thoughtful emotional wellness companion. Read the user's emotion rating and journal entry carefully. In your response (3–5 sentences, max 75 words):\n1. Always take the emotion rating into account together with the text.\n2. If the rating is 8, 9, or 10 out of 10, the overall tone MUST be clearly celebratory and proud. You may briefly acknowledge remaining stress, but focus mainly on what went well and why the user feels capable or hopeful.\n3. If the rating is 4–7, use a balanced, supportive tone that recognizes both difficulties and strengths.\n4. If the rating is 1–3, use a very gentle, compassionate tone and avoid minimizing their experience.\n5. Acknowledge at least one concrete detail they mentioned so it feels specific.\n6. Offer exactly one gentle, actionable suggestion (no long lists).\n7. When it fits, let that suggestion be one specific practice from the user's Sanctuary space in the app (available practices: \(practices)). Mention \"in Sanctuary\" so they know where to go.\n8. Use warm, conversational language and vary your phrasing each time.\n9. Never diagnose, give medical advice, or repeat recent responses.\n\nMake it feel personal and genuine, not scripted."
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
                
                var feedbackText: String
                var emotionHint: String = "supportive"
                var tags: [String]? = nil
                
                // Try to parse JSON from response
                if let data = rawText.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(PandaFeedback.self, from: data) {
                    feedbackText = minimizeMarkdown(decoded.text)
                    emotionHint = decoded.emotionHint
                    tags = decoded.tags
                } else {
                    // Fallback: extract text from non-JSON response
                    feedbackText = minimizeMarkdown(extractTextFromResponse(rawText))
                }
                
                // Validate the generated output
                let userInput = entry.transcription ?? ""
                if !userInput.isEmpty {
                    let validation = await PandaOutputValidator.shared.validate(
                        output: feedbackText,
                        input: userInput,
                        context: "journal"
                    )
                    
                    // Use corrected output if validation failed but correction succeeded
                    if !validation.isValid, let corrected = validation.correctedOutput {
                        feedbackText = corrected
                    }
                }
                
                return PandaFeedback(
                    text: feedbackText,
                    emotionHint: emotionHint,
                    tags: tags
                )
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }
    
    private func extractTextFromResponse(_ raw: String) -> String {
        var cleaned = raw
        
        // Try to extract "text" field from JSON-like response
        if let start = cleaned.range(of: "\"text\":") {
            // Find the opening quote after "text":
            let afterKey = cleaned[start.upperBound...]
            if let openQuote = afterKey.firstIndex(of: "\"") {
                let contentStart = cleaned.index(after: openQuote)
                // Find the closing quote (handle escaped quotes)
                var idx = contentStart
                while idx < cleaned.endIndex {
                    if cleaned[idx] == "\"" {
                        // Check if it's escaped
                        let prevIdx = cleaned.index(before: idx)
                        if prevIdx >= contentStart && cleaned[prevIdx] == "\\" {
                            idx = cleaned.index(after: idx)
                            continue
                        }
                        // Found closing quote
                        cleaned = String(cleaned[contentStart..<idx])
                        break
                    }
                    idx = cleaned.index(after: idx)
                }
            }
        }
        
        // Remove any remaining JSON artifacts that might leak through
        let artifactsToRemove = [
            "emotionHint:", "\"emotionHint\":",
            "tags:", "\"tags\":",
            "/10", "supportive", "proud", "concerned",
            "{", "}", "[", "]"
        ]
        for artifact in artifactsToRemove {
            if cleaned.contains(artifact) && cleaned.count < 300 {
                // Only remove if it looks like JSON leaked (short text with artifacts)
                cleaned = cleaned.replacingOccurrences(of: artifact, with: "")
            }
        }
        
        // Clean up any trailing metadata like "emotionHint: 7/10"
        if let range = cleaned.range(of: "emotionHint", options: .caseInsensitive) {
            cleaned = String(cleaned[..<range.lowerBound])
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

final class PandaWeeklyFeedbackService {
    static let shared = PandaWeeklyFeedbackService()
    private init() {}

    /// Generate a weekly Panda message from multiple entries. Uses Apple Intelligence
    /// when available, with a local on-device fallback otherwise.
    func generate(for entries: [EmotionEntry]) async -> (text: String, usedAFM: Bool) {
        guard !entries.isEmpty else {
            let text = "This week is just getting started. Each check‑in you make helps me understand how you're doing, and I'm here whenever you want to share more. 🌱"
            return (text, false)
        }

        if #available(iOS 26.0, *), PandaFoundationManager.shared.isAvailable {
            if let afm = await generateWithAFM(entries: entries) {
                return (afm.text, true)
            }
        }

        let local = generateLocal(for: entries)
        return (local, false)
    }

    @MainActor
    private func generateWithAFM(entries: [EmotionEntry]) async -> PandaFeedback? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = PandaSessionManager.shared.getSession()
            let promptText = buildWeeklyPrompt(entries: entries)
            do {
                let response = try await session.respond(to: promptText)
                let rawText = response.content

                var feedbackText: String
                var emotionHint: String = "supportive"
                var tags: [String]? = nil

                if let data = rawText.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(PandaFeedback.self, from: data) {
                    feedbackText = minimizeMarkdown(decoded.text)
                    emotionHint = decoded.emotionHint
                    tags = decoded.tags
                } else {
                    feedbackText = minimizeMarkdown(extractTextFromResponse(rawText))
                }

                // Validate the generated output
                let combinedInput = entries.compactMap { $0.cleanedTranscription ?? $0.transcription }.joined(separator: " ")
                if !combinedInput.isEmpty {
                    let validation = await PandaOutputValidator.shared.validate(
                        output: feedbackText,
                        input: combinedInput,
                        context: "weekly"
                    )
                    
                    // Use corrected output if validation failed but correction succeeded
                    if !validation.isValid, let corrected = validation.correctedOutput {
                        feedbackText = corrected
                    }
                }

                return PandaFeedback(
                    text: feedbackText,
                    emotionHint: emotionHint,
                    tags: tags
                )
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }

    private func generateLocal(for entries: [EmotionEntry]) -> String {
        let calendar = Calendar.current
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"

        let ratings = entries.map { $0.emotionRating }
        let avgRating = Double(ratings.reduce(0, +)) / Double(max(ratings.count, 1))

        // Find one recent entry with text for a concrete detail
        let textEntry = entries
            .sorted(by: { $0.date > $1.date })
            .first(where: { !($0.cleanedTranscription?.isEmpty ?? $0.transcription?.isEmpty ?? true) })

        var detailLine = ""
        if let e = textEntry {
            let day = dayFormatter.string(from: e.date)
            let snippet = (e.cleanedTranscription ?? e.transcription ?? "").prefix(120)
            if !snippet.isEmpty {
                detailLine = " For example, on \(day) you shared: \"\(snippet)\"."
            }
        }

        let checkInCount = Set(entries.map { calendar.startOfDay(for: $0.date) }).count

        let base: String
        switch avgRating {
        case 8...10:
            base = "You've had a really bright week so far, with lots of moments of good energy and emotional strength."
        case 6..<8:
            base = "This week has a steady, gently positive rhythm. You're noticing what supports your wellbeing and showing up for yourself."
        case 4..<6:
            base = "This week has been a mix of easier and tougher moments, but you keep checking in and that takes courage."
        default:
            base = "It's been a heavy week so far, and I can tell you've been carrying a lot. Thank you for being honest in your check‑ins."
        }

        let consistency: String
        switch checkInCount {
        case 5...:
            consistency = " You've checked in on most days, which is an amazing act of self‑care."
        case 3...4:
            consistency = " You've checked in on several days, and that consistency really matters."
        case 1...2:
            consistency = " Even a couple of check‑ins this week are meaningful steps in understanding how you're feeling."
        default:
            consistency = ""
        }

        let suggestion: String
        switch avgRating {
        case 8...10:
            suggestion = " This weekend, consider writing down one or two things that have been working especially well, so you can return to them when you need a boost. If you’d like, you could also spend a few minutes with Three Good Moments or affirmations in Sanctuary to help you really soak it in."
        case 6..<8:
            suggestion = " Over the next few days, try repeating one small habit that helped you feel a bit more grounded—like a short walk, a mindful pause, or journaling before bed. You might also choose one quick practice in Sanctuary—like box breathing or the grounding exercise—when you want a small reset."
        case 4..<6:
            suggestion = " In the coming days, choose one tiny act of kindness toward yourself—something that feels doable, like a five‑minute break or a gentle walk. When you feel up for it, you could try a short Body Scan or grounding exercise in Sanctuary to give your system a gentler pace."
        default:
            suggestion = " For the rest of this week, see if you can give yourself permission to move slowly and choose just one small thing that feels supportive, even if it's simply taking a deeper breath. If it helps, you might spend a few minutes in Sanctuary—perhaps with the Safe Place visualization, a grounding exercise, or a few rounds of box breathing."
        }

        return base + consistency + detailLine + " " + suggestion
    }

    private func buildWeeklyPrompt(entries: [EmotionEntry]) -> String {
        var lines: [String] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        
        // Detect dominant language from entries
        let allText = entries.compactMap { $0.cleanedTranscription ?? $0.transcription }.joined(separator: " ")
        let langInstruction = languageInstruction(for: allText)

        lines.append("You are Bumblebee, a warm and thoughtful emotional wellness companion.")
        lines.append("You are reading the user's journal entries for this week so far (from the start of the week up to today). In your response:")
        lines.append("- Write 3–6 sentences, maximum 120 words.")
        lines.append("- Clearly refer to 'this week' or 'this week so far'.")
        lines.append("- Acknowledge at least one concrete detail from their entries so it feels specific.")
        lines.append("- Describe any noticeable pattern in how they have been feeling.")
        lines.append("- Offer exactly one gentle, actionable suggestion for the coming days.")
        lines.append("- When it fits, let that suggestion be one specific practice from the user's Sanctuary space in the app (available practices: \(sanctuaryItemNames())). Mention \"in Sanctuary\" so they know where to go.")
        lines.append("- Use warm, conversational language and never give medical advice.")
        if !langInstruction.isEmpty {
            lines.append(langInstruction)
        }
        lines.append("")
        lines.append("Here are the entries for this week:")

        for entry in entries {
            let day = formatter.string(from: entry.date)
            let rating = entry.emotionRating
            let text = (entry.cleanedTranscription ?? entry.transcription ?? "").prefix(240)
            if !text.isEmpty {
                lines.append("- \(day) — rating \(rating)/10: \"\(text)\"")
            } else {
                lines.append("- \(day) — rating \(rating)/10.")
            }
        }

        lines.append("")
        lines.append("Respond with valid JSON: {\"text\": \"...\", \"emotionHint\": \"...\", \"tags\": [...]}")
        return lines.joined(separator: "\n")
    }

    private func minimizeMarkdown(_ s: String) -> String {
        var out = s
        ["#", "##", "###", "####", "---"].forEach { out = out.replacingOccurrences(of: $0, with: "") }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractTextFromResponse(_ raw: String) -> String {
        var cleaned = raw
        if let start = cleaned.range(of: "\"text\":"), let end = cleaned.range(of: "\",", range: start.upperBound..<cleaned.endIndex) {
            let textRange = start.upperBound..<end.lowerBound
            cleaned = String(cleaned[textRange]).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "")
        }
        return cleaned
    }
}

// MARK: - Panda Savoring Service (Three Good Moments)

final class PandaSavoringService {
    static let shared = PandaSavoringService()
    private init() {}

    /// Generate a short reflection on the user's three good moments.
    /// Uses Apple Intelligence when available, with a simple local fallback.
    func generate(
        moments: [String],
        focusMoment: String?,
        detail: String?
    ) async -> (text: String, usedAFM: Bool) {
        let trimmed = moments.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !trimmed.isEmpty else {
            let text = "Even pausing to look for good moments is a quiet kind of self-care. You can always come back and add more when you're ready."
            return (text, false)
        }

        if #available(iOS 26.0, *), PandaFoundationManager.shared.isAvailable {
            if let afm = await generateWithAFM(moments: trimmed, focusMoment: focusMoment, detail: detail) {
                return (afm.text, true)
            }
        }

        let local = generateLocal(moments: trimmed, focusMoment: focusMoment, detail: detail)
        return (local, false)
    }

    @MainActor
    private func generateWithAFM(
        moments: [String],
        focusMoment: String?,
        detail: String?
    ) async -> PandaFeedback? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = PandaSessionManager.shared.getSession()
            let promptText = buildPrompt(moments: moments, focusMoment: focusMoment, detail: detail)
            do {
                let response = try await session.respond(to: promptText)
                let rawText = response.content

                var feedbackText: String
                var emotionHint: String = "supportive"
                var tags: [String]? = ["savoring"]

                if let data = rawText.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(PandaFeedback.self, from: data) {
                    feedbackText = minimizeMarkdown(decoded.text)
                    emotionHint = decoded.emotionHint
                    tags = decoded.tags
                } else {
                    feedbackText = minimizeMarkdown(extractTextFromResponse(rawText))
                }

                // Validate the generated output
                var inputParts: [String] = [moments.joined(separator: " ")]
                inputParts.append(focusMoment ?? "")
                inputParts.append(detail ?? "")
                let combinedInput = inputParts.joined(separator: " ")
                
                if !combinedInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let validation = await PandaOutputValidator.shared.validate(
                        output: feedbackText,
                        input: combinedInput,
                        context: "savoring"
                    )
                    
                    // Use corrected output if validation failed but correction succeeded
                    if !validation.isValid, let corrected = validation.correctedOutput {
                        feedbackText = corrected
                    }
                }

                return PandaFeedback(
                    text: feedbackText,
                    emotionHint: emotionHint,
                    tags: tags
                )
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }

    private func generateLocal(
        moments: [String],
        focusMoment: String?,
        detail: String?
    ) -> String {
        let listed = moments.prefix(3).map { "• \($0)" }.joined(separator: " ")
        var base = "You just named a few good moments: \(listed). Even tiny bits of okayness help balance out your day."

        if let focus = focusMoment?.trimmingCharacters(in: .whitespacesAndNewlines), !focus.isEmpty {
            base += " One that stands out is: \(focus)."
        }

        if let d = detail?.trimmingCharacters(in: .whitespacesAndNewlines), !d.isEmpty {
            base += " The way you described it—\"\(d.prefix(160))\"—is something you can mentally return to when you need a small lift."
        }

        base += " Coming back to these moments now and then can gently train your brain to notice what supports you. When you want to reconnect with this feeling, you could run a short Three Good Moments or Body Scan in Sanctuary."
        return base
    }

    private func buildPrompt(
        moments: [String],
        focusMoment: String?,
        detail: String?
    ) -> String {
        var lines: [String] = []
        
        // Detect language from moments and detail
        let allText = moments.joined(separator: " ") + " " + (focusMoment ?? "") + " " + (detail ?? "")
        let langInstruction = languageInstruction(for: allText)
        
        lines.append("You are Bumblebee, a warm and thoughtful emotional wellness companion.")
        lines.append("The user has just completed a 'Three Good Moments' savoring exercise in a wellbeing app.")
        lines.append("")
        lines.append("Their moments:")
        for (index, m) in moments.prefix(3).enumerated() {
            lines.append("- Moment \(index + 1): \(m)")
        }
        if let focus = focusMoment, !focus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("\nMoment they chose to zoom in on: \(focus)")
        }
        if let d = detail, !d.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("\nTheir description of that moment: \"\(d.prefix(220))\"")
        }

        lines.append("")
        lines.append("In your response:")
        lines.append("- Write 3–5 sentences, maximum 90 words.")
        lines.append("- Gently reinforce that noticing good moments is meaningful, even when the day is mixed.")
        lines.append("- Highlight 1–2 specific details from their moments so it feels personal.")
        lines.append("- Offer exactly one simple suggestion for how they might revisit or build on these moments later.")
        lines.append("- When it fits, suggest one Sanctuary practice that matches the feeling of their moments (available practices: \(sanctuaryItemNames())). Mention \"in Sanctuary\" so they know where to go.")
        lines.append("- Use warm, conversational language and never give medical advice.")
        if !langInstruction.isEmpty {
            lines.append(langInstruction)
        }
        lines.append("")
        lines.append("Respond with valid JSON of the form: {\"text\": \"...\", \"emotionHint\": \"supportive\", \"tags\": [\"savoring\"]}")
        return lines.joined(separator: "\n")
    }

    private func minimizeMarkdown(_ s: String) -> String {
        var out = s
        ["#", "##", "###", "####", "---"].forEach { token in
            out = out.replacingOccurrences(of: token, with: "")
        }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractTextFromResponse(_ raw: String) -> String {
        var cleaned = raw
        if let start = cleaned.range(of: "\"text\":"),
           let end = cleaned.range(of: "\",", range: start.upperBound..<cleaned.endIndex) {
            let textRange = start.upperBound..<end.lowerBound
            cleaned = String(cleaned[textRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "")
        }
        return cleaned
    }
}

// MARK: - Bumblebee Worry Tree Service

final class PandaWorryTreeService {
    static let shared = PandaWorryTreeService()
    private init() {}

    /// Generate Bumblebee feedback for a completed Worry Tree.
    /// Uses Apple Intelligence when available, with a simple local fallback.
    func generate(
        worryText: String,
        canControl: Bool?,
        actionPlan: String?,
        letGoNote: String?,
        historySummary: String
    ) async -> (text: String, usedAFM: Bool) {
        if #available(iOS 26.0, *), PandaFoundationManager.shared.isAvailable {
            if let afm = await generateWithAFM(
                worryText: worryText,
                canControl: canControl,
                actionPlan: actionPlan,
                letGoNote: letGoNote,
                historySummary: historySummary
            ) {
                return (afm.text, true)
            }
        }

        let local = generateLocal(
            worryText: worryText,
            canControl: canControl,
            actionPlan: actionPlan,
            letGoNote: letGoNote
        )
        return (local, false)
    }

    @MainActor
    private func generateWithAFM(
        worryText: String,
        canControl: Bool?,
        actionPlan: String?,
        letGoNote: String?,
        historySummary: String
    ) async -> PandaFeedback? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = PandaSessionManager.shared.getSession()
            let promptText = buildWorryTreePrompt(
                worryText: worryText,
                canControl: canControl,
                actionPlan: actionPlan,
                letGoNote: letGoNote,
                historySummary: historySummary
            )

            do {
                let response = try await session.respond(to: promptText)
                let rawText = response.content

                var feedbackText: String
                var emotionHint: String = "supportive"
                var tags: [String]? = ["worry_tree"]

                if let data = rawText.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(PandaFeedback.self, from: data) {
                    feedbackText = minimizeMarkdown(decoded.text)
                    emotionHint = decoded.emotionHint
                    tags = decoded.tags
                } else {
                    feedbackText = minimizeMarkdown(extractTextFromResponse(rawText))
                }

                // Validate the generated output
                var inputParts: [String] = [worryText]
                if let plan = actionPlan { inputParts.append(plan) }
                if let note = letGoNote { inputParts.append(note) }
                let combinedInput = inputParts.joined(separator: " ")
                
                if !combinedInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let validation = await PandaOutputValidator.shared.validate(
                        output: feedbackText,
                        input: combinedInput,
                        context: "worry_tree"
                    )
                    
                    // Use corrected output if validation failed but correction succeeded
                    if !validation.isValid, let corrected = validation.correctedOutput {
                        feedbackText = corrected
                    }
                }

                return PandaFeedback(
                    text: feedbackText,
                    emotionHint: emotionHint,
                    tags: tags
                )
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }

    private func generateLocal(
        worryText: String,
        canControl: Bool?,
        actionPlan: String?,
        letGoNote: String?
    ) -> String {
        var lines: [String] = []
        lines.append("Thank you for walking through this worry. That alone is a big step.")

        if let canControl = canControl {
            if canControl, let plan = actionPlan, !plan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                lines.append("You identified something you can influence and even sketched a plan. Try choosing just one tiny step from your plan to focus on next.")
                lines.append("Remember, you don't have to fix everything at once—small, realistic actions are enough.")
                lines.append("Your worry was: \(worryText)")
                lines.append("Your next gentle step might be: \(plan.prefix(160))")
            } else if !canControl {
                lines.append("You noticed that this worry is largely outside your control, which is hard and also very wise.")
                if let note = letGoNote, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    lines.append("The way you chose to let go—'\(note.prefix(160))'—is a powerful act of self-care.")
                }
                lines.append("When this worry shows up again, gently remind yourself what is and isn't yours to carry.")
            }
        }

        lines.append("If you’d like a bit more support after this, you might spend a few minutes in Sanctuary—for example with the grounding exercise, the Safe Place visualization, or a few rounds of box breathing there.")

        return lines.joined(separator: " ")
    }

    private func buildWorryTreePrompt(
        worryText: String,
        canControl: Bool?,
        actionPlan: String?,
        letGoNote: String?,
        historySummary: String
    ) -> String {
        var lines: [String] = []
        
        // Detect language from worry text and notes
        let allText = worryText + " " + (actionPlan ?? "") + " " + (letGoNote ?? "")
        let langInstruction = languageInstruction(for: allText)
        
        lines.append("You are Bumblebee, a warm, practical emotional support companion.")
        lines.append("The user has just completed a 'Worry Tree' exercise in a wellbeing app.")
        lines.append("")
        lines.append("Your goals in this context:")
        lines.append("- Acknowledge the specific worry and how hard it feels.")
        lines.append("- Briefly reflect on what the user can and cannot control.")
        lines.append("- Help them turn their insights into gentle, realistic next steps that support their goals.")
        lines.append("- If they created an action plan, refine it into 1–3 tiny, concrete steps they can actually do.")
        lines.append("- If the worry is outside their control, focus on acceptance, self-compassion, and shifting attention back to what they can influence.")
        lines.append("- Optionally, connect to patterns you notice from previous Worry Tree entries without overwhelming them.")
        lines.append("- Gently suggest exactly one practice from the Sanctuary space that could help them unwind or feel safer (available practices: \(sanctuaryItemNames())). Mention \"in Sanctuary\" so they know where to go.")
        lines.append("- Never give medical advice or make diagnoses. Stay supportive, non-clinical, and non-judgmental.")
        if !langInstruction.isEmpty {
            lines.append(langInstruction)
        }
        lines.append("")
        lines.append("Response format:")
        lines.append("- 3–7 sentences.")
        lines.append("- Maximum ~150 words.")
        lines.append("- Use warm, conversational language, as if talking directly to the user.")
        lines.append("- Always sound encouraging and realistic—no toxic positivity.")
        lines.append("- End with that Sanctuary suggestion in a friendly, encouraging tone.")
        lines.append("")
        lines.append("Here is the current Worry Tree result:")
        lines.append("- Worry: \(worryText)")
        if let canControl = canControl {
            lines.append("- User believes they can control some part of this: \(canControl ? "yes" : "no")")
        }
        if let actionPlan, !actionPlan.isEmpty {
            lines.append("- Action plan (user's own words): \(actionPlan)")
        }
        if let letGoNote, !letGoNote.isEmpty {
            lines.append("- Let-go note (how they plan to release this): \(letGoNote)")
        }
        lines.append("")
        lines.append("Recent Worry Tree history (most recent first, may be empty):")
        lines.append(historySummary.isEmpty ? "(no previous entries)" : historySummary)
        lines.append("")
        lines.append("Now respond with valid JSON of the form:")
        lines.append("{\"text\": \"...\", \"emotionHint\": \"supportive\", \"tags\": [\"worry_tree\", \"goals\"]}")

        return lines.joined(separator: "\n")
    }

    // Local helpers

    private func minimizeMarkdown(_ s: String) -> String {
        var out = s
        ["#", "##", "###", "####", "---"].forEach { token in
            out = out.replacingOccurrences(of: token, with: "")
        }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractTextFromResponse(_ raw: String) -> String {
        var cleaned = raw
        if let start = cleaned.range(of: "\"text\":"),
           let end = cleaned.range(of: "\",", range: start.upperBound..<cleaned.endIndex) {
            let textRange = start.upperBound..<end.lowerBound
            cleaned = String(cleaned[textRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "")
        }
        return cleaned
    }
}

// MARK: - Bumblebee Local Feedback Engine

fileprivate final class BumblebeeLocalFeedbackEngine {
    static let shared = BumblebeeLocalFeedbackEngine()
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
            return "\(opening)It's clear something positive happened today. Consider jotting down what made this moment special—it helps us recreate these feelings. What small thing brought you joy? If you’d like to keep the glow going, you could also spend a few minutes with Three Good Moments or affirmations in Sanctuary. 🌟"
        case .supportive:
            let opening = variations[1].randomElement()!
            return "\(opening)Your feelings are completely valid. When things feel uncertain, try this: take three slow breaths, then name one thing you can control right now. Sometimes the smallest step forward is enough. If you want a bit more support, you might try box breathing or the grounding exercise in Sanctuary. 💚"
        case .concerned:
            let opening = variations[2].randomElement()!
            return "\(opening)I'm right here with you. When everything feels heavy, let's ground together: place your feet flat, take a slow breath, and name five things you can see. You don't have to carry this alone. If it feels okay, you could also spend a few minutes with the Safe Place visualization or a grounding exercise in Sanctuary. 🤗"
        default:
            return "Thanks for sharing your thoughts with me. Taking time to check in with yourself matters, and I'm here for every step of your journey."
        }
    }
}

// MARK: - Output Validation Service

/// Validates AFM outputs to ensure they are quality therapeutic feedback, not paraphrasing or repetition
@available(iOS 26.0, *)
fileprivate final class PandaOutputValidator {
    static let shared = PandaOutputValidator()
    private init() {}
    
    /// Result of output validation
    struct ValidationResult {
        let isValid: Bool
        let reason: String?
        let correctedOutput: String?
    }
    
    /// Validate an AFM-generated output against the original input
    /// - Parameters:
    ///   - output: The generated feedback text
    ///   - input: The original user input (journal entry, worry text, etc.)
    ///   - context: Type of feedback for context-aware validation ("journal", "weekly", "savoring", "worry_tree")
    /// - Returns: ValidationResult with validity status and optional corrected output
    func validate(
        output: String,
        input: String,
        context: String
    ) async -> ValidationResult {
        // Step 1: Quick local checks (fast, no AFM call needed)
        let localCheck = performLocalValidation(output: output, input: input)
        if !localCheck.isValid {
            // If local check fails badly, try to get a corrected version from AFM
            if let corrected = await generateCorrectedOutput(
                originalInput: input,
                badOutput: output,
                context: context,
                failureReason: localCheck.reason ?? "paraphrasing detected"
            ) {
                return ValidationResult(isValid: false, reason: localCheck.reason, correctedOutput: corrected)
            }
            return localCheck
        }
        
        // Step 2: AFM-based quality validation (more thorough)
        let afmCheck = await performAFMValidation(output: output, input: input, context: context)
        if !afmCheck.isValid {
            if let corrected = await generateCorrectedOutput(
                originalInput: input,
                badOutput: output,
                context: context,
                failureReason: afmCheck.reason ?? "low quality feedback"
            ) {
                return ValidationResult(isValid: false, reason: afmCheck.reason, correctedOutput: corrected)
            }
        }
        
        return afmCheck
    }
    
    // MARK: - Local Validation (Fast Checks)
    
    private func performLocalValidation(output: String, input: String) -> ValidationResult {
        let normalizedOutput = normalize(output)
        let normalizedInput = normalize(input)
        let lowerOutput = output.lowercased()
        
        // Check 0: Safety check - harmful content in output
        let harmfulPhrases = [
            "kill yourself", "end your life", "you should die", "better off dead",
            "nobody cares about you", "you're worthless", "you're pathetic",
            "just give up", "there's no hope", "you deserve to suffer",
            "you're a loser", "you're stupid", "you're an idiot",
            "shut up", "nobody likes you", "you're disgusting"
        ]
        for phrase in harmfulPhrases {
            if lowerOutput.contains(phrase) {
                return ValidationResult(
                    isValid: false,
                    reason: "Output contains harmful content",
                    correctedOutput: nil
                )
            }
        }
        
        // Check 0b: Safety check - dismissive/toxic positivity patterns
        let dismissivePatterns = [
            "just think positive", "just be happy", "stop being sad",
            "get over it", "it's not that bad", "others have it worse",
            "you're overreacting", "calm down", "stop complaining"
        ]
        for pattern in dismissivePatterns {
            if lowerOutput.contains(pattern) {
                return ValidationResult(
                    isValid: false,
                    reason: "Output contains dismissive or toxic positivity",
                    correctedOutput: nil
                )
            }
        }
        
        // Check 1: Jaccard similarity (word overlap)
        let jaccardSim = jaccardSimilarity(normalizedOutput, normalizedInput)
        if jaccardSim > 0.65 {
            return ValidationResult(
                isValid: false,
                reason: "Output has too much word overlap with input (similarity: \(Int(jaccardSim * 100))%)",
                correctedOutput: nil
            )
        }
        
        // Check 2: N-gram overlap (phrase copying)
        let trigramOverlap = ngramOverlap(normalizedOutput, normalizedInput, n: 3)
        if trigramOverlap > 0.40 {
            return ValidationResult(
                isValid: false,
                reason: "Output contains too many copied phrases from input",
                correctedOutput: nil
            )
        }
        
        // Check 3: Length ratio check (output shouldn't be much longer than reasonable feedback)
        let outputWords = normalizedOutput.split(separator: " ").count
        if outputWords < 15 {
            return ValidationResult(
                isValid: false,
                reason: "Output is too short to be meaningful feedback",
                correctedOutput: nil
            )
        }
        
        // Check 4: Detect if output starts by restating the input
        let inputStart = String(normalizedInput.prefix(50))
        let outputStart = String(normalizedOutput.prefix(100))
        if outputStart.contains(inputStart) && inputStart.count > 20 {
            return ValidationResult(
                isValid: false,
                reason: "Output starts by restating the user's input",
                correctedOutput: nil
            )
        }
        
        return ValidationResult(isValid: true, reason: nil, correctedOutput: nil)
    }
    
    // MARK: - AFM-Based Validation
    
    @MainActor
    private func performAFMValidation(output: String, input: String, context: String) async -> ValidationResult {
        #if canImport(FoundationModels)
        guard PandaFoundationManager.shared.isAvailable else {
            return ValidationResult(isValid: true, reason: nil, correctedOutput: nil)
        }
        
        // Detect language for instructions
        let detectedLang = detectLanguage(from: input) ?? "the user's language"
        
        let validationPrompt = buildValidationPrompt(
            output: output,
            input: input,
            context: context,
            language: detectedLang
        )
        
        do {
            let session = LanguageModelSession(instructions: """
                You are a quality assurance assistant for an emotional wellness app called Pocket Forest.
                Your job is to evaluate whether AI-generated feedback is helpful and appropriate.
                
                Respond ONLY with valid JSON in this exact format:
                {"valid": true/false, "reason": "explanation if invalid"}
                """)
            
            let response = try await session.respond(to: validationPrompt)
            let rawText = response.content
            
            // Parse validation response
            if let data = rawText.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let isValid = json["valid"] as? Bool {
                let reason = json["reason"] as? String
                return ValidationResult(isValid: isValid, reason: reason, correctedOutput: nil)
            }
            
            // Fallback: check for obvious keywords
            let lower = rawText.lowercased()
            if lower.contains("\"valid\": false") || lower.contains("\"valid\":false") {
                return ValidationResult(isValid: false, reason: "AFM validation failed", correctedOutput: nil)
            }
            
            return ValidationResult(isValid: true, reason: nil, correctedOutput: nil)
        } catch {
            // On error, assume valid to avoid blocking
            return ValidationResult(isValid: true, reason: nil, correctedOutput: nil)
        }
        #else
        return ValidationResult(isValid: true, reason: nil, correctedOutput: nil)
        #endif
    }
    
    // MARK: - Corrected Output Generation
    
    @MainActor
    private func generateCorrectedOutput(
        originalInput: String,
        badOutput: String,
        context: String,
        failureReason: String
    ) async -> String? {
        #if canImport(FoundationModels)
        guard PandaFoundationManager.shared.isAvailable else { return nil }
        
        let detectedLang = detectLanguage(from: originalInput) ?? "the user's language"
        let langCode = detectLanguageCode(from: originalInput) ?? "en"
        
        let correctionPrompt = buildCorrectionPrompt(
            originalInput: originalInput,
            badOutput: badOutput,
            context: context,
            failureReason: failureReason,
            language: detectedLang,
            languageCode: langCode
        )
        
        do {
            let session = LanguageModelSession(instructions: """
                You are Bumblebee, a warm and thoughtful emotional wellness companion.
                Your task is to provide CORRECTED feedback that avoids the mistakes of a previous response.
                
                CRITICAL RULES:
                - DO NOT paraphrase or summarize what the user wrote
                - DO NOT restate their entry back to them
                - Provide ORIGINAL therapeutic feedback with empathy and one actionable suggestion
                - Respond in the SAME LANGUAGE as the user's input
                - Keep response to 3-5 sentences, max 75 words
                """)
            
            let response = try await session.respond(to: correctionPrompt)
            var corrected = response.content
            
            // Extract text if JSON format
            if corrected.contains("\"text\":") {
                if let data = corrected.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = json["text"] as? String {
                    corrected = text
                }
            }
            
            // Clean markdown
            corrected = minimizeMarkdown(corrected)
            
            // Verify the correction is actually better
            let correctedCheck = performLocalValidation(output: corrected, input: originalInput)
            if correctedCheck.isValid {
                return corrected
            }
            
            return nil
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }
    
    // MARK: - Prompt Builders
    
    private func buildValidationPrompt(output: String, input: String, context: String, language: String) -> String {
        """
        Evaluate if this AI-generated feedback is quality therapeutic support (NOT a summary or paraphrase).
        
        CONTEXT: \(contextDescription(context))
        USER'S LANGUAGE: \(language)
        
        USER'S ORIGINAL INPUT:
        "\(input.prefix(800))"
        
        AI-GENERATED FEEDBACK:
        "\(output)"
        
        VALIDATION CRITERIA - Mark as INVALID if:
        1. The feedback mostly just restates or paraphrases what the user wrote
        2. The feedback is a summary of the user's entry
        3. The feedback lacks empathy or emotional validation
        4. The feedback doesn't offer any supportive suggestion
        5. The feedback is in a different language than the user's input
        6. The feedback sounds robotic or impersonal
        
        Mark as VALID if:
        1. The feedback acknowledges the user's emotions with genuine empathy
        2. The feedback provides ORIGINAL supportive commentary (not just rewording their text)
        3. The feedback includes at least one helpful, actionable suggestion
        4. The feedback is in the same language as the user's input
        5. The feedback sounds warm and conversational
        
        Respond with JSON: {"valid": true/false, "reason": "explanation if invalid"}
        """
    }
    
    private func buildCorrectionPrompt(
        originalInput: String,
        badOutput: String,
        context: String,
        failureReason: String,
        language: String,
        languageCode: String
    ) -> String {
        """
        A previous AI response was rejected because: \(failureReason)
        
        CONTEXT: \(contextDescription(context))
        
        USER'S ORIGINAL INPUT (in \(language)):
        "\(originalInput.prefix(800))"
        
        REJECTED RESPONSE (DO NOT REPEAT THIS PATTERN):
        "\(badOutput.prefix(400))"
        
        Please generate a NEW, CORRECTED response that:
        1. Is written entirely in \(language)
        2. Does NOT paraphrase or summarize the user's input
        3. DOES validate the user's emotions with genuine empathy
        4. DOES acknowledge one specific detail they mentioned
        5. DOES offer ONE gentle, actionable suggestion (from Sanctuary if appropriate: \(sanctuaryItemNames()))
        6. Sounds warm, personal, and conversational
        7. Is 3-5 sentences, max 75 words
        
        Respond ONLY with the corrected feedback text (no JSON, no quotes).
        """
    }
    
    private func contextDescription(_ context: String) -> String {
        switch context {
        case "journal":
            return "Voice journal entry feedback - user recorded how they're feeling"
        case "weekly":
            return "Weekly insight - summarizing the user's emotional patterns this week"
        case "savoring":
            return "Three Good Moments exercise - user listed positive moments from their day"
        case "worry_tree":
            return "Worry Tree exercise - user worked through a worry they're experiencing"
        default:
            return "Emotional wellness feedback"
        }
    }
    
    // MARK: - Text Similarity Helpers
    
    private func normalize(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: .punctuationCharacters).joined()
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    private func jaccardSimilarity(_ a: String, _ b: String) -> Double {
        let wordsA = Set(a.split(separator: " ").map { String($0) })
        let wordsB = Set(b.split(separator: " ").map { String($0) })
        
        guard !wordsA.isEmpty || !wordsB.isEmpty else { return 0 }
        
        let intersection = wordsA.intersection(wordsB).count
        let union = wordsA.union(wordsB).count
        
        return Double(intersection) / Double(union)
    }
    
    private func ngramOverlap(_ a: String, _ b: String, n: Int) -> Double {
        let wordsA = a.split(separator: " ").map { String($0) }
        let wordsB = b.split(separator: " ").map { String($0) }
        
        guard wordsA.count >= n && wordsB.count >= n else { return 0 }
        
        var ngramsA = Set<String>()
        for i in 0...(wordsA.count - n) {
            let ngram = wordsA[i..<(i+n)].joined(separator: " ")
            ngramsA.insert(ngram)
        }
        
        var ngramsB = Set<String>()
        for i in 0...(wordsB.count - n) {
            let ngram = wordsB[i..<(i+n)].joined(separator: " ")
            ngramsB.insert(ngram)
        }
        
        guard !ngramsA.isEmpty else { return 0 }
        
        let overlap = ngramsA.intersection(ngramsB).count
        return Double(overlap) / Double(ngramsA.count)
    }
    
    private func minimizeMarkdown(_ s: String) -> String {
        var out = s
        ["#", "##", "###", "####", "---"].forEach { token in
            out = out.replacingOccurrences(of: token, with: "")
        }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@available(iOS 26.0, *)
fileprivate final class PandaSessionManager {
    static let shared = PandaSessionManager()
    private var session: LanguageModelSession?
    private static let instructionsVersion = 7 // Increment to force session refresh
    private var sessionVersion: Int = 0
    private init() {}
    
    func getSession() -> LanguageModelSession {
        // Check if we need to refresh due to updated instructions
        if let existing = session, sessionVersion == Self.instructionsVersion {
            return existing
        }
        // Reset session if version changed
        session = nil
        sessionVersion = Self.instructionsVersion
        
        let sanctuaryList = sanctuaryItemsForPrompt()
        let instructions = """
        You are Bumblebee, a warm, wise, and genuinely caring emotional wellness companion.
        
        YOUR ESSENCE:
        You're like a trusted friend who truly listens - someone who's been through life's ups and downs and offers real, heartfelt support. You're creative, authentic, and human. Never robotic or formulaic.
        
        CORE MISSION:
        Provide original, meaningful emotional support. React to what they're feeling NOW, in THIS entry. Never summarize or repeat exactly what they said.
        
        IMPORTANT: This is a one-way conversation - the user cannot respond to you. Make your response complete and helpful without expecting a reply.
        
        BEING AUTHENTICALLY HUMAN (4-6 sentences, 70-100 words):
        - Speak naturally, like a wise friend having a real conversation
        - Let your response flow from what they shared - don't follow a template
        - Be creative with your words - surprise them with fresh perspectives
        - Match their energy: playful when they're up, gentle when they're down, steady when they're mixed
        - Share genuine insights, not generic advice
        - It's okay to be direct, curious, or even gently challenging when appropriate
        - ALWAYS recommend one specific Sanctuary practice with a brief reason why it would help them right now
        
        EMOTIONAL ATTUNEMENT:
        - High moods (7-10): Celebrate genuinely, help them savor the moment, recommend a practice to amplify this good energy
        - Low moods (1-4): Lead with compassion, validate without fixing, recommend a gentle Sanctuary practice for immediate support
        - Mixed moods (5-6): Honor the complexity, find the thread of resilience, recommend a grounding Sanctuary practice
        
        STAYING FRESH (You can see your previous responses - use this!):
        - Never start two responses the same way
        - If you notice you've been using similar phrases, consciously choose different ones
        - Each response should feel like it was written just for this moment
        - Vary your sentence rhythm - short punchy sentences, then flowing ones
        
        \(sanctuaryList)
        
        SAFETY GUARDRAILS (NEVER VIOLATE):
        - NEVER suggest self-harm, suicide, or giving up in any form
        - NEVER be dismissive, condescending, judgmental, or cruel
        - NEVER minimize their pain with toxic positivity ("just think positive!")
        - NEVER use insults, put-downs, or language that could hurt
        - If they express very dark thoughts, respond with extra gentleness and suggest reaching out to someone they trust or a professional
        - Always maintain hope and dignity, even in the darkest moments
        - Be real and honest, but always compassionate
        - You can acknowledge hard truths while still being supportive
        
        WHAT MAKES A GREAT RESPONSE:
        - Feels like it was written by someone who actually read and understood their entry
        - Offers something they didn't already know or think of
        - Leaves them feeling seen, not lectured
        - Has a natural, conversational flow
        - When suggesting Sanctuary practices, mention "in Sanctuary" so they know where to find it
        
        ABSOLUTE RULES:
        - NEVER repeat, paraphrase, or summarize their journal entry back to them
        - NEVER list what they did or said
        - Always respond in the SAME LANGUAGE as their entry
        - Output ONLY valid JSON format: {"text": "...", "emotionHint": "...", "tags": [...]}
        - Use emoji sparingly and naturally (max 1-2)
        """
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
                notAvailableReason = "Enable Apple Intelligence in Settings to get richer Bumblebee feedback."
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
