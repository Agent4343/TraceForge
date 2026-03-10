import SwiftUI

struct CreateWorkflowScreen: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var selectedTemplate: Template?
    @State private var workflowName = ""
    @State private var dueDate = Date().addingTimeInterval(86400)
    @State private var priority: WorkflowPriority = .standard
    @State private var stepAssignments: [Int: FFUser] = [:]
    @State private var stepDueDates: [Int: Date] = [:]
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Template picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Template")
                                .font(FFTypography.bodyMediumBold())
                                .foregroundColor(FFColors.textPrimary)

                            ForEach(appState.templates.filter { $0.status == .active }) { template in
                                Button {
                                    selectedTemplate = template
                                    if workflowName.isEmpty {
                                        workflowName = template.name
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(template.name)
                                                .font(FFTypography.bodyMedium())
                                                .foregroundColor(FFColors.textPrimary)
                                            Text("\(template.fields.count) fields · \(template.steps.count) steps")
                                                .font(FFTypography.bodySmall())
                                                .foregroundColor(FFColors.textSecondary)
                                        }
                                        Spacer()
                                        if selectedTemplate?.id == template.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(FFColors.accentCyan)
                                        }
                                    }
                                    .padding()
                                    .background(selectedTemplate?.id == template.id ? FFColors.accentCyan.opacity(0.1) : FFColors.surface)
                                    .cornerRadius(FFLayout.cornerRadiusSmall)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                                            .stroke(selectedTemplate?.id == template.id ? FFColors.accentCyan : FFColors.border, lineWidth: 1)
                                    )
                                }
                            }
                        }

                        // Workflow name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Workflow Name")
                                .font(FFTypography.bodyMediumBold())
                                .foregroundColor(FFColors.textPrimary)

                            TextField("", text: $workflowName, prompt: Text("Enter workflow name").foregroundColor(FFColors.textSecondary.opacity(0.4)))
                                .foregroundColor(FFColors.textPrimary)
                                .padding()
                                .frame(minHeight: FFLayout.minTapTarget)
                                .background(FFColors.surface)
                                .cornerRadius(FFLayout.cornerRadiusSmall)
                                .overlay(
                                    RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                                        .stroke(FFColors.border, lineWidth: 1)
                                )
                        }

                        // Due date
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Due Date")
                                .font(FFTypography.bodyMediumBold())
                                .foregroundColor(FFColors.textPrimary)

                            DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .tint(FFColors.accentCyan)
                                .labelsHidden()
                        }

                        // Priority
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Priority")
                                .font(FFTypography.bodyMediumBold())
                                .foregroundColor(FFColors.textPrimary)

                            HStack(spacing: 8) {
                                ForEach(WorkflowPriority.allCases, id: \.self) { p in
                                    Button {
                                        priority = p
                                    } label: {
                                        Text(p.displayName)
                                            .font(FFTypography.bodySmall())
                                            .fontWeight(priority == p ? .semibold : .regular)
                                            .foregroundColor(priority == p ? FFColors.primaryNavy : FFColors.textSecondary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(priority == p ? priorityColor(p) : FFColors.surface)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(priority == p ? Color.clear : FFColors.border, lineWidth: 1)
                                            )
                                    }
                                    .frame(minHeight: FFLayout.minTapTarget)
                                }
                            }
                        }

                        // Step assignments
                        if let template = selectedTemplate {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Step Assignments")
                                    .font(FFTypography.bodyMediumBold())
                                    .foregroundColor(FFColors.textPrimary)

                                ForEach(template.steps.sorted(by: { $0.stepNumber < $1.stepNumber })) { step in
                                    StepAssignmentRow(
                                        step: step,
                                        assignedUser: stepAssignments[step.stepNumber],
                                        users: appState.users.filter { $0.isActive && $0.role != .viewer },
                                        onAssign: { user in
                                            stepAssignments[step.stepNumber] = user
                                        }
                                    )
                                }
                            }
                        }

                        // Create button
                        Button {
                            createWorkflow()
                        } label: {
                            Group {
                                if isCreating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: FFColors.primaryNavy))
                                } else {
                                    Text("Create & Notify Assignees")
                                }
                            }
                            .ffPrimaryButton(isEnabled: isValid)
                        }
                        .disabled(!isValid || isCreating)
                        .padding(.top, 8)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Workflow")
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

    private var isValid: Bool {
        selectedTemplate != nil && !workflowName.isEmpty
    }

    private func priorityColor(_ p: WorkflowPriority) -> Color {
        switch p {
        case .standard: return FFColors.textSecondary
        case .high: return FFColors.warning
        case .critical: return FFColors.danger
        }
    }

    private func createWorkflow() {
        guard let template = selectedTemplate, let user = appState.currentUser else { return }
        isCreating = true

        let newWorkflow = WorkflowInstance(
            id: UUID(),
            organizationId: user.organizationId,
            templateId: template.id,
            templateVersion: template.version,
            name: workflowName,
            siteId: nil,
            status: .inProgress,
            priority: priority,
            createdBy: user.id,
            dueDate: dueDate,
            createdAt: Date(),
            completedAt: nil,
            pdfUrl: nil,
            pdfHash: nil
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            appState.workflows.insert(newWorkflow, at: 0)
            isCreating = false
            dismiss()
        }
    }
}

struct StepAssignmentRow: View {
    let step: TemplateStep
    let assignedUser: FFUser?
    let users: [FFUser]
    let onAssign: (FFUser) -> Void
    @State private var showPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Step \(step.stepNumber): \(step.name)")
                .font(FFTypography.bodySmall())
                .foregroundColor(FFColors.textSecondary)

            Button {
                showPicker = true
            } label: {
                HStack {
                    if let user = assignedUser {
                        AvatarView(initials: user.avatarInitials, role: user.role, size: 24)
                        Text(user.displayName)
                            .font(FFTypography.bodyMedium())
                            .foregroundColor(FFColors.textPrimary)
                    } else {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(FFColors.textSecondary)
                        Text("Assign user")
                            .foregroundColor(FFColors.textSecondary.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(FFColors.textSecondary)
                        .font(.system(size: 12))
                }
                .padding(12)
                .background(FFColors.surface)
                .cornerRadius(FFLayout.cornerRadiusSmall)
                .overlay(
                    RoundedRectangle(cornerRadius: FFLayout.cornerRadiusSmall)
                        .stroke(FFColors.border, lineWidth: 1)
                )
            }
        }
        .sheet(isPresented: $showPicker) {
            UserPickerScreen(
                selectedUser: Binding(
                    get: { assignedUser },
                    set: { if let u = $0 { onAssign(u) } }
                ),
                users: users
            )
        }
    }
}

#Preview {
    CreateWorkflowScreen()
        .environmentObject(AppState())
}
