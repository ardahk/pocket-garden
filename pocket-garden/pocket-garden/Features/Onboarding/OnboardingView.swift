import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @DevObserveInjection var inject: DevInjectionToken
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userFirstName") private var userFirstName = ""
    @State private var currentPage = 0
    @State private var enteredFirstName = ""

    // Feature Pages
    private let features: [OnboardingFeature] = [
        OnboardingFeature(
            type: .welcome,
            title: "Welcome to\nPocket Forest",
            description: "Your cozy corner for self-care, reflection, and growing a little forest of calm 🌿",
            color: Color(red: 0.95, green: 0.75, blue: 0.8), // Soft rose pink
            mascotImage: "panda_welcome"
        ),
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
            mascotImage: "panda_happy"
        ),
        OnboardingFeature(
            type: .privacy,
            title: "Your Privacy, Always",
            description: "Everything stays on your iPhone. No accounts, no cloud, no internet needed. Not even Apple can see your data.",
            color: Color(red: 0.55, green: 0.65, blue: 0.85), // Soft blue for trust
            mascotImage: "panda_supportive"
        ),
        OnboardingFeature(
            type: .name,
            title: "What should I call you?",
            description: "Before we begin, share your first name so Bumblebee can keep feedback personal.",
            color: .accentGold,
            mascotImage: "panda_supportive"
        )
    ]

    // Background color that changes based on current page
    private var backgroundColor: some View {
        // All pages use backgroundCream which adapts to dark mode
        Color.backgroundCream
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<features.count, id: \.self) { index in
                        OnboardingPageView(feature: features[index], enteredFirstName: $enteredFirstName)
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
                            if features[currentPage].type == .name {
                                let trimmedName = sanitizeName(enteredFirstName)
                                guard !trimmedName.isEmpty else { return }
                                enteredFirstName = trimmedName
                                userFirstName = trimmedName
                            }

                            withAnimation {
                                if currentPage < features.count - 1 {
                                    currentPage += 1
                                } else {
                                    completeOnboarding()
                                }
                            }
                        } label: {
                            Text(currentPage == 0 ? "Get Started" : (currentPage == features.count - 1 ? "Get Started" : "Continue"))
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
                        .opacity(isCurrentStepValid ? 1.0 : 0.55)
                        .disabled(!isCurrentStepValid)

                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            enteredFirstName = userFirstName
        }
        .devEnableInjection()
    }

    private var isCurrentStepValid: Bool {
        if features[currentPage].type == .name {
            return !sanitizeName(enteredFirstName).isEmpty
        }
        return true
    }

    private func sanitizeName(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func completeOnboarding() {
        // Complete onboarding without requesting notifications
        // Notifications will be requested after first tree is planted
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Data Models

enum FeatureType {
    case welcome
    case name
    case journal
    case sanctuary
    case forest
    case streaks
    case privacy
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
    @DevObserveInjection var inject: DevInjectionToken
    let feature: OnboardingFeature
    @Binding var enteredFirstName: String

    private var isNameStep: Bool {
        feature.type == .name
    }
    
    // Mascot positioning varies by feature type
    private var mascotOffset: CGSize {
        switch feature.type {
        case .privacy:
            // Move further right and down to not overlap content
            return CGSize(width: 100, height: 50)
        default:
            return CGSize(width: 80, height: 20)
        }
    }
    
    private var mascotHeight: CGFloat {
        switch feature.type {
        case .privacy:
            return 120 // Slightly smaller for privacy screen
        case .name:
            return 0
        default:
            return 140
        }
    }

    var body: some View {
        if isNameStep {
            nameStepBody
        } else {
            regularStepBody
        }
    }

    // MARK: Name Step — matches other pages' visual language
    private var nameStepBody: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                // Bee visual — same role as the phone frame on other pages
                NameBeeVisual()
                    .frame(height: min(geo.size.height * 0.38, 300))

                Spacer(minLength: 0)

                // Title + description + input
                VStack(spacing: 12) {
                    Text(feature.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Text(feature.description)
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("First name")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.textSecondary)

                        TextField("e.g. Arda", text: $enteredFirstName)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .submitLabel(.done)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.textPrimary)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(feature.color.opacity(0.3), lineWidth: 1.5)
                                    )
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                }

                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .devEnableInjection()
    }

    // MARK: Regular Step — unchanged layout
    private var regularStepBody: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack(alignment: .bottom) {
                if feature.type == .welcome {
                    WelcomeMockView()
                } else {
                    MockPhoneFrame {
                        switch feature.type {
                        case .welcome:
                            EmptyView()
                        case .name:
                            EmptyView()
                        case .journal:
                            JournalMockView()
                        case .sanctuary:
                            SanctuaryMockView()
                        case .forest:
                            ForestMockView()
                        case .streaks:
                            StreaksMockView()
                        case .privacy:
                            PrivacyMockView()
                        }
                    }
                    .padding(.bottom, 40)

                    Image(feature.mascotImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: mascotHeight)
                        .offset(mascotOffset)
                }
            }
            .frame(height: 420)

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
        .devEnableInjection()
    }
}

