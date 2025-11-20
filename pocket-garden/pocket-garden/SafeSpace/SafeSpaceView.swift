import SwiftUI
import SwiftData
import Inject

struct SafeSpaceView: View {
    @ObserveInjection var inject

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: SafeSpaceViewModel
    @State private var selectedActivity: CalmActivity?
    @State private var dragOffset: CGFloat = 0

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
                            Text("Sanctuary")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(Color.textPrimary)
                                .padding(.top, 20)
                            
                            Text("A quiet place to pause and reset")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        }

                        // Ambient sounds
                        ambientSoundsSection

                        // Quick practices Grid
                        quickPracticesSection

                        // Spacer
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only consider downward pulls
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { _ in
                            if dragOffset > 140 {
                                viewModel.endSession()
                                dismiss()
                            }
                            dragOffset = 0
                        }
                )
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
                    .buttonStyle(.plain)
                }
            }
            .onAppear {
                viewModel.startSession(fromEmergency: true)
            }
            .sheet(item: $selectedActivity) { activity in
                activitySheet(for: activity)
            }
        }
        .enableInjection()
    }

    // MARK: - Ambient Sounds Section

    private var ambientSoundsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Soundscape")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AmbientSoundType.allCases) { soundType in
                        SoundBubble(
                            soundType: soundType,
                            isSelected: viewModel.selectedAmbientSound == soundType
                        ) {
                            viewModel.toggleAmbientSound(soundType)
                        }
                    }
                }
                .padding(.vertical, 4) // Space for shadows
            }
        }
    }

    // MARK: - Quick Practices Section

    private var quickPracticesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Practices")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(CalmActivity.allActivities) { activity in
                    PracticeGridCard(activity: activity) {
                        selectedActivity = activity
                        viewModel.startActivity(activity)
                    }
                }
            }
        }
    }

    // MARK: - Activity Sheet

    @ViewBuilder
    private func activitySheet(for activity: CalmActivity) -> some View {
        switch activity.type {
        case .breathing:
            BreathingExerciseView(
                pattern: .boxBreathing,
                duration: activity.duration
            ) {
                viewModel.completeActivity(activity)
                selectedActivity = nil
            }

        case .grounding:
            GroundingTechniqueView {
                viewModel.completeActivity(activity)
                selectedActivity = nil
            }

        case .bodyScan:
            BodyScanView {
                viewModel.completeActivity(activity)
                selectedActivity = nil
            }

        case .affirmations:
            AffirmationsView(duration: activity.duration) {
                viewModel.completeActivity(activity)
                selectedActivity = nil
            }
            
        case .worryTree:
            WorryTreeView {
                viewModel.completeActivity(activity)
                selectedActivity = nil
            }
            
        case .butterflyHug:
            ButterflyHugView(duration: activity.duration) {
                viewModel.completeActivity(activity)
                selectedActivity = nil
            }
            
        case .visualization:
            SafePlaceView(duration: activity.duration) {
                viewModel.completeActivity(activity)
                selectedActivity = nil
            }
        
        case .nameAndSoothe:
            NameAndSootheView(duration: activity.duration) {
                viewModel.completeActivity(activity)
                selectedActivity = nil
            }

        case .lovingKindness:
            PlaceholderActivityView(activity: activity) {
                viewModel.completeActivity(activity)
                selectedActivity = nil
            }
        }
    }
}

// MARK: - Components

struct SoundBubble: View {
    let soundType: AmbientSoundType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.primaryGreen : Color.white)
                        .frame(width: 60, height: 60)
                    
                    if isSelected {
                        Circle()
                            .stroke(Color.primaryGreen.opacity(0.3), lineWidth: 4)
                            .frame(width: 68, height: 68)
                    }

                    Image(systemName: soundType.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? .white : Color.textSecondary)
                }
                
                Text(soundType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? Color.primaryGreen : Color.textSecondary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(width: 80)
    }
}

struct PracticeGridCard: View {
    let activity: CalmActivity
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(activity.color.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: activity.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(activity.color)
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("\(activity.duration) min")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(16)
            .frame(height: 130, alignment: .topLeading) // Fixed height for grid
            .background(Color.cardBackground)
            .cornerRadius(20)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PlaceholderActivityView: View {
    let activity: CalmActivity
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(activity.color.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: activity.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(activity.color)
            }
            
            VStack(spacing: 8) {
                Text(activity.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(activity.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: onComplete) {
                Text("Complete")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryGreen)
                    .cornerRadius(16)
            }
            .padding()
        }
    }
}

// MARK: - Preview

#Preview {
    SafeSpaceView()
        .modelContainer(for: [CalmSession.self, EmotionEntry.self])
}
