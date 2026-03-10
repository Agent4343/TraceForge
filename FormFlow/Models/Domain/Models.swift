import Foundation

// MARK: - User Role

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case admin
    case manager
    case worker
    case viewer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .manager: return "Manager"
        case .worker: return "Worker"
        case .viewer: return "Viewer"
        }
    }

    var hierarchyLevel: Int {
        switch self {
        case .admin: return 4
        case .manager: return 3
        case .worker: return 2
        case .viewer: return 1
        }
    }

    var canCreateTemplates: Bool { hierarchyLevel >= UserRole.manager.hierarchyLevel }
    var canCreateWorkflows: Bool { hierarchyLevel >= UserRole.manager.hierarchyLevel }
    var canAssignSteps: Bool { hierarchyLevel >= UserRole.manager.hierarchyLevel }
    var canViewAllWorkflows: Bool { hierarchyLevel >= UserRole.manager.hierarchyLevel }
    var canExportPDF: Bool { hierarchyLevel >= UserRole.manager.hierarchyLevel }
    var canManageUsers: Bool { self == .admin }
    var canViewAuditTrail: Bool { hierarchyLevel >= UserRole.manager.hierarchyLevel }
    var canViewDashboard: Bool { hierarchyLevel >= UserRole.manager.hierarchyLevel }
}

// MARK: - Organization

struct Organization: Identifiable, Codable {
    let id: UUID
    var name: String
    var plan: String
    let createdAt: Date
    var updatedAt: Date
}

// MARK: - User

struct FFUser: Identifiable, Codable {
    let id: UUID
    let organizationId: UUID
    var email: String
    var displayName: String
    var role: UserRole
    var mfaEnabled: Bool
    var deviceId: String
    var isActive: Bool
    let createdAt: Date
    var lastActiveAt: Date?
    var avatarInitials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(displayName.prefix(2)).uppercased()
    }
}

// MARK: - Template

struct Template: Identifiable, Codable {
    let id: UUID
    let organizationId: UUID
    var name: String
    var status: TemplateStatus
    var version: Int
    var fields: [TemplateField]
    var steps: [TemplateStep]
    let createdBy: UUID
    let createdAt: Date
    var updatedAt: Date
}

enum TemplateStatus: String, Codable, CaseIterable {
    case draft
    case active
    case archived

    var displayName: String {
        rawValue.capitalized
    }
}

struct TemplateStep: Identifiable, Codable {
    let id: UUID
    var stepNumber: Int
    var name: String
    var requiresSignature: Bool
    var attestationText: String?

    init(id: UUID = UUID(), stepNumber: Int, name: String, requiresSignature: Bool = true, attestationText: String? = nil) {
        self.id = id
        self.stepNumber = stepNumber
        self.name = name
        self.requiresSignature = requiresSignature
        self.attestationText = attestationText
    }
}

// MARK: - Template Field

enum FieldType: String, Codable, CaseIterable, Identifiable {
    case text
    case longText = "long_text"
    case number
    case yesNo = "yes_no"
    case dropdown
    case multiSelect = "multi_select"
    case date
    case dateTime = "date_time"
    case photo
    case signature
    case divider
    case infoText = "info_text"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .text: return "Short Text"
        case .longText: return "Long Text"
        case .number: return "Number"
        case .yesNo: return "Yes / No"
        case .dropdown: return "Dropdown"
        case .multiSelect: return "Multi-Select"
        case .date: return "Date"
        case .dateTime: return "Date & Time"
        case .photo: return "Photo"
        case .signature: return "Signature"
        case .divider: return "Divider"
        case .infoText: return "Info Text"
        }
    }

    var icon: String {
        switch self {
        case .text: return "textformat"
        case .longText: return "text.alignleft"
        case .number: return "number"
        case .yesNo: return "checkmark.circle"
        case .dropdown: return "chevron.down.circle"
        case .multiSelect: return "checklist"
        case .date: return "calendar"
        case .dateTime: return "calendar.badge.clock"
        case .photo: return "camera"
        case .signature: return "signature"
        case .divider: return "minus"
        case .infoText: return "info.circle"
        }
    }

    var isInputField: Bool {
        switch self {
        case .divider, .infoText: return false
        default: return true
        }
    }
}

