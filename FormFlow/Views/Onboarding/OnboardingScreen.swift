import SwiftUI

// MARK: - Admin Onboarding

struct AdminOnboardingScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var orgName = ""
    @State private var siteName = ""
    @State private var inviteEmails: [String] = [""]
    @State private var inviteRoles: [UserRole] = [.worker]

    var body: some View {
        ZStack {
            FFColors.primaryNavy.ignoresSafeArea()

            VStack {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { step in
                        Circle()
                            .fill(step <= currentStep ? FFColors.accentCyan : FFColors.border)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 24)

                TabView(selection: $currentStep) {
                    // Step 0: Welcome
                    welcomeStep.tag(0)

                    // Step 1: Org name
                    orgNameStep.tag(1)

                    // Step 2: Site name
                    siteNameStep.tag(2)

                    // Step 3: Invite team
                    inviteTeamStep.tag(3)

                    // Step 4: Done
                    doneStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "building.2")
                .font(.system(size: 56, weight: .thin))
                .foregroundColor(FFColors.accentCyan)

            Text("Let's set up your organization")
                .font(FFTypography.displayMedium())
                .foregroundColor(FFColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("We'll get you up and running in a few quick steps.")
                .font(FFTypography.bodyMedium())
                .foregroundColor(FFColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Get Started") {
                withAnimation { currentStep = 1 }
            }
            .ffPrimaryButton()
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding(24)
    }

    private var orgNameStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            Text("Organization Name")
                .font(FFTypography.displaySmall())
                .foregroundColor(FFColors.textPrimary)

            TextField("", text: $orgName, prompt: Text("e.g., Acme Oil & Gas").foregroundColor(FFColors.textSecondary.opacity(0.4)))
                .font(FFTypography.bodyLarge())
                .foregroundColor(FFColors.textPrimary)
                .padding()
                .background(FFColors.surface)
                .cornerRadius(FFLayout.cornerRadiusSmall)
                .overlay(RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall).stroke(FFColors.border, lineWidth: 1))

            Spacer()

            Button("Continue") {
                withAnimation { currentStep = 2 }
            }
            .ffPrimaryButton(isEnabled: !orgName.isEmpty)
            .disabled(orgName.isEmpty)
            .padding(.bottom, 32)
        }
        .padding(24)
    }

    private var siteNameStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()

            Text("First Site")
                .font(FFTypography.displaySmall())
                .foregroundColor(FFColors.textPrimary)

            Text("Add your first operational site or location.")
                .font(FFTypography.bodyMedium())
                .foregroundColor(FFColors.textSecondary)

            TextField("", text: $siteName, prompt: Text("e.g., Platform Alpha").foregroundColor(FFColors.textSecondary.opacity(0.4)))
                .font(FFTypography.bodyLarge())
                .foregroundColor(FFColors.textPrimary)
                .padding()
                .background(FFColors.surface)
                .cornerRadius(FFLayout.cornerRadiusSmall)
                .overlay(RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall).stroke(FFColors.border, lineWidth: 1))

            Spacer()

            Button("Continue") {
                withAnimation { currentStep = 3 }
            }
            .ffPrimaryButton(isEnabled: !siteName.isEmpty)
            .disabled(siteName.isEmpty)
            .padding(.bottom, 32)
        }
        .padding(24)
    }

    private var inviteTeamStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Invite Your Team")
                .font(FFTypography.displaySmall())
                .foregroundColor(FFColors.textPrimary)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(inviteEmails.enumerated()), id: \.offset) { index, _ in
                        HStack {
                            TextField("", text: $inviteEmails[index], prompt: Text("email@company.com").foregroundColor(FFColors.textSecondary.opacity(0.4)))
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .foregroundColor(FFColors.textPrimary)
                                .padding()
                                .background(FFColors.surface)
                                .cornerRadius(FFLayout.cornerRadiusSmall)
                                .overlay(RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall).stroke(FFColors.border, lineWidth: 1))
                        }
                    }

                    Button {
                        inviteEmails.append("")
                        inviteRoles.append(.worker)
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add another")
                        }
                        .foregroundColor(FFColors.accentCyan)
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Skip") {
                    withAnimation { currentStep = 4 }
                }
                .ffSecondaryButton()

                Button("Send Invites") {
                    withAnimation { currentStep = 4 }
                }
                .ffPrimaryButton()
            }
            .padding(.bottom, 32)
        }
        .padding(24)
    }

    private var doneStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(FFColors.success)

            Text("You're All Set!")
                .font(FFTypography.displayMedium())
                .foregroundColor(FFColors.textPrimary)

            Text("\(orgName) is ready to go. Create your first workflow template to get started.")
                .font(FFTypography.bodyMedium())
                .foregroundColor(FFColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Create Your First Workflow") {
                appState.showOnboarding = false
            }
            .ffPrimaryButton()
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding(24)
    }
}

