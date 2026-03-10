import SwiftUI

struct SplashScreen: View {
    @State private var pulseScale: CGFloat = 0.8
    @State private var pulseOpacity: Double = 0.6

    var body: some View {
        ZStack {
            FFColors.primaryNavy.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Shield icon with animated pulse
                ZStack {
                    Circle()
                        .stroke(FFColors.accentCyan.opacity(0.3), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)

                    Circle()
                        .stroke(FFColors.accentCyan.opacity(0.15), lineWidth: 1.5)
                        .frame(width: 130, height: 130)
                        .scaleEffect(pulseScale * 0.9)
                        .opacity(pulseOpacity * 0.7)

                    Image(systemName: "shield.checkered")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(FFColors.accentCyan)
                }

                // Wordmark
                VStack(spacing: 4) {
                    Text("FormFlow")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundColor(FFColors.textPrimary)

                    Text("Workflows & Signatures")
                        .font(FFTypography.bodyMedium())
                        .foregroundColor(FFColors.textSecondary)
                }

                Spacer()

                // Version
                Text("v1.0.0")
                    .font(FFTypography.mono())
                    .foregroundColor(FFColors.textSecondary.opacity(0.5))
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
                pulseOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreen()
}
