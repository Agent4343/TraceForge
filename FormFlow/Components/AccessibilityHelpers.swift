import SwiftUI

// MARK: - Accessibility Modifiers

extension View {
    /// Apply FormFlow accessibility enhancements
    func ffAccessible(label: String, hint: String? = nil, value: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
    }

    /// Conditionally apply reduce motion preferences
    func ffAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        self.modifier(ReduceMotionModifier(animation: animation, value: value))
    }
}

struct ReduceMotionModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        if reduceMotion {
            content.animation(.none, value: value)
        } else {
            content.animation(animation, value: value)
        }
    }
}

// MARK: - Accessible Status Badge

struct AccessibleStatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        StatusBadge(text, color: color)
            .accessibilityLabel("Status: \(text)")
    }
}

// MARK: - Accessible Step Progress

struct AccessibleStepProgressBar: View {
    let totalSteps: Int
    let completedSteps: Int
    let currentStep: Int

    var body: some View {
        StepProgressBar(totalSteps: totalSteps, completedSteps: completedSteps, currentStep: currentStep)
            .accessibilityLabel("Step \(currentStep) of \(totalSteps)")
            .accessibilityValue("\(completedSteps) steps completed")
    }
}

// MARK: - Dynamic Type Support

struct DynamicTypeText: View {
    let text: String
    let font: Font
    let color: Color
    let lineLimit: Int?

    init(_ text: String, font: Font = FFTypography.bodyMedium(), color: Color = FFColors.textPrimary, lineLimit: Int? = nil) {
        self.text = text
        self.font = font
        self.color = color
        self.lineLimit = lineLimit
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .lineLimit(lineLimit)
            .minimumScaleFactor(0.7) // Allow text to scale down if needed
            .fixedSize(horizontal: false, vertical: true) // Prevent truncation on critical labels
    }
}

// MARK: - Accessible Signature Canvas

struct AccessibleSignatureCanvas: View {
    @Binding var signatureImage: UIImage?
    @Binding var isEmpty: Bool

    var body: some View {
        SignatureCanvasView(signatureImage: $signatureImage, isEmpty: $isEmpty)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isEmpty ? "Signature canvas, empty" : "Signature canvas, signed")
            .accessibilityHint("Draw your signature on this canvas")
            .accessibilityAddTraits(.allowsDirectInteraction)
            .accessibilityAction(named: "Clear signature") {
                signatureImage = nil
                isEmpty = true
            }
    }
}

// MARK: - High Contrast Support

struct HighContrastBorder: ViewModifier {
    @Environment(\.colorSchemeContrast) var contrast

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: FFLayout.cornerRadius)
                    .stroke(
                        contrast == .increased ? FFColors.textPrimary.opacity(0.5) : FFColors.border,
                        lineWidth: contrast == .increased ? 2 : 1
                    )
            )
    }
}

extension View {
    func ffHighContrastBorder() -> some View {
        modifier(HighContrastBorder())
    }
}

// MARK: - Reduce Motion Transition

extension AnyTransition {
    static var ffTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity
        )
    }

    static var ffReducedMotionTransition: AnyTransition {
        .opacity
    }
}

// MARK: - Accessible Photo Input

extension EnhancedPhotoInput {
    func accessibilityConfigured() -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Photo capture area")
    }
}
