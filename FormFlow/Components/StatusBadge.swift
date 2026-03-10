import SwiftUI

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(FFTypography.label())
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }

    // Convenience initializers
    static func forStepStatus(_ status: StepStatus) -> StatusBadge {
        switch status {
        case .locked: return StatusBadge("Locked", color: FFColors.textSecondary)
        case .todo: return StatusBadge("To Do", color: FFColors.accentCyan)
        case .inProgress: return StatusBadge("In Progress", color: FFColors.warning)
        case .signed: return StatusBadge("Signed", color: FFColors.success)
        case .complete: return StatusBadge("Complete", color: FFColors.success)
        }
    }

    static func forWorkflowStatus(_ status: WorkflowStatus) -> StatusBadge {
        switch status {
        case .draft: return StatusBadge("Draft", color: FFColors.textSecondary)
        case .inProgress: return StatusBadge("In Progress", color: FFColors.warning)
        case .complete: return StatusBadge("Complete", color: FFColors.success)
        case .overdue: return StatusBadge("Overdue", color: FFColors.danger)
        }
    }

    static func forPriority(_ priority: WorkflowPriority) -> StatusBadge {
        switch priority {
        case .standard: return StatusBadge("Standard", color: FFColors.textSecondary)
        case .high: return StatusBadge("High", color: FFColors.warning)
        case .critical: return StatusBadge("Critical", color: FFColors.danger)
        }
    }

    static func forRole(_ role: UserRole) -> StatusBadge {
        switch role {
        case .admin: return StatusBadge("Admin", color: FFColors.roleAdmin)
        case .manager: return StatusBadge("Manager", color: FFColors.roleManager)
        case .worker: return StatusBadge("Worker", color: FFColors.roleWorker)
        case .viewer: return StatusBadge("Viewer", color: FFColors.roleViewer)
        }
    }

    static func forTemplateStatus(_ status: TemplateStatus) -> StatusBadge {
        switch status {
        case .draft: return StatusBadge("Draft", color: FFColors.textSecondary)
        case .active: return StatusBadge("Active", color: FFColors.success)
        case .archived: return StatusBadge("Archived", color: FFColors.textSecondary)
        }
    }
}

// MARK: - Avatar View

struct AvatarView: View {
    let initials: String
    let role: UserRole
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(roleColor.opacity(0.3))
                .frame(width: size, height: size)

            Text(initials)
                .font(.system(size: size * 0.35, weight: .semibold))
                .foregroundColor(roleColor)
        }
    }

    private var roleColor: Color {
        switch role {
        case .admin: return FFColors.roleAdmin
        case .manager: return FFColors.roleManager
        case .worker: return FFColors.roleWorker
        case .viewer: return FFColors.roleViewer
        }
    }
}

// MARK: - Offline Banner

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .medium))
            Text("Working Offline — changes will sync when connected")
                .font(FFTypography.bodySmall())
        }
        .foregroundColor(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(FFColors.warning)
    }
}

// MARK: - Progress Step Bar

struct StepProgressBar: View {
    let totalSteps: Int
    let completedSteps: Int
    let currentStep: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorForStep(step))
                    .frame(height: 6)
            }
        }
    }

    private func colorForStep(_ step: Int) -> Color {
        if step <= completedSteps {
            return FFColors.success
        } else if step == currentStep {
            return FFColors.accentCyan
        } else {
            return FFColors.border
        }
    }
}

// MARK: - Loading States

struct LoadingView: View {
    var message: String = "Loading…"

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FFColors.accentCyan))
                .scaleEffect(1.2)
            Text(message)
                .font(FFTypography.bodyMedium())
                .foregroundColor(FFColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FFColors.primaryNavy)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56, weight: .thin))
                .foregroundColor(FFColors.accentCyan.opacity(0.6))
            Text(title)
                .font(FFTypography.displaySmall())
                .foregroundColor(FFColors.textPrimary)
            Text(subtitle)
                .font(FFTypography.bodyMedium())
                .foregroundColor(FFColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Due Date Label

struct DueDateLabel: View {
    let date: Date?

    var body: some View {
        if let date = date {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text(relativeString(for: date))
                    .font(FFTypography.bodySmall())
            }
            .foregroundColor(urgencyColor(for: date))
        }
    }

    private func relativeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func urgencyColor(for date: Date) -> Color {
        let hours = date.timeIntervalSinceNow / 3600
        if hours < 0 { return FFColors.danger }
        if hours < 4 { return FFColors.warning }
        return FFColors.success
    }
}
