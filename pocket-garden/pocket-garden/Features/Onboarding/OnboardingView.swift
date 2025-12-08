import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    // Feature Pages
    private let features: [OnboardingFeature] = [
        OnboardingFeature(
            type: .journal,
            title: "Voice Journaling",
            description: "Rate your mood from 1–10, then speak freely. Bumblebee keeps everything on-device and helps you reflect.",
            color: .primaryGreen,
            mascotImage: "panda_welcome"
        ),
        OnboardingFeature(
            type: .sanctuary,
            title: "Your Sanctuary",
            description: "Ground, breathe, and unwind with quick practices like breathing, grounding, gentle affirmations, and more.",
            color: .emotionCalm,
            mascotImage: "panda_sleep"
        ),
        OnboardingFeature(
            type: .forest,
            title: "Grow Your Forest",
            description: "Each day you check in, you water a tree. Over time, your calm habits grow into a peaceful forest.",
            color: .primaryGreen,
            mascotImage: "panda_happy"
        ),
        OnboardingFeature(
            type: .streaks,
            title: "Track Progress",
            description: "See your week as a gentle mood line and keep an eye on your streaks and trees grown.",
            color: Color(red: 1.0, green: 0.82, blue: 0.25), // Bee yellow
            mascotImage: "panda_supportive"
        )
    ]

    var body: some View {
        ZStack {
            Color.backgroundCream
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<features.count, id: \.self) { index in
                        OnboardingPageView(feature: features[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                // Bottom Controls
                VStack(spacing: 32) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<features.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? features[currentPage].color : Color.gray.opacity(0.2))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring, value: currentPage)
                        }
                    }

                    // Buttons
                    VStack(spacing: 16) {
                        Button {
                            withAnimation {
                                if currentPage < features.count - 1 {
                                    currentPage += 1
                                } else {
                                    completeOnboarding()
                                }
                            }
                        } label: {
                            Text(currentPage == features.count - 1 ? "Get Started" : "Continue")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(features[currentPage].color)
                                )
                        }
                        .buttonStyle(.plain) // flat button, no extra shadow

                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
            }
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Data Models

enum FeatureType {
    case journal
    case sanctuary
    case forest
    case streaks
}

struct OnboardingFeature {
    let type: FeatureType
    let title: String
    let description: String
    let color: Color
    let mascotImage: String
}

// MARK: - Page View

struct OnboardingPageView: View {
    let feature: OnboardingFeature

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Feature preview card + mascot
            ZStack(alignment: .bottom) {
                MockPhoneFrame {
                    switch feature.type {
                    case .journal:
                        JournalMockView()
                    case .sanctuary:
                        SanctuaryMockView()
                    case .forest:
                        ForestMockView()
                    case .streaks:
                        StreaksMockView()
                    }
                }
                .padding(.bottom, 40)

                Image(feature.mascotImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 140)
                    .offset(x: 80, y: 20)
            }
            .frame(height: 420)

            // Text content
            VStack(spacing: 12) {
                Text(feature.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(feature.description)
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.top, 20)
    }
}

// MARK: - Phone Frame

struct MockPhoneFrame<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.backgroundCream)
                .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )

            VStack(spacing: 0) {
                // Status bar hint
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 6)
                    .padding(.top, 12)

                Spacer()
            }

            content
                .clipShape(RoundedRectangle(cornerRadius: 32))
        }
        .frame(width: 280, height: 380)
    }
}

// MARK: - Journal Mock

struct JournalMockView: View {
    private let gradientColors: [Color] = [
        .emotionSad,
        .emotionMelancholy,
        .emotionNeutral,
        .emotionContent,
        .emotionJoy
    ]

    var body: some View {
        VStack(spacing: 18) {
            Color.clear.frame(height: 30)
            // Mood header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How are you feeling?")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.textSecondary)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.emotionJoy)
                            .frame(width: 10, height: 10)

                        Text("8 / 10 · Great")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Mini emotion slider with labels
            VStack(alignment: .leading, spacing: 6) {
                Text("Mood from 1 to 10")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.textSecondary.opacity(0.8))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.borderColor)
                            .frame(height: 8)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * 0.8, height: 8)

