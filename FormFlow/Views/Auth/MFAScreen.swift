import SwiftUI

struct MFAScreen: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var digits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var resendCooldown: Int = 0
    @State private var timer: Timer?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(FFColors.accentCyan)

                        Text("Two-Factor Verification")
                            .font(FFTypography.displaySmall())
                            .foregroundColor(FFColors.textPrimary)

                        Text("Enter the 6-digit code from your authenticator app")
                            .font(FFTypography.bodyMedium())
                            .foregroundColor(FFColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // 6-digit OTP input
                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { index in
                            OTPDigitField(text: $digits[index], isFocused: focusedIndex == index)
                                .focused($focusedIndex, equals: index)
                                .onChange(of: digits[index]) { _, newValue in
                                    handleDigitChange(index: index, value: newValue)
                                }
                        }
                    }
                    .padding(.horizontal, 24)

                    if let error = errorMessage {
                        Text(error)
                            .font(FFTypography.bodySmall())
                            .foregroundColor(FFColors.danger)
                    }

                    // Resend option
                    VStack(spacing: 8) {
                        if resendCooldown > 0 {
                            Text("Resend code in \(resendCooldown)s")
                                .font(FFTypography.bodyMedium())
                                .foregroundColor(FFColors.textSecondary)
                        } else {
                            Button("Resend Code via SMS") {
                                startResendCooldown()
                            }
                            .font(FFTypography.bodyMedium())
                            .foregroundColor(FFColors.accentCyan)
                            .frame(minHeight: FFLayout.minTapTarget)
                        }
                    }

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundColor(FFColors.accentCyan)
                }
            }
        }
        .onAppear {
            focusedIndex = 0
        }
    }

    private func handleDigitChange(index: Int, value: String) {
        // Only allow single digit
        if value.count > 1 {
            digits[index] = String(value.last!)
        }

        // Auto-advance
        if !value.isEmpty && index < 5 {
            focusedIndex = index + 1
        }

        // Auto-submit when all 6 digits entered
        let code = digits.joined()
        if code.count == 6 {
            verifyCode(code)
        }
    }

    private func verifyCode(_ code: String) {
        // Simulate MFA verification
        errorMessage = nil
        appState.isAuthenticated = true
    }

    private func startResendCooldown() {
        resendCooldown = 60
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
}

struct OTPDigitField: View {
    @Binding var text: String
    var isFocused: Bool

    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .foregroundColor(FFColors.textPrimary)
            .frame(width: 48, height: 56)
            .background(FFColors.surface)
            .cornerRadius(FFLayout.cornerRadiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                    .stroke(isFocused ? FFColors.accentCyan : FFColors.border, lineWidth: isFocused ? 2 : 1)
            )
    }
}

#Preview {
    MFAScreen()
        .environmentObject(AppState())
}
