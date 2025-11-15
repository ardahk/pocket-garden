import SwiftUI
import Inject

struct PracticeCardView: View {
    @ObserveInjection var inject

    let activity: CalmActivity
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(activity.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: activity.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(activity.color)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)

                    Text("\(activity.duration) minute\(activity.duration == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .enableInjection()
    }
}

// Custom button style for subtle scale effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        PracticeCardView(activity: .breathingExercise) {
            print("Breathing selected")
        }

        PracticeCardView(activity: .groundingTechnique) {
            print("Grounding selected")
        }

        PracticeCardView(activity: .bodyScan) {
            print("Body scan selected")
        }

        PracticeCardView(activity: .gentleAffirmations) {
            print("Affirmations selected")
        }
    }
    .padding()
    .background(Color.backgroundCream)
}
