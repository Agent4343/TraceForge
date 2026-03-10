import SwiftUI

struct ForgotPasswordScreen: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var isSubmitted = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                VStack(spacing: 24) {
                    if isSubmitted {
                        // Success state
                        VStack(spacing: 16) {
                            Spacer()

                            Image(systemName: "envelope.badge.shield.half.filled")
                                .font(.system(size: 56, weight: .thin))
                                .foregroundColor(FFColors.success)

                            Text("Reset Link Sent")
                                .font(FFTypography.displaySmall())
                                .foregroundColor(FFColors.textPrimary)

                            Text("We've sent a password reset link to")
                                .font(FFTypography.bodyMedium())
                                .foregroundColor(FFColors.textSecondary)

                            Text(email)
                                .font(FFTypography.bodyMediumBold())
                                .foregroundColor(FFColors.accentCyan)

                            Text("Check your inbox and follow the instructions to reset your password.")
                                .font(FFTypography.bodyMedium())
                                .foregroundColor(FFColors.textSecondary)
                                .multilineTextAlignment(.center)

                            Spacer()

                            Button("Done") {
                                dismiss()
                            }
                            .ffPrimaryButton()
                        }
                        .padding(24)
                    } else {
                        // Form state
                        VStack(spacing: 24) {
                            Spacer()

                            Image(systemName: "key.horizontal")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(FFColors.accentCyan)

                            Text("Forgot Password?")
                                .font(FFTypography.displaySmall())
                                .foregroundColor(FFColors.textPrimary)

                            Text("Enter your email address and we'll send you a link to reset your password.")
                                .font(FFTypography.bodyMedium())
                                .foregroundColor(FFColors.textSecondary)
                                .multilineTextAlignment(.center)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(FFTypography.label())
                                    .foregroundColor(FFColors.textSecondary)

                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(FFColors.textSecondary)
                                    TextField("", text: $email, prompt: Text("Enter your email").foregroundColor(FFColors.textSecondary.opacity(0.5)))
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .foregroundColor(FFColors.textPrimary)
                                }
                                .padding()
                                .frame(minHeight: FFLayout.minTapTarget)
                                .background(FFColors.surface)
                                .cornerRadius(FFLayout.cornerRadiusSmall)
                                .overlay(
                                    RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                                        .stroke(FFColors.border, lineWidth: 1)
                                )
                            }

                            Button(action: submitReset) {
                                Group {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: FFColors.primaryNavy))
                                    } else {
                                        Text("Send Reset Link")
                                    }
                                }
                                .ffPrimaryButton(isEnabled: !email.isEmpty)
                            }
                            .disabled(email.isEmpty || isLoading)

                            Spacer()
                        }
                        .padding(24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(FFColors.accentCyan)
                }
            }
        }
    }

    private func submitReset() {
        isLoading = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            isLoading = false
            isSubmitted = true
        }
    }
}

#Preview {
    ForgotPasswordScreen()
}
