import SwiftUI

struct MyTasksScreen: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var syncService = SyncService.shared
    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedTask: MockData.TaskItem?

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private var filteredTasks: [MockData.TaskItem] {
        let tasks = appState.tasksForCurrentUser()
        switch selectedFilter {
        case .all:
            return tasks
        case .dueToday:
            return tasks.filter { task in
                guard let due = task.dueDate else { return false }
                return Calendar.current.isDateInToday(due)
            }
        case .overdue:
            return tasks.filter { task in
                guard let due = task.dueDate else { return false }
                return due < Date()
            }
        case .pendingHandover:
            return [] // Would filter based on handover status
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FFColors.primaryNavy.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Offline banner
                    if !syncService.isOnline {
                        OfflineBanner()
                    }

                    // Filter bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(TaskFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    title: filter.rawValue,
                                    isSelected: selectedFilter == filter
                                ) {
                                    withAnimation { selectedFilter = filter }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    // Task list
                    if filteredTasks.isEmpty {
                        EmptyStateView(
                            icon: "checkmark.seal",
                            title: "You're all caught up.",
                            subtitle: "No tasks match the current filter. When you're assigned a workflow step, it will appear here."
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTasks) { task in
                                    NavigationLink(destination: FormFillScreen(task: task)) {
                                        TaskCard(task: task)
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle("My Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if syncService.pendingOperations > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(FFColors.warning)
                                .frame(width: 8, height: 8)
                            Text("\(syncService.pendingOperations)")
                                .font(FFTypography.monoSmall())
                                .foregroundColor(FFColors.warning)
                        }
                    }
                }
            }
            .toolbarBackground(FFColors.primaryNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FFTypography.bodySmall())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? FFColors.primaryNavy : FFColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? FFColors.accentCyan : FFColors.surfaceElevated)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : FFColors.border, lineWidth: 1)
                )
        }
        .frame(minHeight: FFLayout.minTapTarget)
    }
}

// MARK: - Task Card

struct TaskCard: View {
    let task: MockData.TaskItem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                // Workflow name
                Text(task.workflowName)
                    .font(FFTypography.bodyMediumBold())
                    .foregroundColor(FFColors.textPrimary)
                    .lineLimit(1)

                // Step info
                Text("Step \(task.stepNumber) of \(task.totalSteps) — \(task.stepName)")
                    .font(FFTypography.bodySmall())
                    .foregroundColor(FFColors.textSecondary)

                // Assigned by
                HStack(spacing: 4) {
                    Image(systemName: "person")
                        .font(.system(size: 10))
                    Text("Assigned by \(task.assignedBy)")
                        .font(FFTypography.bodySmall())
                }
                .foregroundColor(FFColors.textSecondary)

                HStack(spacing: 12) {
                    DueDateLabel(date: task.dueDate)
                    StatusBadge.forStepStatus(task.status)
                    if task.priority != .standard {
                        StatusBadge.forPriority(task.priority)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FFColors.textSecondary)
        }
        .ffCard()
    }
}

#Preview {
    MyTasksScreen()
        .environmentObject(AppState())
}
