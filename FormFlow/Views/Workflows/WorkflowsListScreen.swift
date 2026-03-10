import SwiftUI

struct WorkflowsListScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var showCreateWorkflow = false
    @State private var statusFilter: WorkflowStatus?

    private var filteredWorkflows: [WorkflowInstance] {
        var workflows = appState.workflows
        if !searchText.isEmpty {
            workflows = workflows.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let filter = statusFilter {
            workflows = workflows.filter { $0.status == filter }
        }
        return workflows.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                FFColors.primaryNavy.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Status filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterChip(title: "All", isSelected: statusFilter == nil) {
                                statusFilter = nil
                            }
                            ForEach(WorkflowStatus.allCases, id: \.self) { status in
                                FilterChip(title: status.displayName, isSelected: statusFilter == status) {
                                    statusFilter = status
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    if filteredWorkflows.isEmpty {
                        EmptyStateView(
                            icon: "arrow.triangle.branch",
                            title: "No Workflows",
                            subtitle: "Create a new workflow to get started."
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredWorkflows) { workflow in
                                    NavigationLink(destination: WorkflowDetailScreen(workflow: workflow)) {
                                        WorkflowCard(workflow: workflow)
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                }

                // FAB for Managers+
                if let user = appState.currentUser, user.role.canCreateWorkflows {
                    Button {
                        showCreateWorkflow = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(FFColors.primaryNavy)
                            .frame(width: 56, height: 56)
                            .background(FFColors.accentCyan)
                            .clipShape(Circle())
                            .shadow(color: FFColors.accentCyan.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Workflows")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search workflows")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(FFColors.textSecondary)
                    }
                }
            }
            .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showCreateWorkflow) {
                CreateWorkflowScreen()
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - Workflow Card

struct WorkflowCard: View {
    @EnvironmentObject var appState: AppState
    let workflow: WorkflowInstance

    private var template: Template? {
        appState.templates.first { $0.id == workflow.templateId }
    }

    private var steps: [StepAssignment] {
        appState.stepsForWorkflow(workflow.id)
    }

    private var completedSteps: Int {
        steps.filter { $0.status == .complete || $0.status == .signed }.count
    }

    private var currentStep: Int {
        steps.first(where: { $0.status == .inProgress || $0.status == .todo })?.stepNumber ?? steps.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workflow.name)
                        .font(FFTypography.bodyMediumBold())
                        .foregroundColor(FFColors.textPrimary)
                        .lineLimit(1)

                    if let template = template {
                        Text(template.name)
                            .font(FFTypography.bodySmall())
                            .foregroundColor(FFColors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(FFColors.surface)
                            .cornerRadius(4)
                    }
                }

                Spacer()

                StatusBadge.forWorkflowStatus(workflow.status)
            }

            // Step progress
            if !steps.isEmpty {
                StepProgressBar(
                    totalSteps: steps.count,
                    completedSteps: completedSteps,
                    currentStep: currentStep
                )
            }

            HStack {
                DueDateLabel(date: workflow.dueDate)

                Spacer()

                // Avatar stack
                HStack(spacing: -8) {
                    ForEach(Array(steps.prefix(3).enumerated()), id: \.element.id) { _, step in
                        if let user = appState.users.first(where: { $0.id == step.assignedTo }) {
                            AvatarView(initials: user.avatarInitials, role: user.role, size: 24)
                                .overlay(Circle().stroke(FFColors.surfaceElevated, lineWidth: 2))
                        }
                    }
                    if steps.count > 3 {
                        Text("+\(steps.count - 3)")
                            .font(FFTypography.monoSmall())
                            .foregroundColor(FFColors.textSecondary)
                            .padding(.leading, 8)
                    }
                }
            }
        }
        .ffCard()
    }
}

#Preview {
    WorkflowsListScreen()
        .environmentObject(AppState())
}
