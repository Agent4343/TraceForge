import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var syncService = SyncService.shared

    @State private var showAdminPanel = false
    @State private var assignmentNotifications = true
    @State private var dueDateReminders = true
    @State private var completionNotifications = true
    @State private var handoverNotifications = true
    @State private var requireBiometrics = false
    @State private var autoLockMinutes = 5
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Profile card
                        profileCard

                        // Admin panel access
                        if let user = appState.currentUser, user.role.canManageUsers {
                            NavigationLink(destination: AdminPanelScreen()) {
                                HStack {
                                    Image(systemName: "gearshape.2")
                                        .foregroundColor(FFColors.accentCyan)
                                    Text("Admin Panel")
                                        .font(FFTypography.bodyMediumBold())
                                        .foregroundColor(FFColors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(FFColors.textSecondary)
                                        .font(.system(size: 12))
                                }
                                .ffCard()
                            }
                        }

                        // Notifications section
                        notificationsSection

                        // Offline & Sync section
                        syncSection

                        // Security section
                        securitySection

                        // About section
                        aboutSection

                        // Sign out
                        Button {
                            showLogoutConfirm = true
                        } label: {
                            Text("Sign Out")
                                .ffDestructiveButton()
                        }
                        .padding(.top, 8)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Sign Out", isPresented: $showLogoutConfirm) {
                Button("Sign Out", role: .destructive) {
                    appState.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out? Any unsynced data will be preserved on this device.")
            }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 16) {
            if let user = appState.currentUser {
                // Avatar
                AvatarView(initials: user.avatarInitials, role: user.role, size: 64)

                VStack(spacing: 4) {
                    Text(user.displayName)
                        .font(FFTypography.displaySmall())
                        .foregroundColor(FFColors.textPrimary)

                    Text(user.email)
                        .font(FFTypography.bodyMedium())
                        .foregroundColor(FFColors.textSecondary)

                    StatusBadge.forRole(user.role)
                        .padding(.top, 4)
                }

                if let org = appState.organization {
                    Text(org.name)
                        .font(FFTypography.bodySmall())
                        .foregroundColor(FFColors.textSecondary)
                }

                // Device ID
                HStack(spacing: 4) {
                    Text("Device:")
                        .font(FFTypography.bodySmall())
                        .foregroundColor(FFColors.textSecondary)
                    Text(String(user.deviceId.suffix(8)))
                        .font(FFTypography.mono())
                        .foregroundColor(FFColors.textSecondary)

                    Button {
                        UIPasteboard.general.string = user.deviceId
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(FFColors.accentCyan)
                    }
                }

                // MFA status
                HStack(spacing: 6) {
                    Image(systemName: user.mfaEnabled ? "checkmark.shield.fill" : "shield.slash")
                        .foregroundColor(user.mfaEnabled ? FFColors.success : FFColors.warning)
                    Text(user.mfaEnabled ? "MFA Enabled" : "MFA Disabled")
                        .font(FFTypography.bodySmall())
                        .foregroundColor(user.mfaEnabled ? FFColors.success : FFColors.warning)
                }
            }
        }
        .ffCard()
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(FFTypography.labelLarge())
                .foregroundColor(FFColors.textSecondary)

            VStack(spacing: 0) {
                settingsToggle("Assignment Notifications", isOn: $assignmentNotifications)
                Divider().background(FFColors.border)
                settingsToggle("Due Date Reminders", isOn: $dueDateReminders)
                Divider().background(FFColors.border)
                settingsToggle("Completion Notifications", isOn: $completionNotifications)
                Divider().background(FFColors.border)
                settingsToggle("Handover Notifications", isOn: $handoverNotifications)
            }
            .background(FFColors.surfaceElevated)
            .cornerRadius(FFLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: FFLayout.cornerRadius)
                    .stroke(FFColors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Sync Section

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Offline & Sync")
                .font(FFTypography.labelLarge())
                .foregroundColor(FFColors.textSecondary)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sync Status")
                            .font(FFTypography.bodyMediumBold())
                            .foregroundColor(FFColors.textPrimary)

                        if let lastSync = syncService.lastSyncDate {
                            let formatter = RelativeDateTimeFormatter()
                            Text("Last synced: \(formatter.localizedString(for: lastSync, relativeTo: Date()))")
                                .font(FFTypography.bodySmall())
                                .foregroundColor(FFColors.textSecondary)
                        } else {
                            Text("Never synced")
                                .font(FFTypography.bodySmall())
                                .foregroundColor(FFColors.warning)
                        }
                    }

                    Spacer()

                    Button("Sync Now") {
                        Task { await syncService.syncNow() }
                    }
                    .font(FFTypography.bodySmall())
                    .foregroundColor(FFColors.accentCyan)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(FFColors.accentCyan, lineWidth: 1)
                    )
                    .disabled(syncService.isSyncing)
                }

                if syncService.pendingOperations > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(FFColors.warning)
                        Text("\(syncService.pendingOperations) operations waiting to sync")
                            .font(FFTypography.bodySmall())
                            .foregroundColor(FFColors.warning)
                    }
                }

                HStack {
                    Text("Storage: ~142 MB")
                        .font(FFTypography.bodySmall())
                        .foregroundColor(FFColors.textSecondary)
                    Spacer()
                    Button("Clear Cache") {}
                        .font(FFTypography.bodySmall())
                        .foregroundColor(FFColors.danger)
                }
            }
            .ffCard()
        }
    }

    // MARK: - Security Section

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security")
                .font(FFTypography.labelLarge())
                .foregroundColor(FFColors.textSecondary)

            VStack(spacing: 0) {
                settingsToggle("Require Face ID / Touch ID", isOn: $requireBiometrics)
                Divider().background(FFColors.border)

                HStack {
                    Text("Auto-lock after")
                        .font(FFTypography.bodyMedium())
                        .foregroundColor(FFColors.textPrimary)
                    Spacer()
                    Picker("", selection: $autoLockMinutes) {
                        Text("2 min").tag(2)
                        Text("5 min").tag(5)
                        Text("15 min").tag(15)
                        Text("Never").tag(0)
                    }
                    .pickerStyle(.menu)
                    .tint(FFColors.accentCyan)
                }
                .padding(16)
            }
            .background(FFColors.surfaceElevated)
            .cornerRadius(FFLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: FFLayout.cornerRadius)
                    .stroke(FFColors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(FFTypography.labelLarge())
                .foregroundColor(FFColors.textSecondary)

            VStack(spacing: 0) {
                settingsRow("App Version") {
                    Text("1.0.0 (1)")
                        .font(FFTypography.mono())
                        .foregroundColor(FFColors.textSecondary)
                }
                Divider().background(FFColors.border)
                settingsRow("Terms of Service") {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(FFColors.textSecondary)
                        .font(.system(size: 12))
                }
                Divider().background(FFColors.border)
                settingsRow("Privacy Policy") {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(FFColors.textSecondary)
                        .font(.system(size: 12))
                }
                Divider().background(FFColors.border)
                settingsRow("Send Feedback") {
                    Image(systemName: "envelope")
                        .foregroundColor(FFColors.textSecondary)
                        .font(.system(size: 12))
                }
            }
            .background(FFColors.surfaceElevated)
            .cornerRadius(FFLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: FFLayout.cornerRadius)
                    .stroke(FFColors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers

    private func settingsToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(FFTypography.bodyMedium())
                .foregroundColor(FFColors.textPrimary)
        }
        .toggleStyle(SwitchToggleStyle(tint: FFColors.accentCyan))
        .padding(16)
    }

    private func settingsRow(_ title: String, @ViewBuilder trailing: () -> some View) -> some View {
        HStack {
            Text(title)
                .font(FFTypography.bodyMedium())
                .foregroundColor(FFColors.textPrimary)
            Spacer()
            trailing()
        }
        .padding(16)
    }
}

#Preview {
    ProfileScreen()
        .environmentObject(AppState())
}
