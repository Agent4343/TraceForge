import SwiftUI

struct AdminPanelScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var roleFilter: UserRole?
    @State private var showInviteUsers = false

    private var filteredUsers: [FFUser] {
        var users = appState.users
        if !searchText.isEmpty {
            users = users.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let filter = roleFilter {
            users = users.filter { $0.role == filter }
        }
        return users.sorted { $0.displayName < $1.displayName }
    }

    var body: some View {
        ZStack {
            FFColors.primaryNavy.ignoresSafeArea()

            VStack(spacing: 0) {
                // Role filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterChip(title: "All", isSelected: roleFilter == nil) {
                            roleFilter = nil
                        }
                        ForEach(UserRole.allCases) { role in
                            FilterChip(title: role.displayName, isSelected: roleFilter == role) {
                                roleFilter = role
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                List {
                    ForEach(filteredUsers) { user in
                        UserManagementRow(user: user)
                            .listRowBackground(FFColors.surfaceElevated)
                            .listRowSeparatorTint(FFColors.border)
                    }
                }
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search by name or email")
            }
        }
        .navigationTitle("User Management")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showInviteUsers = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(FFColors.accentCyan)
                }
            }
        }
        .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showInviteUsers) {
            InviteUsersScreen()
                .environmentObject(appState)
        }
    }
}

// MARK: - User Management Row

struct UserManagementRow: View {
    let user: FFUser
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            HStack(spacing: 12) {
                AvatarView(initials: user.avatarInitials, role: user.role, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(FFTypography.bodyMediumBold())
                        .foregroundColor(FFColors.textPrimary)
                    Text(user.email)
                        .font(FFTypography.bodySmall())
                        .foregroundColor(FFColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge.forRole(user.role)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(user.isActive ? FFColors.success : FFColors.danger)
                            .frame(width: 6, height: 6)
                        Text(user.isActive ? "Active" : "Inactive")
                            .font(FFTypography.monoSmall())
                            .foregroundColor(user.isActive ? FFColors.success : FFColors.danger)
                    }
                }
            }
        }
        .sheet(isPresented: $showDetail) {
            UserDetailSheet(user: user)
        }
    }
}

// MARK: - User Detail Sheet

struct UserDetailSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let user: FFUser
    @State private var selectedRole: UserRole
    @State private var showDeactivateConfirm = false

    init(user: FFUser) {
        self.user = user
        _selectedRole = State(initialValue: user.role)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Profile
                        VStack(spacing: 12) {
                            AvatarView(initials: user.avatarInitials, role: user.role, size: 64)

                            Text(user.displayName)
                                .font(FFTypography.displaySmall())
                                .foregroundColor(FFColors.textPrimary)

                            Text(user.email)
                                .font(FFTypography.bodyMedium())
                                .foregroundColor(FFColors.textSecondary)
                        }

                        // Role picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Role")
                                .font(FFTypography.bodyMediumBold())
                                .foregroundColor(FFColors.textPrimary)

                            Picker("Role", selection: $selectedRole) {
                                ForEach(UserRole.allCases) { role in
                                    Text(role.displayName).tag(role)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .ffCard()

                        // Info
                        VStack(spacing: 0) {
                            infoRow("Device ID", value: String(user.deviceId.suffix(8)))
                            Divider().background(FFColors.border)
                            infoRow("MFA", value: user.mfaEnabled ? "Enabled" : "Disabled")
                            Divider().background(FFColors.border)
                            infoRow("Joined", value: formattedDate(user.createdAt))
                            Divider().background(FFColors.border)
                            infoRow("Last Active", value: user.lastActiveAt.map { formattedDate($0) } ?? "Never")
                        }
                        .background(FFColors.surfaceElevated)
                        .cornerRadius(FFLayout.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: FFLayout.cornerRadius)
                                .stroke(FFColors.border, lineWidth: 1)
                        )

                        // Actions
                        VStack(spacing: 8) {
                            Button("Reset MFA") {}
                                .ffSecondaryButton()

                            Button {
                                showDeactivateConfirm = true
                            } label: {
                                Text(user.isActive ? "Deactivate Account" : "Reactivate Account")
                                    .ffDestructiveButton()
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("User Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(FFColors.accentCyan)
                }
            }
            .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Confirm", isPresented: $showDeactivateConfirm) {
                Button(user.isActive ? "Deactivate" : "Reactivate", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(user.isActive ? "This user will no longer be able to sign in." : "This user will regain access.")
            }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(FFTypography.bodyMedium())
                .foregroundColor(FFColors.textSecondary)
            Spacer()
            Text(value)
                .font(FFTypography.mono())
                .foregroundColor(FFColors.textPrimary)
        }
        .padding(16)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Invite Users Screen

struct InviteUsersScreen: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var emails: [String] = [""]
    @State private var roles: [UserRole] = [.worker]
    @State private var customMessage = ""
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Invite team members to join your organization.")
                            .font(FFTypography.bodyMedium())
                            .foregroundColor(FFColors.textSecondary)

                        ForEach(Array(emails.enumerated()), id: \.offset) { index, _ in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    TextField("", text: $emails[index], prompt: Text("email@example.com").foregroundColor(FFColors.textSecondary.opacity(0.4)))
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .foregroundColor(FFColors.textPrimary)
                                        .padding()
                                        .background(FFColors.surface)
                                        .cornerRadius(FFLayout.cornerRadiusSmall)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                                                .stroke(FFColors.border, lineWidth: 1)
                                        )

                                    if emails.count > 1 {
                                        Button {
                                            emails.remove(at: index)
                                            roles.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(FFColors.danger)
                                        }
                                        .frame(minWidth: FFLayout.minTapTarget, minHeight: FFLayout.minTapTarget)
                                    }
                                }

                                if index < roles.count {
                                    Picker("Role", selection: $roles[index]) {
                                        Text("Worker").tag(UserRole.worker)
                                        Text("Manager").tag(UserRole.manager)
                                        Text("Viewer").tag(UserRole.viewer)
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                        }

                        Button {
                            emails.append("")
                            roles.append(.worker)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add another email")
                            }
                            .font(FFTypography.bodyMedium())
                            .foregroundColor(FFColors.accentCyan)
                        }
                        .frame(minHeight: FFLayout.minTapTarget)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Custom Message (optional)")
                                .font(FFTypography.bodyMediumBold())
                                .foregroundColor(FFColors.textPrimary)

                            TextEditor(text: $customMessage)
                                .foregroundColor(FFColors.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(FFColors.surface)
                                .cornerRadius(FFLayout.cornerRadiusSmall)
                                .overlay(
                                    RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                                        .stroke(FFColors.border, lineWidth: 1)
                                )
                        }

                        Button {
                            sendInvites()
                        } label: {
                            Group {
                                if isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: FFColors.primaryNavy))
                                } else {
                                    Text("Send Invites")
                                }
                            }
                            .ffPrimaryButton(isEnabled: emails.contains { !$0.isEmpty })
                        }
                        .disabled(emails.allSatisfy { $0.isEmpty })
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Invite Users")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(FFColors.accentCyan)
                }
            }
            .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func sendInvites() {
        isSending = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            isSending = false
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        AdminPanelScreen()
            .environmentObject(AppState())
    }
}