struct TemplateField: Identifiable, Codable {
    let id: UUID
    var stepNumber: Int
    var type: FieldType
    var label: String
    var helpText: String?
    var required: Bool
    var order: Int
    var options: [String]?
    var minValue: Double?
    var maxValue: Double?
    var unit: String?
    var maxPhotos: Int?
    var attestationText: String?
    var maxLength: Int?
    var requireAnnotation: Bool?

    init(
        id: UUID = UUID(),
        stepNumber: Int,
        type: FieldType,
        label: String,
        helpText: String? = nil,
        required: Bool = false,
        order: Int = 0,
        options: [String]? = nil,
        minValue: Double? = nil,
        maxValue: Double? = nil,
        unit: String? = nil,
        maxPhotos: Int? = nil,
        attestationText: String? = nil,
        maxLength: Int? = nil,
        requireAnnotation: Bool? = nil
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.type = type
        self.label = label
        self.helpText = helpText
        self.required = required
        self.order = order
        self.options = options
        self.minValue = minValue
        self.maxValue = maxValue
        self.unit = unit
        self.maxPhotos = maxPhotos
        self.attestationText = attestationText
        self.maxLength = maxLength
        self.requireAnnotation = requireAnnotation
    }
}

// MARK: - Workflow Instance

struct WorkflowInstance: Identifiable, Codable {
    let id: UUID
    let organizationId: UUID
    let templateId: UUID
    let templateVersion: Int
    var name: String
    var siteId: UUID?
    var status: WorkflowStatus
    var priority: WorkflowPriority
    let createdBy: UUID
    var dueDate: Date?
    let createdAt: Date
    var completedAt: Date?
    var pdfUrl: String?
    var pdfHash: String?
}

enum WorkflowStatus: String, Codable, CaseIterable {
    case draft
    case inProgress = "in_progress"
    case complete
    case overdue

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .inProgress: return "In Progress"
        case .complete: return "Complete"
        case .overdue: return "Overdue"
        }
    }
}

enum WorkflowPriority: String, Codable, CaseIterable {
    case standard
    case high
    case critical

    var displayName: String { rawValue.capitalized }
}

// MARK: - Step Assignment

struct StepAssignment: Identifiable, Codable {
    let id: UUID
    let workflowId: UUID
    var stepNumber: Int
    var stepName: String
    var assignedTo: UUID
    var assignedBy: UUID
    var status: StepStatus
    var dueDate: Date?
    let assignedAt: Date
    var completedAt: Date?
    var isLocked: Bool
    var lockedAt: Date?
}

enum StepStatus: String, Codable, CaseIterable {
    case locked
    case todo
    case inProgress = "in_progress"
    case signed
    case complete

    var displayName: String {
        switch self {
        case .locked: return "Locked"
        case .todo: return "To Do"
        case .inProgress: return "In Progress"
        case .signed: return "Signed"
        case .complete: return "Complete"
        }
    }
}

// MARK: - Form Response

struct FormResponse: Identifiable, Codable {
    let id: UUID
    let workflowId: UUID
    let stepNumber: Int
    let fieldId: UUID
    var fieldLabel: String
    var value: String
    let respondedBy: UUID
    let deviceId: String
    var timestamp: Date
    var synced: Bool
    var syncAttemptedAt: Date?
}

// MARK: - Signature Record

struct SignatureRecord: Identifiable, Codable {
    let id: UUID
    let workflowId: UUID
    let stepNumber: Int
    let signerId: UUID
    let signerName: String
    let signerRole: String
    var signatureImageData: Data
    let attestationText: String
    let deviceId: String
    let timestamp: Date
    var ipAddress: String?
    var mfaVerified: Bool
    var contentHash: String
    var synced: Bool
}