// MARK: - Worker Onboarding

struct WorkerOnboardingScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0

    var body: some View {
        ZStack {
            FFColors.primaryNavy.ignoresSafeArea()

            VStack {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { step in
                        Circle()
                            .fill(step <= currentStep ? FFColors.accentCyan : FFColors.border)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 24)

                TabView(selection: $currentStep) {
                    // Welcome
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: "hand.wave")
                            .font(.system(size: 56, weight: .thin))
                            .foregroundColor(FFColors.accentCyan)

                        Text("Welcome to FormFlow")
                            .font(FFTypography.displayMedium())
                            .foregroundColor(FFColors.textPrimary)

                        if let org = appState.organization {
                            Text("You've been invited to join \(org.name)")
                                .font(FFTypography.bodyMedium())
                                .foregroundColor(FFColors.textSecondary)
                        }
                        Spacer()

                        Button("Continue") { withAnimation { currentStep = 1 } }
                            .ffPrimaryButton()
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                    }.tag(0)

                    // Enable notifications
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: "bell.badge")
                            .font(.system(size: 56, weight: .thin))
                            .foregroundColor(FFColors.accentCyan)

                        Text("Stay Notified")
                            .font(FFTypography.displaySmall())
                            .foregroundColor(FFColors.textPrimary)

                        Text("Get notified when you're assigned tasks, when steps are due, and when handovers happen.")
                            .font(FFTypography.bodyMedium())
                            .foregroundColor(FFColors.textSecondary)
                            .multilineTextAlignment(.center)

                        Spacer()

                        VStack(spacing: 8) {
                            Button("Enable Notifications") { withAnimation { currentStep = 2 } }
                                .ffPrimaryButton()
                            Button("Skip") { withAnimation { currentStep = 2 } }
                                .foregroundColor(FFColors.textSecondary)
                                .frame(minHeight: FFLayout.minTapTarget)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }.tag(1)

                    // Enable biometrics
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: "faceid")
                            .font(.system(size: 56, weight: .thin))
                            .foregroundColor(FFColors.accentCyan)

                        Text("Secure Access")
                            .font(FFTypography.displaySmall())
                            .foregroundColor(FFColors.textPrimary)

                        Text("Use Face ID or Touch ID for quick, secure access to FormFlow.")
                            .font(FFTypography.bodyMedium())
                            .foregroundColor(FFColors.textSecondary)
                            .multilineTextAlignment(.center)

                        Spacer()

                        VStack(spacing: 8) {
                            Button("Enable Face ID") { withAnimation { currentStep = 3 } }
                                .ffPrimaryButton()
                            Button("Skip") { withAnimation { currentStep = 3 } }
                                .foregroundColor(FFColors.textSecondary)
                                .frame(minHeight: FFLayout.minTapTarget)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }.tag(2)

                    // Done
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 64, weight: .thin))
                            .foregroundColor(FFColors.success)

                        Text("You're Ready!")
                            .font(FFTypography.displayMedium())
                            .foregroundColor(FFColors.textPrimary)

                        Text("When you're assigned a workflow step, it will appear in My Tasks.")
                            .font(FFTypography.bodyMedium())
                            .foregroundColor(FFColors.textSecondary)
                            .multilineTextAlignment(.center)

                        Spacer()

                        Button("Go to My Tasks") {
                            appState.showOnboarding = false
                        }
                        .ffPrimaryButton()
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }
}

#Preview {
    AdminOnboardingScreen()
        .environmentObject(AppState())
}
