import SwiftUI

// MARK: - FormFlow Design System
// Industrial-utilitarian meets precision engineering. Dark-first. Clean. Authoritative.

enum FFColors {
    // Primary palette
    static let primaryNavy = Color(hex: "0A1628")
    static let accentCyan = Color(hex: "00D4FF")
    static let success = Color(hex: "00C896")
    static let warning = Color(hex: "FFB800")
    static let danger = Color(hex: "FF4444")

    // Surfaces
    static let surface = Color(hex: "131F35")
    static let surfaceElevated = Color(hex: "1C2D47")
    static let border = Color(hex: "2A3F5F")

    // Text
    static let textPrimary = Color(hex: "F0F4FF")
    static let textSecondary = Color(hex: "8BA3C7")

    // Tab bar
    static let tabInactive = Color(hex: "4A6080")

    // Audit trail
    static let auditFieldChange = Color(hex: "4488FF")

    // Role colors
    static let roleAdmin = Color(hex: "FF6B6B")
    static let roleManager = Color(hex: "FFB800")
    static let roleWorker = Color(hex: "00D4FF")
    static let roleViewer = Color(hex: "8BA3C7")
}

enum FFTypography {
    // Display / Headings
    static func displayLarge() -> Font { .system(size: 34, weight: .bold, design: .default) }
    static func displayMedium() -> Font { .system(size: 28, weight: .bold, design: .default) }
    static func displaySmall() -> Font { .system(size: 22, weight: .semibold, design: .default) }

    // Body
    static func bodyLarge() -> Font { .system(size: 17, weight: .regular, design: .default) }
    static func bodyMedium() -> Font { .system(size: 15, weight: .regular, design: .default) }
    static func bodySmall() -> Font { .system(size: 13, weight: .regular, design: .default) }
    static func bodyMediumBold() -> Font { .system(size: 15, weight: .medium, design: .default) }

    // Monospace (hashes, IDs, timestamps)
    static func mono() -> Font { .system(size: 13, weight: .regular, design: .monospaced) }
    static func monoSmall() -> Font { .system(size: 11, weight: .regular, design: .monospaced) }

    // Labels
    static func label() -> Font { .system(size: 12, weight: .medium, design: .default) }
    static func labelLarge() -> Font { .system(size: 14, weight: .semibold, design: .default) }
}

enum FFLayout {
    static let minTapTarget: CGFloat = 48 // Glove-safe, exceeds Apple's 44pt standard
    static let cornerRadius: CGFloat = 12
    static let cornerRadiusSmall: CGFloat = 8
    static let spacing: CGFloat = 16
    static let spacingSmall: CGFloat = 8
    static let spacingLarge: CGFloat = 24
    static let borderWidth: CGFloat = 1
    static let cardPadding: CGFloat = 16
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

struct FFCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(FFLayout.cardPadding)
            .background(FFColors.surfaceElevated)
            .cornerRadius(FFLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: FFLayout.cornerRadius)
                    .stroke(FFColors.border, lineWidth: FFLayout.borderWidth)
            )
    }
}

struct FFPrimaryButtonModifier: ViewModifier {
    var isEnabled: Bool = true

    func body(content: Content) -> some View {
        content
            .font(FFTypography.bodyMediumBold())
            .foregroundColor(FFColors.primaryNavy)
            .frame(maxWidth: .infinity)
            .frame(minHeight: FFLayout.minTapTarget)
            .background(isEnabled ? FFColors.accentCyan : FFColors.border)
            .cornerRadius(FFLayout.cornerRadius)
    }
}

struct FFDestructiveButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(FFTypography.bodyMediumBold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: FFLayout.minTapTarget)
            .background(FFColors.danger)
            .cornerRadius(FFLayout.cornerRadius)
    }
}

struct FFSecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(FFTypography.bodyMediumBold())
            .foregroundColor(FFColors.accentCyan)
            .frame(maxWidth: .infinity)
            .frame(minHeight: FFLayout.minTapTarget)
            .background(Color.clear)
            .cornerRadius(FFLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: FFLayout.cornerRadius)
                    .stroke(FFColors.accentCyan, lineWidth: FFLayout.borderWidth)
            )
    }
}

extension View {
    func ffCard() -> some View {
        modifier(FFCardModifier())
    }

    func ffPrimaryButton(isEnabled: Bool = true) -> some View {
        modifier(FFPrimaryButtonModifier(isEnabled: isEnabled))
    }

    func ffDestructiveButton() -> some View {
        modifier(FFDestructiveButtonModifier())
    }

    func ffSecondaryButton() -> some View {
        modifier(FFSecondaryButtonModifier())
    }
}