                        Circle()
                            .fill(Color.cardBackground)
                            .frame(width: 26, height: 26)
                            .overlay(
                                Circle()
                                    .stroke(Color.emotionContent, lineWidth: 2)
                            )
                            .offset(x: geo.size.width * 0.8 - 13)
                    }
                }
                .frame(height: 26)

                HStack {
                    Text("1")
                    Spacer()
                    Text("5")
                    Spacer()
                    Text("10")
                }
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(Color.textSecondary.opacity(0.7))
            }
            .padding(.horizontal, 20)

            // Transcription preview card
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.primaryGreen)

                    Text("Speak it, see it, feel it")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.textSecondary.opacity(0.15))
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.textSecondary.opacity(0.12))
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.textSecondary.opacity(0.09))
                        .frame(width: 120, height: 7)
                }
            }
            .padding(14)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)

            Spacer()

            // Mic button
            ZStack {
                Circle()
                    .fill(Color.primaryGreen.opacity(0.16))
                    .frame(width: 80, height: 80)

                Circle()
                    .fill(Color.primaryGreen)
                    .frame(width: 60, height: 60)

                Image(systemName: "mic.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 36)
        }
    }
}

// MARK: - Sanctuary Mock

struct SanctuaryMockView: View {
    private let icons = ["wind", "leaf.fill", "heart.fill", "tree.fill"]
    private let colors: [Color] = [.blue, .green, .pink, .orange]
    private let titles = ["Breathing", "Grounding", "Gentle Words", "Worry Tree"]
    private let subtitles = ["Guided breath", "5–4–3–2–1", "Affirmations", "Write & release"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Color.clear.frame(height: 30)
            // Header
            Text("Sanctuary")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
                .padding(.leading, 20)
                .padding(.top, 20)

            // Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.cardBackground)
                        .overlay(
                            VStack(alignment: .leading, spacing: 8) {
                                Circle()
                                    .fill(colors[index].opacity(0.15))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: icons[index])
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(colors[index])
                                    )

                                Text(titles[index])
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.textPrimary)

                                Text(subtitles[index])
                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color.textSecondary.opacity(0.7))
                            }
                            .padding(12)
                            , alignment: .topLeading
                        )
                        .frame(height: 100)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.backgroundCream)
    }
}

// MARK: - Forest Mock

struct ForestMockView: View {
    var body: some View {
        ZStack {
            // Sky
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Sun
            Circle()
                .fill(Color(red: 1.0, green: 0.9, blue: 0.4))
                .frame(width: 44, height: 44)
                .blur(radius: 4)
                .position(x: 220, y: 60)
            
            Circle()
                .fill(Color(red: 1.0, green: 0.95, blue: 0.6))
                .frame(width: 32, height: 32)
                .position(x: 220, y: 60)
            
            // Clouds
            OnboardingCloudShape()
                .fill(Color.white.opacity(0.8))
                .frame(width: 60, height: 30)
                .position(x: 60, y: 80)
            
            OnboardingCloudShape()
                .fill(Color.white.opacity(0.6))
                .frame(width: 40, height: 20)
                .position(x: 160, y: 50)
            
            OnboardingCloudShape()
                .fill(Color.white.opacity(0.7))
                .frame(width: 50, height: 25)
                .position(x: 250, y: 100)
            
            // Mountains
            GeometryReader { proxy in
                ZStack {
                    // Back mountain
                    Path { path in
                        let w = proxy.size.width
                        let h = proxy.size.height
                        path.move(to: CGPoint(x: 0, y: h * 0.7))
                        path.addLine(to: CGPoint(x: w * 0.4, y: h * 0.4))
                        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.75))
                        path.addLine(to: CGPoint(x: w, y: h * 0.6))
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.addLine(to: CGPoint(x: 0, y: h))
                        path.closeSubpath()
                    }
                    .fill(Color.gray.opacity(0.2))
                    
                    // Front mountain
                    Path { path in
                        let w = proxy.size.width
                        let h = proxy.size.height
                        path.move(to: CGPoint(x: 0, y: h * 0.8))
                        path.addLine(to: CGPoint(x: w * 0.3, y: h * 0.55))
                        path.addLine(to: CGPoint(x: w * 0.6, y: h * 0.7))
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.addLine(to: CGPoint(x: 0, y: h))
                        path.closeSubpath()
                    }
                    .fill(Color.gray.opacity(0.3))
                    
                    // Hills
                    Ellipse()
                        .fill(Color.primaryGreen.opacity(0.5))
                        .frame(width: proxy.size.width * 1.6, height: 200)
                        .position(x: proxy.size.width * 0.3, y: proxy.size.height * 1.05)
                    
                    Ellipse()
                        .fill(Color.primaryGreen.opacity(0.8))
                        .frame(width: proxy.size.width * 1.4, height: 190)
                        .position(x: proxy.size.width * 0.9, y: proxy.size.height * 1.08)
                }
            }
            
