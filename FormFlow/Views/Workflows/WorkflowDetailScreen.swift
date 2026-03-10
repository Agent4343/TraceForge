import SwiftUI

struct WorkflowDetailScreen: View {
    @EnvironmentObject var appState: AppState
    let workflow: WorkflowInstance
    @State private var selectedTab = 0
    @State private var showExportPDF = false
    @State private var isGeneratingPDF = false
    @State private var pdfData: Data?

    private var template: Template? {
        appState.templateForWorkflow(workflow)
    }

    private var steps: [StepAssignment] {
        appState.stepsForWorkflow(workflow.id).sorted { $0.stepNumber < $1.stepNumber }
    }

    private var auditEntries: [AuditLogEntry] {
        appState.auditEntriesForWorkflow(workflow.id)
    }

    var body: some View {
        ZStack {
            FFColors.primaryNavy.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let template = template {
                            Text(template.name)
                                .font(FFTypography.bodySmall())
                                .foregroundColor(FFColors.accentCyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(FFColors.accentCyan.opacity(0.15))
                                .cornerRadius(4)
                        }

                        Spacer()

                        StatusBadge.forWorkflowStatus(workflow.status)
                    }

                    if let creator = appState.users.first(where: { $0.id == workflow.createdBy }) {
                        Text("Created by \(creator.displayName)")
                            .font(FFTypography.bodySmall())
                            .foregroundColor(FFColors.textSecondary)
                    }

                    HStack {
                        Label(formattedDate(workflow.createdAt), systemImage: "calendar")
                            .font(FFTypography.bodySmall())
                            .foregroundColor(FFColors.textSecondary)

                        Spacer()

                        if workflow.priority != .standard {
                            StatusBadge.forPriority(workflow.priority)
                        }
                    }
                }
                .ffCard()
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Tab picker
                Picker("View", selection: $selectedTab) {
                    Text("Steps").tag(0)
                    Text("Audit Trail").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(16)

                // Content
                if selectedTab == 0 {
                    stepTimeline
                } else {
                    auditTrailList
                }

                // Action bar
                actionBar
            }
        }
        .navigationTitle(workflow.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showExportPDF) {
            PDFExportView(workflow: workflow, pdfData: pdfData)
                .environmentObject(appState)
        }
    }

    // MARK: - Step Timeline

    private var stepTimeline: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    StepTimelineRow(
                        step: step,
                        isFirst: index == 0,
                        isLast: index == steps.count - 1,
                        user: appState.users.first(where: { $0.id == step.assignedTo })
                    )
                }
            }
            .padding(16)
        }
    }

    // MARK: - Audit Trail List

    private var auditTrailList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(auditEntries) { entry in
                    AuditEntryRow(entry: entry)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        VStack(spacing: 0) {
            Divider().background(FFColors.border)

            HStack(spacing: 12) {
                if let user = appState.currentUser {
                    if let currentStep = steps.first(where: { $0.assignedTo == user.id && ($0.status == .todo || $0.status == .inProgress) }) {
                        NavigationLink(destination: FormFillScreen(task: taskForStep(currentStep))) {
                            Text("Open My Step")
                                .ffPrimaryButton()
                        }
                    }

                    if workflow.status == .complete && user.role.canExportPDF {
                        Button("Export PDF") {
                            generatePDF()
                        }
                        .ffSecondaryButton()
                    }
                }
            }
            .padding(16)
        }
        .background(FFColors.primaryNavy)
    }

    private func taskForStep(_ step: StepAssignment) -> MockData.TaskItem {
        MockData.TaskItem(
            id: step.id,
            workflowName: workflow.name,
            stepNumber: step.stepNumber,
            totalSteps: steps.count,
            stepName: step.stepName,
            assignedBy: appState.users.first(where: { $0.id == step.assignedBy })?.displayName ?? "Unknown",
            assignedAt: step.assignedAt,
            dueDate: step.dueDate,
            status: step.status,
            priority: workflow.priority,
            workflowId: workflow.id
        )
    }

    private func generatePDF() {
        isGeneratingPDF = true
        guard let template = template, let org = appState.organization else { return }

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            let data = PDFService.shared.generatePDF(
                workflow: workflow,
                template: template,
                steps: steps,
                responses: appState.formResponses[workflow.id] ?? [:],
                signatures: [],
                auditEntries: auditEntries,
                organization: org
            )
            pdfData = data
            isGeneratingPDF = false
            showExportPDF = true
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Step Timeline Row

struct StepTimelineRow: View {
    let step: StepAssignment
    let isFirst: Bool
    let isLast: Bool
    let user: FFUser?

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline column
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(step.status == .complete || step.status == .signed ? FFColors.accentCyan : FFColors.border)
                        .frame(width: 2, height: 16)
                }

                // Step circle
                ZStack {
                    Circle()
                        .fill(stepCircleColor)
                        .frame(width: 32, height: 32)

                    if step.status == .complete || step.status == .signed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else if step.status == .locked {
                        Image(systemName: "lock")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(FFColors.textSecondary)
                    } else {
                        Text("\(step.stepNumber)")
                            .font(FFTypography.bodySmall())
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }

                if !isLast {
                    Rectangle()
                        .fill(step.status == .complete || step.status == .signed ? FFColors.accentCyan : FFColors.border)
                        .frame(width: 2)
                        .frame(minHeight: 40)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(step.stepName)
                        .font(FFTypography.bodyMediumBold())
                        .foregroundColor(FFColors.textPrimary)

                    Spacer()

                    StatusBadge.forStepStatus(step.status)
                }

                if let user = user {
                    HStack(spacing: 6) {
                        AvatarView(initials: user.avatarInitials, role: user.role, size: 20)
                        Text(user.displayName)
                            .font(FFTypography.bodySmall())
                            .foregroundColor(FFColors.textSecondary)
                        StatusBadge.forRole(user.role)
                    }
                }

                DueDateLabel(date: step.dueDate)
            }
            .padding(.bottom, isLast ? 0 : 12)
        }
    }

    private var stepCircleColor: Color {
        switch step.status {
        case .complete, .signed: return FFColors.success
        case .inProgress: return FFColors.accentCyan
        case .todo: return FFColors.surfaceElevated
        case .locked: return FFColors.surface
        }
    }
}