// MARK: - Sync Operation

struct SyncOperation: Identifiable, Codable {
    let id: UUID
    let type: SyncOperationType
    let entityType: String
    let entityId: UUID
    var fieldId: UUID?
    var value: String?
    let timestamp: Date
    let deviceId: String
    var synced: Bool
    var syncAttemptedAt: Date?
    var errorMessage: String?
}

enum SyncOperationType: String, Codable {
    case createResponse = "create_response"
    case updateResponse = "update_response"
    case signStep = "sign_step"
    case handover
}

// MARK: - Audit Log Entry

struct AuditLogEntry: Identifiable, Codable {
    let id: UUID
    let workflowId: UUID
    var stepNumber: Int?
    let actorId: UUID
    let actorName: String
    let actorRole: String
    let action: AuditAction
    let entityType: String
    let entityId: UUID
    var metadata: String
    let timestamp: Date
    let deviceId: String
}

enum AuditAction: String, Codable {
    case fieldResponseSubmitted = "field_response_submitted"
    case stepSigned = "step_signed"
    case handoverInitiated = "handover_initiated"
    case handoverCompleted = "handover_completed"
    case workflowCreated = "workflow_created"
    case workflowCompleted = "workflow_completed"
    case stepAssigned = "step_assigned"
    case stepUnlocked = "step_unlocked"
    case pdfGenerated = "pdf_generated"
    case userLogin = "user_login"
    case conflictResolved = "conflict_resolved"

    var displayText: String {
        switch self {
        case .fieldResponseSubmitted: return "submitted a response"
        case .stepSigned: return "signed a step"
        case .handoverInitiated: return "initiated a handover"
        case .handoverCompleted: return "completed a handover"
        case .workflowCreated: return "created workflow"
        case .workflowCompleted: return "completed workflow"
        case .stepAssigned: return "assigned a step"
        case .stepUnlocked: return "unlocked a step"
        case .pdfGenerated: return "generated PDF"
        case .userLogin: return "logged in"
        case .conflictResolved: return "resolved conflict"
        }
    }

    var category: AuditCategory {
        switch self {
        case .stepSigned: return .signature
        case .fieldResponseSubmitted: return .fieldChange
        case .handoverInitiated, .handoverCompleted: return .handover
        default: return .system
        }
    }
}

enum AuditCategory: String, CaseIterable {
    case all = "All"
    case signature = "Signatures"
    case fieldChange = "Field Changes"
    case handover = "Handovers"
    case system = "System"
}

// MARK: - Task Filter

enum TaskFilter: String, CaseIterable {
    case all = "All"
    case dueToday = "Due Today"
    case overdue = "Overdue"
    case pendingHandover = "Pending Handover"
}

// MARK: - Subscription Plan

enum SubscriptionPlan: String, Codable {
    case free
    case proMonthly = "formflow.pro.monthly"
    case proAnnual = "formflow.pro.annual"
    case businessMonthly = "formflow.business.monthly"
    case businessAnnual = "formflow.business.annual"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .proMonthly, .proAnnual: return "Pro"
        case .businessMonthly, .businessAnnual: return "Business"
        }
    }

    var maxTemplates: Int {
        switch self {
        case .free: return 3
        case .proMonthly, .proAnnual: return Int.max
        case .businessMonthly, .businessAnnual: return Int.max
        }
    }

    var maxWorkflowsPerMonth: Int {
        switch self {
        case .free: return 25
        case .proMonthly, .proAnnual: return Int.max
        case .businessMonthly, .businessAnnual: return Int.max
        }
    }

    var maxUsers: Int {
        switch self {
        case .free: return 2
        case .proMonthly, .proAnnual: return 10
        case .businessMonthly, .businessAnnual: return Int.max
        }
    }
}

// MARK: - Handover

struct HandoverRequest: Codable {
    let stepAssignmentId: UUID
    let fromUserId: UUID
    let toUserId: UUID
    let note: String
    let contextPhotoData: Data?
    let timestamp: Date
}
