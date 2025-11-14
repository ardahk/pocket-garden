//
//  RecordingButton.swift
//  pocket-garden
//
//  Beautiful Recording Button with Animations
//

import SwiftUI

struct RecordingButton: View {
    let isRecording: Bool
    let isTranscribing: Bool
    let action: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var pulseAnimation = false

    var body: some View {
        Button(action: {
            Theme.Haptics.medium()
            action()
        }) {
            ZStack {
                // Pulse rings when recording
                if isRecording {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(buttonColor.opacity(0.4), lineWidth: 3)
                            .frame(width: 100, height: 100)
                            .scaleEffect(pulseAnimation ? 1.4 + (CGFloat(index) * 0.2) : 1.0)
                            .opacity(pulseAnimation ? 0 : 0.7)
                            .animation(
                                .easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3),
                                value: pulseAnimation
                            )
                    }
                }

                // Main button circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(scale)
                    .shadow(color: buttonColor.opacity(0.4), radius: isRecording ? 16 : 8)

                // Icon
                buttonIcon
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(light: "FFFFFF", dark: "2A2A2E"))

                // Transcribing indicator
                if isTranscribing && !isRecording {
                    VStack(spacing: 4) {
                        PulsingDotsLoader()
                    }
                    .offset(y: 50)
                }
            }
        }
        .disabled(isTranscribing && !isRecording)
        .onChange(of: isRecording) { _, newValue in
            pulseAnimation = newValue
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isTranscribing {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            scale = 0.95
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        scale = 1.0
                    }
                }
        )
    }

    // MARK: - Button Appearance

    private var buttonColor: Color {
        if isRecording {
            return .errorRed
        } else if isTranscribing {
            return .gray
        } else {
            return .primaryGreen
        }
    }

    private var gradientColors: [Color] {
        if isRecording {
            return [Color.errorRed, Color.errorRed.opacity(0.8)]
        } else if isTranscribing {
            return [Color.gray, Color.gray.opacity(0.8)]
        } else {
            return [Color.primaryGreen, Color.primaryGreen.opacity(0.8)]
        }
    }

    private var buttonIcon: some View {
        Group {
            if isRecording {
                Image(systemName: "stop.fill")
            } else if isTranscribing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(light: "FFFFFF", dark: "2A2A2E")))
            } else {
                Image(systemName: "mic.fill")
            }
        }
    }
}

// MARK: - Recording Timer

struct RecordingTimer: View {
    let seconds: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Pulsing red dot
            Circle()
                .fill(Color.errorRed)
                .frame(width: 12, height: 12)
                .opacity(0.0)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: seconds
                )
                .onAppear {
                    // Trigger animation
                }

            // Time display
            Text(timeString)
                .font(Typography.title3)
                .foregroundColor(.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(
            Capsule()
                .fill(Color.cardBackground)
        )
        .cardShadow()
    }

    private var timeString: String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Previews

#Preview("Recording Button") {
    VStack(spacing: Spacing.xxxl) {
        // Ready to record
        VStack {
            RecordingButton(isRecording: false, isTranscribing: false) {
                print("Start recording")
            }
            Text("Ready to Record")
                .font(Typography.callout)
                .foregroundColor(.textSecondary)
        }

        // Recording
        VStack {
            RecordingButton(isRecording: true, isTranscribing: false) {
                print("Stop recording")
            }
            Text("Recording...")
                .font(Typography.callout)
                .foregroundColor(.errorRed)
        }

        // Transcribing
        VStack {
            RecordingButton(isRecording: false, isTranscribing: true) {
                print("Transcribing")
            }
            Text("Transcribing...")
                .font(Typography.callout)
                .foregroundColor(.textSecondary)
        }
    }
    .padding()
    .background(Color.backgroundCream)
}

#Preview("Recording Timer") {
    VStack(spacing: Spacing.lg) {
        RecordingTimer(seconds: 0)
        RecordingTimer(seconds: 45)
        RecordingTimer(seconds: 125)
    }
    .padding()
    .background(Color.backgroundCream)
}