// MARK: - Phone Frame

struct MockPhoneFrame<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            // Base “design size” for our mock phone.
            // We render at this size and scale down *only if needed* so it never overflows
            // on smaller devices (e.g., iPhone mini / 16e) while staying large on bigger phones.
            let baseW: CGFloat = 280
            let baseH: CGFloat = 380
            let scale = min(1, min(geo.size.width / baseW, geo.size.height / baseH))

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

                // Content is laid out at base size and scales together with the frame.
                content
                    .frame(width: baseW, height: baseH, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
            }
            .frame(width: baseW, height: baseH)
            .scaleEffect(scale, anchor: .center)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - Welcome Mock

struct WelcomeMockView: View {
    @State private var floatOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Floating decorative elements (no hearts - using flowers, sparkles, and leaves instead)
            GeometryReader { geo in
                // Soft floating flowers
                FloatingFlower(size: 18, delay: 0)
                    .position(x: geo.size.width * 0.12, y: geo.size.height * 0.18)
                
                FloatingFlower(size: 14, delay: 0.4)
                    .position(x: geo.size.width * 0.88, y: geo.size.height * 0.22)
                
                FloatingFlower(size: 16, delay: 0.7)
                    .position(x: geo.size.width * 0.08, y: geo.size.height * 0.58)
                
                FloatingFlower(size: 12, delay: 1.0)
                    .position(x: geo.size.width * 0.92, y: geo.size.height * 0.52)
                
                // Sparkles
                FloatingSparkle(delay: 0.2)
                    .position(x: geo.size.width * 0.18, y: geo.size.height * 0.38)
                
                FloatingSparkle(delay: 0.5)
                    .position(x: geo.size.width * 0.82, y: geo.size.height * 0.42)
                
                FloatingSparkle(delay: 0.8)
                    .position(x: geo.size.width * 0.22, y: geo.size.height * 0.72)
                
                FloatingSparkle(delay: 1.1)
                    .position(x: geo.size.width * 0.78, y: geo.size.height * 0.68)
                
                // Tiny leaves
                FloatingLeaf(delay: 0.1)
                    .position(x: geo.size.width * 0.72, y: geo.size.height * 0.78)
                
                FloatingLeaf(delay: 0.4)
                    .position(x: geo.size.width * 0.28, y: geo.size.height * 0.82)
                
                FloatingLeaf(delay: 0.6)
                    .position(x: geo.size.width * 0.15, y: geo.size.height * 0.48)
                
                FloatingLeaf(delay: 0.9)
                    .position(x: geo.size.width * 0.85, y: geo.size.height * 0.35)
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Main mascot with soft glow (no hard edges)
                ZStack {
                    // Very soft glow behind mascot - adapts to dark mode
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.backgroundCream.opacity(0.6),
                                    Color.backgroundCream.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 160
                            )
                        )
                        .frame(width: 320, height: 320)
                    
                    // Mascot
                    Image("panda_welcome")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .offset(y: floatOffset)
                }
                
                Spacer()
                
                // Decorative row of mini items
                HStack(spacing: 24) {
                    WelcomeFeatureIcon(emoji: "🌱", label: "Grow")
                    WelcomeFeatureIcon(emoji: "💭", label: "Reflect")
                    WelcomeFeatureIcon(emoji: "✨", label: "Bloom")
                }
                .padding(.bottom, 32)
            }
        }
        .frame(width: 280, height: 380) // Match MockPhoneFrame dimensions for consistency
        .onAppear {
            // Floating animation
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatOffset = -10
            }
        }
    }
}

struct NameBeeVisual: View {
    @DevObserveInjection var inject: DevInjectionToken
    @State private var floatOffset: CGFloat = 0
    @State private var glowScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Outer soft glow — matches WelcomeMockView's radial gradient style
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.accentGold.opacity(0.22),
                            Color.accentGold.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(glowScale)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: glowScale)

            // Inner circle background
            Circle()
                .fill(Color.accentGold.opacity(0.14))
                .frame(width: 180, height: 180)

            // Bee mascot
            Image("panda_supportive")
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .offset(y: floatOffset)
        }
        .onAppear {
            glowScale = 1.15
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                floatOffset = -10
            }
        }
        .devEnableInjection()
    }
}

