//
//  CustomButton.swift
//  pocket-garden
//
//  Reusable Button Components
//

import SwiftUI

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            Theme.Haptics.medium()
            action()
        }) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                    }

                    Text(title)
                        .font(Typography.button)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
            .background(
                LinearGradient(
                    colors: isDisabled ? [Color.gray.opacity(0.5)] : [Color.primaryGreen, Color.primaryGreen.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(CornerRadius.md)
            .shadow(color: isDisabled ? .clear : Color.primaryGreen.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(isDisabled || isLoading)
        .pressAnimation()
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isDisabled: Bool = false

    init(
        _ title: String,
        icon: String? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            action()
        }) {
            HStack(spacing: Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }

                Text(title)
                    .font(Typography.button)
            }
            .foregroundColor(.primaryGreen)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
            .background(Color.primaryGreen.opacity(0.1))
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.primaryGreen.opacity(0.3), lineWidth: 1.5)
            )
        }
        .disabled(isDisabled)
        .pressAnimation()
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let size: CGFloat
    let color: Color
    let action: () -> Void

    init(
        icon: String,
        size: CGFloat = 44,
        color: Color = .primaryGreen,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: {
            Theme.Haptics.light()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(color.opacity(0.1))
                .clipShape(Circle())
        }
        .pressAnimation()
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 64

    var body: some View {
        Button(action: {
            Theme.Haptics.medium()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    LinearGradient(
                        colors: [Color.primaryGreen, Color.primaryGreen.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color.primaryGreen.opacity(0.4), radius: 12, y: 6)
        }
        .pressAnimation(scale: 0.92)
    }
}

// MARK: - Tag Button

struct TagButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            Theme.Haptics.selection()
            action()
        }) {
            Text(text)
                .font(Typography.callout)
                .foregroundColor(isSelected ? .white : .primaryGreen)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(isSelected ? Color.primaryGreen : Color.primaryGreen.opacity(0.1))
                .cornerRadius(CornerRadius.circular)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.circular)
                        .stroke(Color.primaryGreen.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        }
        .pressAnimation()
    }
}

// MARK: - Previews

#Preview("Buttons") {
    VStack(spacing: Spacing.lg) {
        PrimaryButton("Save Entry", icon: "checkmark") {
            print("Primary tapped")
        }

        PrimaryButton("Loading...", isLoading: true) {
            print("Loading")
        }

        PrimaryButton("Disabled", isDisabled: true) {
            print("Disabled")
        }

        SecondaryButton("Cancel", icon: "xmark") {
            print("Secondary tapped")
        }

        HStack(spacing: Spacing.md) {
            IconButton(icon: "heart") {
                print("Heart tapped")
            }

            IconButton(icon: "star.fill", color: .accentGold) {
                print("Star tapped")
            }

            FloatingActionButton(icon: "plus") {
                print("FAB tapped")
            }
        }

        HStack(spacing: Spacing.sm) {
            TagButton(text: "Happy", isSelected: true) {
                print("Tag tapped")
            }

            TagButton(text: "Calm", isSelected: false) {
                print("Tag tapped")
            }

            TagButton(text: "Grateful", isSelected: false) {
                print("Tag tapped")
            }
        }
    }
    .padding()
    .background(Color.backgroundCream)
}
