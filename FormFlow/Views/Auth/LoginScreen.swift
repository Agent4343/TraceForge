import SwiftUI

struct LoginScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var showPassword = false
    @State private var showMFA = false
    @State private var showForgotPassword = false
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        ZStack {
            FFColors.primaryNavy.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Logo section
                    VStack(spacing: 8) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(FFColors.accentCyan)

                        Text("FormFlow")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(FFColors.textPrimary)

                        Text("Sign in to continue")
                            .font(FFTypography.bodyMedium())
                            .foregroundColor(FFColors.textSecondary)
                    }
                    .padding(.top, 80)
                    .padding(.bottom, 48)

                    // Form section
                    VStack(spacing: 20) {
                        // Offline indicator
                        if !appState.isOnline {
                            OfflineBanner()
                                .cornerRadius(FFLayout.cornerRadiusSmall)
                        }

                        // Email field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(FFTypography.label())
                                .foregroundColor(FFColors.textSecondary)

                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(FFColors.textSecondary)
                                    .frame(width: 20)
                                TextField("", text: $email, prompt: Text("Enter your email").foregroundColor(FFColors.textSecondary.opacity(0.5)))
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .foregroundColor(FFColors.textPrimary)
                            }
                            .padding()
                            .frame(minHeight: FFLayout.minTapTarget)
                            .background(FFColors.surface)
                            .cornerRadius(FFLayout.cornerRadiusSmall)
                            .overlay(
                                RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                                    .stroke(emailError != nil ? FFColors.danger : FFColors.border, lineWidth: 1)
                            )

                            if let error = emailError {
                                Text(error)
                                    .font(FFTypography.bodySmall())
                                    .foregroundColor(FFColors.danger)
                            }
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(FFTypography.label())
                                .foregroundColor(FFColors.textSecondary)

                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(FFColors.textSecondary)
                                    .frame(width: 20)

                                Group {
                                    if showPassword {
                                        TextField("", text: $password, prompt: Text("Enter your password").foregroundColor(FFColors.textSecondary.opacity(0.5)))
                                    } else {
                                        SecureField("", text: $password, prompt: Text("Enter your password").foregroundColor(FFColors.textSecondary.opacity(0.5)))
                                    }
                                }
                                .textContentType(.password)
                                .foregroundColor(FFColors.textPrimary)

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(FFColors.textSecondary)
                                }
                                .frame(minWidth: FFLayout.minTapTarget, minHeight: FFLayout.minTapTarget)
                            }
                            .padding()
                            .frame(minHeight: FFLayout.minTapTarget)
                            .background(FFColors.surface)
                            .cornerRadius(FFLayout.cornerRadiusSmall)
                            .overlay(
                                RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                                    .stroke(passwordError != nil ? FFColors.danger : FFColors.border, lineWidth: 1)
                            )

                            if let error = passwordError {
                                Text(error)
                                    .font(FFTypography.bodySmall())
                                    .foregroundColor(FFColors.danger)
                            }
                        }

                        // Remember me
                        HStack {
                            Toggle(isOn: $rememberMe) {
                                Text("Remember me")
                                    .font(FFTypography.bodyMedium())
                                    .foregroundColor(FFColors.textSecondary)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: FFColors.accentCyan))
                        }

                        // Sign In button
                        Button(action: handleLogin) {
                            Group {
                                if appState.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: FFColors.primaryNavy))
                                } else {
                                    Text("Sign In")
                                }
                            }
                            .ffPrimaryButton(isEnabled: !email.isEmpty && !password.isEmpty)
                        }
                        .disabled(email.isEmpty || password.isEmpty || appState.isLoading)
                        .offset(x: shakeOffset)

                        // Forgot password
                        Button {
                            showForgotPassword = true
                        } label: {
                            Text("Forgot Password?")
                                .font(FFTypography.bodyMedium())
                                .foregroundColor(FFColors.accentCyan)
                        }
                        .frame(minHeight: FFLayout.minTapTarget)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .sheet(isPresented: $showMFA) {
            MFAScreen()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordScreen()
        }
    }

    private func handleLogin() {
        emailError = nil
        passwordError = nil

        guard !email.isEmpty else {
            emailError = "Email is required"
            shakeAnimation()
            return
        }

        guard email.contains("@") else {
            emailError = "Please enter a valid email"
            shakeAnimation()
            return
        }

        guard !password.isEmpty else {
            passwordError = "Password is required"
            shakeAnimation()
            return
        }

        appState.login(email: email, password: password)
    }

    private func shakeAnimation() {
        withAnimation(.default) {
            shakeOffset = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.default) {
                shakeOffset = -10
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.default) {
                shakeOffset = 0
            }
        }
    }
}

#Preview {
    LoginScreen()
        .environmentObject(AppState())
}
