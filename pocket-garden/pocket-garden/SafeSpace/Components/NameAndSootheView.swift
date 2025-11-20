import SwiftUI
import Inject

struct NameAndSootheView: View {
    @ObserveInjection var inject

    let duration: Int
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var selectedEmotion: String? = nil
    @State private var customEmotion: String = ""
    @State private var selectedBodyArea: String? = nil

    @Environment(\.dismiss) private var dismiss

    private let emotions = [
        "Anxious",
        "Sad",
        "Overwhelmed",
        "Stressed",
        "Numb",
        "Mixed"
    ]

    private let bodyAreas = [
        "Head",
        "Throat",
        "Chest",
        "Stomach",
        "Hands",
        "Whole body"
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.backgroundCream,
                    Color.mint.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Name & Soothe")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)

                    Text("A quick pause to name what you feel and respond with kindness")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text("~\(duration) min")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary.opacity(0.8))
                }
                .padding(.top, 40)
                .padding(.bottom, 24)

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.mint : Color.borderColor)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 32)

                Spacer()

                stepContent
                    .padding(.horizontal, 24)

                Spacer()

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .enableInjection()
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            emotionStep
        case 1:
            bodyStep
        default:
            sootheStep
        }
    }

    private var emotionStep: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.mint.opacity(0.3),
                                Color.mint.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 140
                        )
                    )
                    .frame(width: 220, height: 220)

                Circle()
                    .fill(Color.mint.opacity(0.2))
                    .frame(width: 130, height: 130)

                Image(systemName: "face.smiling")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.mint)
            }

            VStack(spacing: 16) {
                Text("Name what you feel")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Text("Putting feelings into words can help your brain turn down the alarm and make emotions feel more manageable.")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(emotions, id: \.self) { emotion in
                        emotionChip(for: emotion, isSelected: selectedEmotion == emotion)
                    }
                }

                TextField("Or type your own word", text: $customEmotion)
                    .padding(12)
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )
            }
        }
    }

    private var bodyStep: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.mint.opacity(0.3),
                                Color.mint.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 140
                        )
                    )
                    .frame(width: 220, height: 220)

                Circle()
                    .fill(Color.mint.opacity(0.2))
                    .frame(width: 130, height: 130)

                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.mint)
            }

            VStack(spacing: 16) {
                Text("Notice it in your body")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Text("Gently scan for where you feel this most. Noticing sensations brings you back into your body.")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(bodyAreas, id: \.self) { area in
                    bodyChip(for: area, isSelected: selectedBodyArea == area)
                }
            }
        }
    }

    private var sootheStep: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.mint.opacity(0.35),
                                Color.mint.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 140
                        )
                    )
                    .frame(width: 220, height: 220)

                Circle()
                    .fill(Color.mint.opacity(0.25))
                    .frame(width: 130, height: 130)

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.mint)
            }

            VStack(spacing: 16) {
                Text("Offer yourself kindness")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Text(soothingMessage)
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                Image("panda_supportive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)

                Text("Let this sentence be something you could gently say to a close friend who felt the same way.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
            )
        }
    }

    @ViewBuilder
    private var controls: some View {
        VStack(spacing: 12) {
            if currentStep < 2 {
                Button(action: nextStep) {
                    Text("Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(canGoForward ? Color.mint : Color.gray)
                        )
                }
                .disabled(!canGoForward)
                .buttonStyle(.plain)
            } else {
                Button(action: finish) {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.primaryGreen)
                        )
                }
                .buttonStyle(.plain)
            }

            if currentStep > 0 {
                Button(action: goBack) {
                    Text("Back")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var canGoForward: Bool {
        switch currentStep {
        case 0:
            return selectedEmotion != nil || !customEmotion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1:
            return selectedBodyArea != nil
        default:
            return true
        }
    }

    private var emotionLabel: String {
        let trimmedCustom = customEmotion.trimmingCharacters(in: .whitespacesAndNewlines)
        if let selectedEmotion {
            return selectedEmotion.lowercased()
        } else if !trimmedCustom.isEmpty {
            return trimmedCustom.lowercased()
        } else {
            return "this feeling"
        }
    }

    private var bodyLabel: String {
        if let selectedBodyArea {
            return selectedBodyArea.lowercased()
        } else {
            return "your body"
        }
    }

    private var soothingMessage: String {
        "It makes sense to feel \(emotionLabel) right now, especially with everything on your mind. Notice how it shows up in \(bodyLabel), and see if you can soften that area just a little. You deserve kindness while you feel this."
    }

    private func emotionChip(for emotion: String, isSelected: Bool) -> some View {
        Button(action: {
            selectedEmotion = emotion
        }) {
            Text(emotion)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Color.mint : Color.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.mint.opacity(0.15) : Color.cardBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.mint : Color.borderColor.opacity(0.6), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func bodyChip(for area: String, isSelected: Bool) -> some View {
        Button(action: {
            selectedBodyArea = area
        }) {
            Text(area)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Color.mint : Color.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.mint.opacity(0.15) : Color.cardBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.mint : Color.borderColor.opacity(0.6), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func nextStep() {
        guard canGoForward else { return }
        withAnimation {
            if currentStep < 2 {
                currentStep += 1
            }
        }
    }

    private func goBack() {
        withAnimation {
            if currentStep > 0 {
                currentStep -= 1
            }
        }
    }

    private func finish() {
        onComplete()
        dismiss()
    }
}

#Preview {
    NameAndSootheView(duration: 3) {
        print("Name & Soothe completed")
    }
}
