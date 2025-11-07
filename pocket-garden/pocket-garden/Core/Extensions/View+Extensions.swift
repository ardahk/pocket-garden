//
//  View+Extensions.swift
//  pocket-garden
//
//  SwiftUI View Extensions
//

import SwiftUI

// MARK: - Press Animation

extension View {
    /// Add press animation effect to any view
    func pressAnimation() -> some View {
        self.modifier(PressAnimationModifier())
    }

    /// Add press animation with custom scale
    func pressAnimation(scale: CGFloat) -> some View {
        self.modifier(PressAnimationModifier(scale: scale))
    }
}

struct PressAnimationModifier: ViewModifier {
    @State private var isPressed = false
    var scale: CGFloat = 0.96

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.easeInOut(duration: Theme.Animation.quick), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            Theme.Haptics.light()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

// MARK: - Shimmer Effect

extension View {
    /// Add shimmer loading effect
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

// MARK: - Conditional Modifiers

extension View {
    /// Apply modifier conditionally
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Apply one of two modifiers based on condition
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

// MARK: - Corner Radius

extension View {
    /// Apply rounded corners to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Fade In Animation

extension View {
    /// Fade in animation when appearing
    func fadeIn(duration: Double = 0.3, delay: Double = 0) -> some View {
        self.modifier(FadeInModifier(duration: duration, delay: delay))
    }
}

struct FadeInModifier: ViewModifier {
    let duration: Double
    let delay: Double

    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

// MARK: - Slide In Animation

extension View {
    /// Slide in from bottom when appearing
    func slideInFromBottom(duration: Double = 0.4, delay: Double = 0) -> some View {
        self.modifier(SlideInModifier(duration: duration, delay: delay))
    }
}

struct SlideInModifier: ViewModifier {
    let duration: Double
    let delay: Double

    @State private var offset: CGFloat = 50
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    offset = 0
                    opacity = 1
                }
            }
    }
}

// MARK: - Bordered Style

extension View {
    /// Add border with color
    func bordered(color: Color = .borderColor, width: CGFloat = 1, cornerRadius: CGFloat = CornerRadius.md) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: width)
            )
    }
}

// MARK: - Glow Effect

extension View {
    /// Add colored glow effect
    func glow(color: Color, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.4), radius: radius)
            .shadow(color: color.opacity(0.2), radius: radius * 1.5)
    }
}
