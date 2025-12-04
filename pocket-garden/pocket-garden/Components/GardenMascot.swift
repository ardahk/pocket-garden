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
        }
        if !recentHints.isEmpty {
            lines.append("\nYour recent replies (vary your wording and avoid repeating these):")
            recentHints.prefix(3).forEach { lines.append("- \($0.prefix(150))") }
        }
        lines.append("\nRespond with valid JSON: {\"text\": \"...\", \"emotionHint\": \"...\", \"tags\": [...]}")
        return lines.joined(separator: "\n")
    }

    private func instructionsText() -> String {
        "You are Bumblebee, a warm and thoughtful emotional wellness companion. Read the user's emotion rating and journal entry carefully. In your response (3–5 sentences, max 75 words):\n1. Always take the emotion rating into account together with the text.\n2. If the rating is 8, 9, or 10 out of 10, the overall tone MUST be clearly celebratory and proud. You may briefly acknowledge remaining stress, but focus mainly on what went well and why the user feels capable or hopeful.\n3. If the rating is 4–7, use a balanced, supportive tone that recognizes both difficulties and strengths.\n4. If the rating is 1–3, use a very gentle, compassionate tone and avoid minimizing their experience.\n5. Acknowledge at least one concrete detail they mentioned so it feels specific.\n6. Offer exactly one gentle, actionable suggestion (no long lists).\n7. When it fits, let that suggestion be one specific practice from the user's Sanctuary space in the app (for example: box breathing, the grounding exercise, Body Scan, Three Good Moments, Worry Tree, Butterfly Hug, Safe Place visualization, or affirmations). Mention \"in Sanctuary\" so they know where to go.\n8. Use warm, conversational language and vary your phrasing each time.\n9. Never diagnose, give medical advice, or repeat recent responses.\n\nMake it feel personal and genuine, not scripted."
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

                if let data = rawText.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(PandaFeedback.self, from: data) {
                    return PandaFeedback(
                        text: minimizeMarkdown(decoded.text),
                        emotionHint: decoded.emotionHint,
                        tags: decoded.tags
                    )
                }

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

        lines.append("You are Bumblebee, a warm and thoughtful emotional wellness companion.")
        lines.append("You are reading the user's journal entries for this week so far (from the start of the week up to today). In your response:")
        lines.append("- Write 3–6 sentences, maximum 120 words.")
        lines.append("- Clearly refer to 'this week' or 'this week so far'.")
        lines.append("- Acknowledge at least one concrete detail from their entries so it feels specific.")
        lines.append("- Describe any noticeable pattern in how they have been feeling.")
        lines.append("- Offer exactly one gentle, actionable suggestion for the coming days.")
        lines.append("- When it fits, let that suggestion be one specific practice from the user's Sanctuary space in the app (for example: box breathing, the grounding exercise, Body Scan, Three Good Moments, Worry Tree, Butterfly Hug, Safe Place visualization, or affirmations). Mention \"in Sanctuary\" so they know where to go.")
        lines.append("- Use warm, conversational language and never give medical advice.")
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

                if let data = rawText.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(PandaFeedback.self, from: data) {
                    return PandaFeedback(
                        text: minimizeMarkdown(decoded.text),
                        emotionHint: decoded.emotionHint,
                        tags: decoded.tags
                    )
                }

                let cleaned = extractTextFromResponse(rawText)
                return PandaFeedback(
                    text: minimizeMarkdown(cleaned),
                    emotionHint: "supportive",
                    tags: ["savoring"]
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
        lines.append("- When it fits, suggest one Sanctuary practice that matches the feeling of their moments (for example: revisiting them with Three Good Moments in Sanctuary, trying a short Body Scan in Sanctuary, or doing a Safe Place visualization there). Mention \"in Sanctuary\" so they know where to go.")
        lines.append("- Use warm, conversational language and never give medical advice.")
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

                if let data = rawText.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode(PandaFeedback.self, from: data) {
                    return PandaFeedback(
                        text: minimizeMarkdown(decoded.text),
                        emotionHint: decoded.emotionHint,
                        tags: decoded.tags
                    )
                }

                let cleaned = extractTextFromResponse(rawText)
                return PandaFeedback(
                    text: minimizeMarkdown(cleaned),
                    emotionHint: "supportive",
                    tags: ["worry_tree"]
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
        lines.append("- Gently suggest exactly one practice from the Sanctuary space that could help them unwind or feel safer (for example: the grounding exercise in Sanctuary, box breathing in Sanctuary, a Safe Place visualization in Sanctuary, or writing another worry in Sanctuary using the Worry Tree).")
        lines.append("- Never give medical advice or make diagnoses. Stay supportive, non-clinical, and non-judgmental.")
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

@available(iOS 26.0, *)
fileprivate final class PandaSessionManager {
    static let shared = PandaSessionManager()
    private var session: LanguageModelSession?
    private init() {}
    
    func getSession() -> LanguageModelSession {
        if let existing = session {
            return existing
        }
        let instructions = "You are Bumblebee, a warm and thoughtful emotional wellness companion. Read the user's journal entry carefully. In your response (3–5 sentences, max 75 words):\n1. Acknowledge something specific they mentioned to show you're listening\n2. Validate their feelings with empathy\n3. Offer one gentle, actionable suggestion\n4. When it fits, let that suggestion be one specific practice from the user's Sanctuary space in the app (for example: box breathing, the grounding exercise, Body Scan, Three Good Moments, Worry Tree, Butterfly Hug, Safe Place visualization, or affirmations). Mention \"in Sanctuary\" so they know where to go.\n5. Use warm, conversational language and vary your phrasing each time\n6. Never diagnose, give medical advice, or repeat recent responses\n\nMake it feel personal and genuine, not scripted."
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
