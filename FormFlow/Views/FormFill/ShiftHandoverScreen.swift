import SwiftUI

struct ShiftHandoverScreen: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    let stepName: String
    let workflowName: String
    let workflowId: UUID
    let stepNumber: Int

    @State private var selectedUser: FFUser?
    @State private var handoverNote = ""
    @State private var showUserPicker = false
    @State private var showConfirmation = false
    @State private var isTransferring = false

    private var isValid: Bool {
        selectedUser != nil && handoverNote.count >= 20
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Transfer Step")
                                .font(FFTypography.displaySmall())
                                .foregroundColor(FFColors.textPrimary)

                            Text("\(stepName) — \(workflowName)")
                                .font(FFTypography.bodyMedium())
                                .foregroundColor(FFColors.textSecondary)
                        }

                        // Warning banner
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(FFColors.warning)
                            Text("Warning: You will lose edit access to this step immediately upon transfer.")
                                .font(FFTypography.bodySmall())
                                .foregroundColor(FFColors.warning)
                        }
                        .padding()
                        .background(FFColors.warning.opacity(0.1))
                        .cornerRadius(FFLayout.cornerRadiusSmall)
                        .overlay(
                            RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                                .stroke(FFColors.warning.opacity(0.3), lineWidth: 1)
                        )

                        // Transfer to
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Transfer to")
                                    .font(FFTypography.bodyMediumBold())
                                    .foregroundColor(FFColors.textPrimary)
                                Text("*")
                                    .foregroundColor(FFColors.danger)
                            }

                            Button {
                                showUserPicker = true
                            } label: {
                                HStack {
                                    if let user = selectedUser {
                                        AvatarView(initials: user.avatarInitials, role: user.role, size: 28)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(user.displayName)
                                                .foregroundColor(FFColors.textPrimary)
                                                .font(FFTypography.bodyMedium())
                                            HStack(spacing: 6) {
                                                StatusBadge.forRole(user.role)
                                                Circle()
                                                    .fill(FFColors.success)
                                                    .frame(width: 6, height: 6)
                                                Text("Online")
                                                    .font(FFTypography.bodySmall())
                                                    .foregroundColor(FFColors.success)
                                            }
                                        }
                                    } else {
                                        Image(systemName: "person.badge.plus")
                                            .foregroundColor(FFColors.textSecondary)
                                        Text("Select a user")
                                            .foregroundColor(FFColors.textSecondary.opacity(0.5))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(FFColors.textSecondary)
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
                        }

                        // Handover note
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Handover Note")
                                    .font(FFTypography.bodyMediumBold())
                                    .foregroundColor(FFColors.textPrimary)
                                Text("*")
                                    .foregroundColor(FFColors.danger)
                            }

                            TextEditor(text: $handoverNote)
                                .foregroundColor(FFColors.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(FFColors.surface)
                                .cornerRadius(FFLayout.cornerRadiusSmall)
                                .overlay(
                                    RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                                        .stroke(FFColors.border, lineWidth: 1)
                                )
                                .overlay(alignment: .topLeading) {
                                    if handoverNote.isEmpty {
                                        Text("Describe current status, what has been completed, and what remains. Include any safety-critical information.")
                                            .font(FFTypography.bodyMedium())
                                            .foregroundColor(FFColors.textSecondary.opacity(0.4))
                                            .padding(12)
                                            .allowsHitTesting(false)
                                    }
                                }

                            HStack {
                                Spacer()
                                Text("\(handoverNote.count) characters")
                                    .font(FFTypography.monoSmall())
                                    .foregroundColor(handoverNote.count < 20 ? FFColors.danger : FFColors.textSecondary)
                                if handoverNote.count < 20 {
                                    Text("(min 20)")
                                        .font(FFTypography.monoSmall())
                                        .foregroundColor(FFColors.danger)
                                }
                            }
                        }

                        Spacer(minLength: 40)

                        // Confirm transfer
                        Button {
                            showConfirmation = true
                        } label: {
                            Group {
                                if isTransferring {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Confirm Transfer")
                                }
                            }
                            .ffDestructiveButton()
                        }
                        .disabled(!isValid || isTransferring)
                        .opacity(isValid ? 1 : 0.5)
                    }
                    .padding(16)
                }
            }
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
            .sheet(isPresented: $showUserPicker) {
                UserPickerScreen(
                    selectedUser: $selectedUser,
                    users: appState.users.filter { $0.id != appState.currentUser?.id && $0.isActive }
                )
            }
            .alert("Confirm Transfer", isPresented: $showConfirmation) {
                Button("Transfer", role: .destructive) {
                    executeTransfer()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let from = appState.currentUser?.displayName, let to = selectedUser?.displayName {
                    Text("Are you sure? \(from) → \(to). This cannot be undone.")
                }
            }
        }
    }

    private func executeTransfer() {
        isTransferring = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isTransferring = false
            dismiss()
        }
    }
}

// MARK: - User Picker

struct UserPickerScreen: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedUser: FFUser?
    let users: [FFUser]
    @State private var searchText = ""

    private var filteredUsers: [FFUser] {
        if searchText.isEmpty { return users }
        return users.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText) ||
            $0.role.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                List {
                    ForEach(filteredUsers) { user in
                        Button {
                            selectedUser = user
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(initials: user.avatarInitials, role: user.role, size: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.displayName)
                                        .font(FFTypography.bodyMediumBold())
                                        .foregroundColor(FFColors.textPrimary)
                                    Text(user.email)
                                        .font(FFTypography.bodySmall())
                                        .foregroundColor(FFColors.textSecondary)
                                }

                                Spacer()

                                StatusBadge.forRole(user.role)

                                if selectedUser?.id == user.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(FFColors.accentCyan)
                                }
                            }
                        }
                        .listRowBackground(FFColors.surfaceElevated)
                    }
                }
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search by name, email, or role")
            }
            .navigationTitle("Select User")
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
}

#Preview {
    ShiftHandoverScreen(
        stepName: "HSE Pre-Job Review",
        workflowName: "Platform A — Hot Work Permit #2847",
        workflowId: MockData.activeWorkflow.id,
        stepNumber: 2
    )
    .environmentObject(AppState())
}
