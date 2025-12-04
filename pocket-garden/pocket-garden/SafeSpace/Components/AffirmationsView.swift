import SwiftUI
import Inject

struct AffirmationsView: View {
    @ObserveInjection var inject

    let duration: Int // minutes
    let onComplete: () -> Void

    @State private var currentIndex = 0
    @State private var allAffirmations: [Affirmation] = []
    @State private var affirmations: [Affirmation] = []
    @State private var dragOffset: CGSize = .zero
    @State private var hasSwiped: Bool = false
    @State private var shufflesRemainingToday: Int = 10 // Interpreted as swipes remaining today
    @State private var showDailyIntro: Bool = false
    @State private var showInfoSheet: Bool = false
    
    // Soft rose accent for affirmations theme
    private let affirmationAccent = Color(red: 0.94, green: 0.54, blue: 0.60)
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background gradient with a gentle rose tint (dark mode compatible)
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground),
                    Color(UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark
                            ? UIColor(red: 0.18, green: 0.12, blue: 0.14, alpha: 1.0)
                            : UIColor(red: 1.0, green: 0.93, blue: 0.95, alpha: 1.0)
                    })
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Spacer()

                        Text("Gentle Affirmations")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textPrimary)

                        Button {
                            showInfoSheet = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(affirmationAccent.opacity(0.9))
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }

                    Text("Speak kindly to yourself")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 16)

                if showDailyIntro {
                    Spacer()
                    introView
                    Spacer()
                } else {
                    Spacer()

                    // Affirmation cards
                    ZStack {
                        // Show next 2 cards in background for depth
                        ForEach(Array(affirmations.enumerated()), id: \.element.id) { index, affirmation in
                            if index >= currentIndex && index < currentIndex + 3 {
                                AffirmationCard(
                                    affirmation: affirmation,
                                    offset: index - currentIndex
                                )
                                .offset(dragOffset)
                                .rotationEffect(.degrees(Double(dragOffset.width) / 20))
                                .opacity(index == currentIndex ? 1.0 : 0.5)
                                .scaleEffect(index == currentIndex ? 1.0 : 0.95 - CGFloat(index - currentIndex) * 0.05)
                                .offset(y: CGFloat(index - currentIndex) * 10)
                                .zIndex(Double(affirmations.count - index))
                                .gesture(
                                    index == currentIndex ? DragGesture()
                                        .onChanged { value in
                                            dragOffset = value.translation
                                        }
                                        .onEnded { value in
                                            handleSwipe(value: value)
                                        }
                                    : nil
                                )
                            }
                        }
                    }
                    .frame(height: 400)
                    .padding(.horizontal, 24)

                    Spacer()

                    // Instructions
                    VStack(spacing: 16) {
                        if !hasSwiped {
                            HStack(spacing: 12) {
                                Image("panda_supportive")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)

                                Text("Swipe left or right to move through today's affirmations")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cardBackground)
                            )
                            .padding(.horizontal, 24)
                        }

                        Text("\(shufflesRemainingToday) swipe\(shufflesRemainingToday == 1 ? "" : "s") left today")
                            .font(.caption2)
                            .foregroundStyle(Color.textSecondary.opacity(0.8))

                        // Done button
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
                                        .fill(affirmationAccent)
                                )
                        }
                        .padding(.horizontal, 24)
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            setupAffirmations()
        }
        .sheet(isPresented: $showInfoSheet) {
            affirmationsInfoSheet
        }
        .enableInjection()
    }

    // MARK: - Intro & Setup

    private var introView: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                Image("panda_supportive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's gentle affirmations")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)

                    Text("Here are 10 kind thoughts picked for you today. Swipe slowly and let each one sink in.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("How it works")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)

                Text("• You get up to 10 affirmation swipes each day.\n• Move forward with a gentle swipe left.\n• You can always swipe right to revisit a card you've already seen.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color.cardBackground.opacity(0.6))
            .cornerRadius(16)
            .padding(.horizontal, 24)

            Button(action: {
                showDailyIntro = false
            }) {
                Text("Show Today's Affirmations")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(affirmationAccent)
                    )
            }
            .padding(.horizontal, 24)
            .buttonStyle(.plain)
        }
    }

    // Short science explainer for affirmations
    private var affirmationsInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Why this exercise helps")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)

                    Text("Gentle affirmations invite you to focus on values and self-worth instead of only on flaws or mistakes. Writing or repeating kind statements about yourself can soften self-criticism, reduce defensiveness, and make it easier to take healthy actions.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Self-affirmation research shows that brief value-based reflection exercises can lower stress responses, improve openness to health messages, and support behavior change in areas like physical activity and medical adherence.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)

                        if let url = URL(string: "https://pubmed.ncbi.nlm.nih.gov/24405362/") {
                            Link("Cohen & Sherman, 2014 – The psychology of change: self-affirmation and social psychological intervention", destination: url)
                                .font(.subheadline)
                                .foregroundStyle(affirmationAccent)
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
                    .foregroundStyle(affirmationAccent)
                }
            }
        }
    }

    private func setupAffirmations() {
        allAffirmations = Affirmation.defaultAffirmations
        loadShuffleCount()
        affirmations = allAffirmations.shuffled()
        currentIndex = 0
    }
    
    private func loadShuffleCount() {
        let today = Calendar.current.startOfDay(for: Date())
        let defaults = UserDefaults.standard
        
        if let lastDate = defaults.object(forKey: "lastAffirmationShuffleDate") as? Date,
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            shufflesRemainingToday = max(0, defaults.integer(forKey: "affirmationShufflesRemaining"))
            showDailyIntro = false
        } else {
            shufflesRemainingToday = 10
            defaults.set(today, forKey: "lastAffirmationShuffleDate")
            defaults.set(10, forKey: "affirmationShufflesRemaining")
            showDailyIntro = true
        }
    }
    
    private func decrementShuffleCount() {
        shufflesRemainingToday = max(0, shufflesRemainingToday - 1)
        UserDefaults.standard.set(shufflesRemainingToday, forKey: "affirmationShufflesRemaining")
    }

    // MARK: - Swipe Handling

    private func handleSwipe(value: DragGesture.Value) {
        let swipeThreshold: CGFloat = 100

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if abs(value.translation.width) > swipeThreshold {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()

                hasSwiped = true

                if value.translation.width < 0 {
                    // Swipe left - next affirmation
                    if currentIndex < affirmations.count - 1 && shufflesRemainingToday > 0 {
                        currentIndex += 1
                        decrementShuffleCount()
                    }
                } else {
                    // Swipe right - previous affirmation
                    if currentIndex > 0 {
                        currentIndex -= 1
                    }
                }
            }
            dragOffset = .zero
        }
    }
}

struct AffirmationCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Color.primaryGreen : Color.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.primaryGreen.opacity(0.15) : Color.cardBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.primaryGreen : Color.borderColor.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Affirmation Card

struct AffirmationCard: View {
    let affirmation: Affirmation
    let offset: Int

    var body: some View {
        VStack(spacing: 24) {
            // Category badge
            Text(affirmation.category.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(categoryColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(categoryColor.opacity(0.15))
                )

            // Affirmation text
            Text(affirmation.text)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 32)

            Spacer()

            // Decorative element
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [categoryColor.opacity(0.6), categoryColor.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
        )
    }

    private var categoryColor: Color {
        switch affirmation.category {
        case .safety: return .blue
        case .strength: return .orange
        case .peace: return .green
        case .selfCompassion: return .pink
        case .present: return .purple
        case .resilience: return .red
        }
    }
}

#Preview {
    AffirmationsView(duration: 2) {
        print("Affirmations completed")
    }
}
