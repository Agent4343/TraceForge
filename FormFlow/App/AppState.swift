import SwiftUI
import Combine

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    // Auth state
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var currentUser: FFUser?
    @Published var organization: Organization?
    @Published var authError: String?

    // Network state
    @Published var isOnline: Bool = true
    @Published var lastSyncDate: Date?
    @Published var pendingSyncCount: Int = 0

    // Navigation
    @Published var selectedTab: AppTab = .myTasks
    @Published var showOnboarding: Bool = false

    // Subscription
    @Published var currentPlan: SubscriptionPlan = .free
    @Published var trialDaysRemaining: Int? = 14

    // Settings
    @Published var requireBiometrics: Bool = false
    @Published var autoLockInterval: TimeInterval = 300 // 5 min

    // Mock data stores (replace with Core Data in production)
    @Published var templates: [Template] = MockData.allTemplates
    @Published var workflows: [WorkflowInstance] = MockData.allWorkflows
    @Published var stepAssignments: [StepAssignment] = MockData.stepAssignments
    @Published var auditLog: [AuditLogEntry] = MockData.auditEntries
    @Published var users: [FFUser] = MockData.allUsers
    @Published var formResponses: [UUID: [UUID: String]] = [:] // workflowId -> fieldId -> value

    func login(email: String, password: String) {
        isLoading = true
        authError = nil

        // Simulate network delay
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard let self else { return }
            self.isLoading = false

            if email.lowercased().contains("admin") {
                self.currentUser = MockData.adminUser
            } else if email.lowercased().contains("manager") || email.lowercased().contains("sarah") {
                self.currentUser = MockData.managerUser
            } else if email.lowercased().contains("viewer") {
                self.currentUser = MockData.viewerUser
            } else {
                self.currentUser = MockData.workerUser
            }
            self.organization = MockData.organization
            self.isAuthenticated = true
        }
    }

    func logout() {
        isAuthenticated = false
        currentUser = nil
        organization = nil
        selectedTab = .myTasks
    }

    func tasksForCurrentUser() -> [MockData.TaskItem] {
        return MockData.myTasks
    }

    func stepsForWorkflow(_ workflowId: UUID) -> [StepAssignment] {
        return stepAssignments.filter { $0.workflowId == workflowId }
    }

    func templateForWorkflow(_ workflow: WorkflowInstance) -> Template? {
        return templates.first { $0.id == workflow.templateId }
    }

    func auditEntriesForWorkflow(_ workflowId: UUID) -> [AuditLogEntry] {
        return auditLog.filter { $0.workflowId == workflowId }.sorted { $0.timestamp > $1.timestamp }
    }

    func saveResponse(workflowId: UUID, fieldId: UUID, value: String) {
        if formResponses[workflowId] == nil {
            formResponses[workflowId] = [:]
        }
        formResponses[workflowId]?[fieldId] = value
    }

    func getResponse(workflowId: UUID, fieldId: UUID) -> String? {
        return formResponses[workflowId]?[fieldId]
    }
}

// MARK: - App Tabs

enum AppTab: String, CaseIterable {
    case myTasks = "My Tasks"
    case workflows = "Workflows"
    case templates = "Templates"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .myTasks: return "person.badge.checkmark"
        case .workflows: return "arrow.triangle.branch"
        case .templates: return "doc.on.doc"
        case .profile: return "person.circle"
        }
    }
}