            // Background Trees
            GeometryReader { proxy in
                // Small trees in background
                Image(systemName: "tree.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.primaryGreen.opacity(0.7))
                    .position(x: proxy.size.width * 0.2, y: proxy.size.height * 0.65)
                
                Image(systemName: "tree.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.primaryGreen.opacity(0.6))
                    .position(x: proxy.size.width * 0.75, y: proxy.size.height * 0.62)
                
                Image(systemName: "tree.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.primaryGreen.opacity(0.8))
                    .position(x: proxy.size.width * 0.85, y: proxy.size.height * 0.7)
            }

            VStack(spacing: 12) {
                // Mini stats row
                HStack(spacing: 12) {
                    forestStat(icon: "tree.fill", value: "12", label: "Trees")
                    forestStat(icon: "flame.fill", value: "7", label: "Streak")
                }
                .padding(.top, 38) // Extra padding for status bar since we removed it from frame
                .padding(.horizontal, 20)

                Spacer()

                // Main tree
                ZStack {
                    Ellipse()
                        .fill(Color.primaryGreen.opacity(0.3))
                        .frame(width: 160, height: 60)

                    Image(systemName: "tree.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(Color.primaryGreen)
                        .offset(y: -20)
                }

                Spacer(minLength: 12)

            }
        }
    }

    private func forestStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct OnboardingCloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.2, y: h))
        path.addCurve(to: CGPoint(x: w * 0.2, y: h * 0.4), control1: CGPoint(x: 0, y: h), control2: CGPoint(x: 0, y: h * 0.4))
        path.addCurve(to: CGPoint(x: w * 0.5, y: 0), control1: CGPoint(x: w * 0.2, y: h * 0.1), control2: CGPoint(x: w * 0.35, y: 0))
        path.addCurve(to: CGPoint(x: w * 0.8, y: h * 0.4), control1: CGPoint(x: w * 0.65, y: 0), control2: CGPoint(x: w * 0.8, y: h * 0.1))
        path.addCurve(to: CGPoint(x: w * 0.8, y: h), control1: CGPoint(x: w, y: h * 0.4), control2: CGPoint(x: w, y: h))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Streaks / Progress Mock

struct StreaksMockView: View {
    private let points: [CGFloat] = [0.4, 0.6, 0.35, 0.8, 0.55, 0.9, 0.7]

    var body: some View {
        VStack(spacing: 20) {
            // Summary cards
            HStack(spacing: 16) {
                summaryCard(value: "7", label: "Days")
                summaryCard(value: "12", label: "Trees")
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)

            Spacer(minLength: 8)

            // Line chart approximation
            GeometryReader { geo in
                ZStack {
                    let width = geo.size.width
                    let height = geo.size.height

                    // Horizontal guide lines
                    ForEach(0..<3) { index in
                        let y = height * (CGFloat(index) + 1) / 4
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                        .stroke(Color.textSecondary.opacity(0.12), lineWidth: 1)
                    }

                    // Area under line
                    Path { path in
                        guard let first = points.first else { return }
                        let stepX = width / CGFloat(points.count - 1)
                        path.move(to: CGPoint(x: 0, y: height * (1 - first)))

                        for (index, value) in points.enumerated() {
                            let x = stepX * CGFloat(index)
                            let y = height * (1 - value)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }

                        path.addLine(to: CGPoint(x: width, y: height))
                        path.addLine(to: CGPoint(x: 0, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color.primaryGreen.opacity(0.3), Color.primaryGreen.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line
                    Path { path in
                        guard let first = points.first else { return }
                        let stepX = width / CGFloat(points.count - 1)
                        path.move(to: CGPoint(x: 0, y: height * (1 - first)))

                        for (index, value) in points.enumerated() {
                            let x = stepX * CGFloat(index)
                            let y = height * (1 - value)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(Color.primaryGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    // Points
                    let stepX = width / CGFloat(max(points.count - 1, 1))
                    ForEach(Array(points.enumerated()), id: \.offset) { item in
                        let x = stepX * CGFloat(item.offset)
                        let y = height * (1 - item.element)
                        Circle()
                            .fill(item.offset == points.count - 1 ? Color.emotionJoy : Color.primaryGreen)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
            }
            .frame(height: 130)
            .padding(.horizontal, 24)

            // X-axis labels
            HStack {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.textSecondary.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func summaryCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    OnboardingView()
}

