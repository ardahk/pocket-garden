import SwiftUI
import SwiftData
import Inject

struct SafeSpaceView: View {
    @ObserveInjection var inject

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: SafeSpaceViewModel
    @State private var breathingScale: CGFloat = 1.0
    @State private var showActivity: Bool = false
    @State private var selectedActivity: CalmActivity?

    init(modelContext: ModelContext? = nil) {
        _viewModel = State(initialValue: SafeSpaceViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.backgroundCream,
                        Color.emotionCalm.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 8) {
                            Text("You're Safe Here")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.textPrimary)

                            Text("Take all the time you need")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding(.top, 20)

                        // Breathing circle with panda
                        breathingCircle

                        // Ambient sounds
                        ambientSoundsSection

                        // Quick practices
                        quickPracticesSection

                        // Spacer
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.endSession()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .onAppear {
                viewModel.startSession(fromEmergency: true)
                startBreathingAnimation()
            }
            .sheet(isPresented: $showActivity) {
                activitySheet
            }
        }
        .enableInjection()
    }

    // MARK: - Breathing Circle

    private var breathingCircle: some View {
        VStack(spacing: 24) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.emotionCalm.opacity(0.3),
                                Color.emotionCalm.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 80,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.emotionCalm.opacity(0.6),
                                Color.primaryGreen.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(breathingScale)
                    .shadow(color: Color.emotionCalm.opacity(0.4), radius: 20)

                // Text
                Text(breathingText)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
            }

            // Panda
            Image("panda-supportive")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(Color.cardBackground)
                        .frame(width: 100, height: 100)
                )
                .shadow(color: Color.shadowColor, radius: 8, y: 4)
        }
    }

    private var breathingText: String {
        breathingScale > 1.3 ? "Breathe Out" : "Breathe In"
    }

    // MARK: - Ambient Sounds Section

    private var ambientSoundsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Ambient Sounds")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                // Toggle indicator
                Toggle("", isOn: .constant(viewModel.selectedAmbientSound != .silent))
                    .labelsHidden()
                    .tint(Color.primaryGreen)
                    .disabled(true)
            }

            // Sound options
            HStack(spacing: 12) {
                ForEach(AmbientSoundType.allCases) { soundType in
                    SoundButton(
                        soundType: soundType,
                        isSelected: viewModel.selectedAmbientSound == soundType
                    ) {
                        viewModel.toggleAmbientSound(soundType)
                    }
                }

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowColor, radius: 8, y: 4)
        )
    }

    // MARK: - Quick Practices Section

    private var quickPracticesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Practices")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 12) {
                ForEach(CalmActivity.allActivities) { activity in
                    PracticeCardView(activity: activity) {
                        selectedActivity = activity
                        viewModel.startActivity(activity)
                        showActivity = true
                    }
                }
            }
        }
    }

    // MARK: - Activity Sheet

    @ViewBuilder
    private var activitySheet: some View {
        if let activity = selectedActivity {
            switch activity.type {
            case .breathing:
                BreathingExerciseView(
                    pattern: .boxBreathing,
                    duration: activity.duration
                ) {
                    viewModel.completeActivity(activity)
                }

            case .grounding:
                GroundingTechniqueView {
                    viewModel.completeActivity(activity)
                }

            case .bodyScan:
                BodyScanView {
                    viewModel.completeActivity(activity)
                }

            case .affirmations:
                AffirmationsView(duration: activity.duration) {
                    viewModel.completeActivity(activity)
                }

            default:
                Text("Coming soon!")
            }
        }
    }

    // MARK: - Breathing Animation

    private func startBreathingAnimation() {
        withAnimation(
            .easeInOut(duration: 4.0)
            .repeatForever(autoreverses: true)
        ) {
            breathingScale = 1.5
        }
    }
}

// MARK: - Sound Button Component

struct SoundButton: View {
    let soundType: AmbientSoundType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: soundType.icon)
                    .font(.system(size: 16))

                Text(soundType.rawValue)
                    .font(.subheadline)
            }
            .foregroundStyle(isSelected ? .white : Color.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.primaryGreen : Color.borderColor.opacity(0.3))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    SafeSpaceView()
        .modelContainer(for: [CalmSession.self, EmotionEntry.self])
}