struct FloatingFlower: View {
    let size: CGFloat
    let delay: Double
    
    @State private var offset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0.5
    
    var body: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: size))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.6, green: 0.8, blue: 0.6),
                        Color(red: 0.5, green: 0.75, blue: 0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(opacity)
            .offset(y: offset)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(delay)) {
                    offset = -6
                    rotation = 15
                    opacity = 0.8
                }
            }
    }
}

struct WelcomeFeatureIcon: View {
    let emoji: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.cardBackground) // Adapts to dark mode
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 3)
                
                Text(emoji)
                    .font(.system(size: 24))
            }
            
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.textSecondary)
        }
    }
}


struct FloatingSparkle: View {
    let delay: Double
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.4
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.accentGold.opacity(0.8))
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(delay)) {
                    scale = 1.2
                    opacity = 0.9
                }
            }
    }
}

struct FloatingLeaf: View {
    let delay: Double
    
    @State private var rotation: Double = -10
    @State private var offset: CGFloat = 0
    
    var body: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 12))
            .foregroundStyle(Color.primaryGreen.opacity(0.6))
            .rotationEffect(.degrees(rotation))
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(delay)) {
                    rotation = 10
                    offset = -6
                }
            }
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
        VStack(spacing: 16) { // Match spacing with other mock views
            Color.clear.frame(height: 30)
            // Mood header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How are you feeling?")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.textSecondary)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.emotionJoy)
                            .frame(width: 10, height: 10)

                        Text("8 / 10 · Great")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
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
                    .font(.system(size: 13, weight: .medium, design: .rounded))
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
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.primaryGreen)

                    Text("Speak it, see it, feel it")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
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

            //Spacer()

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
            .padding(.bottom, 50)
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
        VStack(alignment: .leading, spacing: 14) {
            // Header - reduced top padding to use space better
            Text("Sanctuary")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
                .padding(.leading, 20)
                .padding(.top, 24)

            // Grid - slightly larger spacing for better visual balance
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.cardBackground)
                        .overlay(
                            VStack(alignment: .leading, spacing: 9) {
                                Circle()
                                    .fill(colors[index].opacity(0.15))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: icons[index])
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(colors[index])
                                    )

                                Text(titles[index])
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.textPrimary)

                                Text(subtitles[index])
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color.textSecondary.opacity(0.7))
                            }
                            .padding(14)
                            , alignment: .topLeading
                        )
                        .frame(height: 110)
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
                .font(.title2)
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
        VStack(spacing: 16) { // Match spacing with other mock views
            Color.clear.frame(height: 30) // Match status bar spacing
            // Summary cards
            HStack(spacing: 16) {
                summaryCard(value: "7", label: "Days")
                summaryCard(value: "12", label: "Trees")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20) // Reduced from 30 to match other views

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

// MARK: - Privacy Mock

struct PrivacyMockView: View {
    var body: some View {
        VStack(spacing: 14) {
            // Header - consistent top padding with other mock views
            VStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(red: 0.55, green: 0.65, blue: 0.85))
                
                Text("100% Private")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(.top, 28)
            
            // Privacy features - better spacing and sizing
            VStack(spacing: 10) {
                PrivacyRow(
                    icon: "iphone",
                    iconColor: .primaryGreen,
                    title: "On-Device Only",
                    description: "Stored on your iPhone"
                )
                
                PrivacyRow(
                    icon: "wifi.slash",
                    iconColor: .orange,
                    title: "No Internet",
                    description: "Works fully offline"
                )
                
                PrivacyRow(
                    icon: "person.slash.fill",
                    iconColor: .purple,
                    title: "No Accounts",
                    description: "No sign-up needed"
                )
                
                PrivacyRow(
                    icon: "eye.slash.fill",
                    iconColor: Color(red: 0.55, green: 0.65, blue: 0.85),
                    title: "Invisible",
                    description: "Even Apple can't see it"
                )
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .background(Color.backgroundCream)
    }
}

struct PrivacyRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .truncationMode(.tail)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.textSecondary.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .truncationMode(.tail)
            }
            // Prefer keeping text visible over pushing it out by the trailing check.
            .layoutPriority(1)
            
            Spacer(minLength: 6)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.green.opacity(0.8))
                .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OnboardingView()
}