// MARK: - Audit Entry Row

struct AuditEntryRow: View {
    let entry: AuditLogEntry

    private var borderColor: Color {
        switch entry.action.category {
        case .signature: return FFColors.accentCyan
        case .fieldChange: return FFColors.auditFieldChange
        case .handover: return FFColors.warning
        case .system: return FFColors.textSecondary
        case .all: return FFColors.textSecondary
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Color border
            RoundedRectangle(cornerRadius: 2)
                .fill(borderColor)
                .frame(width: 4)

            // Avatar
            AvatarView(
                initials: String(entry.actorName.prefix(2)).uppercased(),
                role: UserRole(rawValue: entry.actorRole) ?? .worker,
                size: 28
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(entry.actorName) \(entry.action.displayText)")
                        .font(FFTypography.bodyMedium())
                        .foregroundColor(FFColors.textPrimary)
                    Spacer()
                }

                if let stepNum = entry.stepNumber {
                    Text("Step \(stepNum)")
                        .font(FFTypography.bodySmall())
                        .foregroundColor(FFColors.textSecondary)
                }

                Text(relativeTime(entry.timestamp))
                    .font(FFTypography.mono())
                    .foregroundColor(FFColors.textSecondary)
            }
        }
        .padding(12)
        .background(FFColors.surfaceElevated)
        .cornerRadius(FFLayout.cornerRadiusSmall)
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - PDF Export View

struct PDFExportView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let workflow: WorkflowInstance
    let pdfData: Data?

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "doc.richtext")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundColor(FFColors.accentCyan)

                    Text("PDF Generated")
                        .font(FFTypography.displaySmall())
                        .foregroundColor(FFColors.textPrimary)

                    Text(workflow.name)
                        .font(FFTypography.bodyMedium())
                        .foregroundColor(FFColors.textSecondary)

                    if let data = pdfData {
                        Text("\(data.count / 1024) KB")
                            .font(FFTypography.mono())
                            .foregroundColor(FFColors.textSecondary)
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        if let data = pdfData {
                            ShareLink(
                                item: data,
                                preview: SharePreview(workflow.name, icon: "doc.richtext")
                            ) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .ffPrimaryButton()
                            }
                        }

                        Button("Done") {
                            dismiss()
                        }
                        .ffSecondaryButton()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(FFColors.accentCyan)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkflowDetailScreen(workflow: MockData.activeWorkflow)
            .environmentObject(AppState())
    }
}
