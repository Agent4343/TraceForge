import Foundation

// MARK: - Mock Data for SwiftUI Previews

enum MockData {

    // MARK: - Users

    static let adminUser = FFUser(
        id: UUID(uuidString: "A0000001-0000-0000-0000-000000000001")!,
        organizationId: orgId,
        email: "admin@acmeoil.com",
        displayName: "James Morrison",
        role: .admin,
        mfaEnabled: true,
        deviceId: "DEV-A1B2C3D4",
        isActive: true,
        createdAt: Date().addingTimeInterval(-86400 * 180),
        lastActiveAt: Date()
    )

    static let managerUser = FFUser(
        id: UUID(uuidString: "A0000002-0000-0000-0000-000000000002")!,
        organizationId: orgId,
        email: "sarah.k@acmeoil.com",
        displayName: "Sarah Kim",
        role: .manager,
        mfaEnabled: true,
        deviceId: "DEV-E5F6G7H8",
        isActive: true,
        createdAt: Date().addingTimeInterval(-86400 * 120),
        lastActiveAt: Date().addingTimeInterval(-3600)
    )

    static let workerUser = FFUser(
        id: UUID(uuidString: "A0000003-0000-0000-0000-000000000003")!,
        organizationId: orgId,
        email: "mike.r@acmeoil.com",
        displayName: "Mike Rodriguez",
        role: .worker,
        mfaEnabled: false,
        deviceId: "DEV-I9J0K1L2",
        isActive: true,
        createdAt: Date().addingTimeInterval(-86400 * 90),
        lastActiveAt: Date().addingTimeInterval(-1800)
    )

    static let workerUser2 = FFUser(
        id: UUID(uuidString: "A0000004-0000-0000-0000-000000000004")!,
        organizationId: orgId,
        email: "chen.w@acmeoil.com",
        displayName: "Chen Wei",
        role: .worker,
        mfaEnabled: true,
        deviceId: "DEV-M3N4O5P6",
        isActive: true,
        createdAt: Date().addingTimeInterval(-86400 * 60),
        lastActiveAt: Date().addingTimeInterval(-7200)
    )

    static let viewerUser = FFUser(
        id: UUID(uuidString: "A0000005-0000-0000-0000-000000000005")!,
        organizationId: orgId,
        email: "viewer@acmeoil.com",
        displayName: "Pat Nguyen",
        role: .viewer,
        mfaEnabled: false,
        deviceId: "DEV-Q7R8S9T0",
        isActive: true,
        createdAt: Date().addingTimeInterval(-86400 * 30),
        lastActiveAt: nil
    )

    static let allUsers: [FFUser] = [adminUser, managerUser, workerUser, workerUser2, viewerUser]

    // MARK: - Organization

    static let orgId = UUID(uuidString: "B0000001-0000-0000-0000-000000000001")!

    static let organization = Organization(
        id: orgId,
        name: "Acme Oil & Gas",
        plan: "pro",
        createdAt: Date().addingTimeInterval(-86400 * 365),
        updatedAt: Date()
    )

    // MARK: - Templates

    static let preJobSafetyTemplate: Template = {
        let templateId = UUID(uuidString: "C0000001-0000-0000-0000-000000000001")!
        return Template(
            id: templateId,
            organizationId: orgId,
            name: "Pre-Job Safety Checklist",
            status: .active,
            version: 3,
            fields: [
                TemplateField(id: UUID(uuidString: "D0000001-0000-0000-0000-000000000001")!, stepNumber: 1, type: .text, label: "Job Location", required: true, order: 1, maxLength: 200),
                TemplateField(id: UUID(uuidString: "D0000002-0000-0000-0000-000000000002")!, stepNumber: 1, type: .dropdown, label: "Work Type", required: true, order: 2, options: ["Hot Work", "Cold Work", "Confined Space", "Working at Height", "Electrical"]),
                TemplateField(id: UUID(uuidString: "D0000003-0000-0000-0000-000000000003")!, stepNumber: 1, type: .yesNo, label: "PPE Verified", helpText: "Confirm all required PPE is in place", required: true, order: 3),
                TemplateField(id: UUID(uuidString: "D0000004-0000-0000-0000-000000000004")!, stepNumber: 1, type: .number, label: "Atmospheric LEL Reading", required: true, order: 4, minValue: 0, maxValue: 100, unit: "%LEL"),
                TemplateField(id: UUID(uuidString: "D0000005-0000-0000-0000-000000000005")!, stepNumber: 1, type: .photo, label: "Site Photo", helpText: "Take a photo of the work area", required: true, order: 5, maxPhotos: 3),
                TemplateField(id: UUID(uuidString: "D0000006-0000-0000-0000-000000000006")!, stepNumber: 2, type: .yesNo, label: "Hazards Identified & Mitigated", required: true, order: 1),
                TemplateField(id: UUID(uuidString: "D0000007-0000-0000-0000-000000000007")!, stepNumber: 2, type: .longText, label: "Hazard Details", helpText: "List all identified hazards and mitigations", required: true, order: 2),
                TemplateField(id: UUID(uuidString: "D0000008-0000-0000-0000-000000000008")!, stepNumber: 2, type: .multiSelect, label: "Control Measures", required: true, order: 3, options: ["Barricades", "Fire Watch", "Gas Monitor", "Spotter", "Lockout/Tagout", "Fall Protection"]),
                TemplateField(id: UUID(uuidString: "D0000009-0000-0000-0000-000000000009")!, stepNumber: 3, type: .yesNo, label: "All Steps Verified", required: true, order: 1),
                TemplateField(id: UUID(uuidString: "D000000A-0000-0000-0000-00000000000A")!, stepNumber: 3, type: .signature, label: "HSE Supervisor Sign-Off", required: true, order: 2, attestationText: "I confirm all safety requirements have been met and work may proceed."),
            ],
            steps: [
                TemplateStep(stepNumber: 1, name: "Worker Pre-Job Check", requiresSignature: true),
                TemplateStep(stepNumber: 2, name: "HSE Pre-Job Review", requiresSignature: true),
                TemplateStep(stepNumber: 3, name: "Supervisor Approval", requiresSignature: true, attestationText: "I authorize this work to proceed based on the completed safety assessment."),
            ],
            createdBy: adminUser.id,
            createdAt: Date().addingTimeInterval(-86400 * 60),
            updatedAt: Date().addingTimeInterval(-86400 * 5)
        )
    }()

    static let shiftHandoverTemplate: Template = {
        let templateId = UUID(uuidString: "C0000002-0000-0000-0000-000000000002")!
        return Template(
            id: templateId,
            organizationId: orgId,
            name: "Shift Handover Report",
            status: .active,
            version: 2,
            fields: [
                TemplateField(id: UUID(), stepNumber: 1, type: .text, label: "Outgoing Shift Operator", required: true, order: 1),
                TemplateField(id: UUID(), stepNumber: 1, type: .dropdown, label: "Shift", required: true, order: 2, options: ["Day (06:00-18:00)", "Night (18:00-06:00)"]),
                TemplateField(id: UUID(), stepNumber: 1, type: .longText, label: "Operations Summary", helpText: "Summarize key activities during your shift", required: true, order: 3),
                TemplateField(id: UUID(), stepNumber: 1, type: .yesNo, label: "All Equipment Operational", required: true, order: 4),
                TemplateField(id: UUID(), stepNumber: 1, type: .longText, label: "Outstanding Issues", required: false, order: 5),
                TemplateField(id: UUID(), stepNumber: 1, type: .number, label: "Production Rate", required: true, order: 6, minValue: 0, maxValue: 50000, unit: "bbl/day"),
                TemplateField(id: UUID(), stepNumber: 2, type: .yesNo, label: "Handover Received", required: true, order: 1),
                TemplateField(id: UUID(), stepNumber: 2, type: .longText, label: "Incoming Shift Notes", required: false, order: 2),
                TemplateField(id: UUID(), stepNumber: 2, type: .signature, label: "Incoming Operator Signature", required: true, order: 3, attestationText: "I confirm I have received this shift handover and understand all outstanding items."),
            ],
            steps: [
                TemplateStep(stepNumber: 1, name: "Outgoing Shift Report", requiresSignature: true),
                TemplateStep(stepNumber: 2, name: "Incoming Shift Acknowledgment", requiresSignature: true),
            ],
            createdBy: managerUser.id,
            createdAt: Date().addingTimeInterval(-86400 * 45),
            updatedAt: Date().addingTimeInterval(-86400 * 3)
        )
    }()

    static let equipmentInspectionTemplate: Template = {
        let templateId = UUID(uuidString: "C0000003-0000-0000-0000-000000000003")!
        return Template(
            id: templateId,
            organizationId: orgId,
            name: "Equipment Inspection Checklist",
            status: .active,
            version: 1,
            fields: [
                TemplateField(id: UUID(), stepNumber: 1, type: .text, label: "Equipment ID", required: true, order: 1),
                TemplateField(id: UUID(), stepNumber: 1, type: .dropdown, label: "Equipment Type", required: true, order: 2, options: ["Pump", "Valve", "Compressor", "Heat Exchanger", "Vessel", "Piping"]),
                TemplateField(id: UUID(), stepNumber: 1, type: .date, label: "Inspection Date", required: true, order: 3),
                TemplateField(id: UUID(), stepNumber: 1, type: .yesNo, label: "Visual Condition OK", required: true, order: 4),
                TemplateField(id: UUID(), stepNumber: 1, type: .yesNo, label: "Corrosion Detected", required: true, order: 5),
                TemplateField(id: UUID(), stepNumber: 1, type: .number, label: "Wall Thickness Reading", required: false, order: 6, minValue: 0, maxValue: 100, unit: "mm"),
                TemplateField(id: UUID(), stepNumber: 1, type: .photo, label: "Equipment Photos", helpText: "Capture overall condition photos", required: true, order: 7, maxPhotos: 5),
                TemplateField(id: UUID(), stepNumber: 1, type: .longText, label: "Inspector Notes", required: false, order: 8),
                TemplateField(id: UUID(), stepNumber: 2, type: .yesNo, label: "Findings Reviewed", required: true, order: 1),
                TemplateField(id: UUID(), stepNumber: 2, type: .dropdown, label: "Action Required", required: true, order: 2, options: ["None", "Monitor", "Repair Required", "Replace", "Shutdown"]),
                TemplateField(id: UUID(), stepNumber: 2, type: .date, label: "Next Inspection Due", required: true, order: 3),
                TemplateField(id: UUID(), stepNumber: 2, type: .signature, label: "Engineering Sign-Off", required: true, order: 4, attestationText: "I have reviewed the inspection findings and approve the recommended actions."),
            ],
            steps: [
                TemplateStep(stepNumber: 1, name: "Field Inspection", requiresSignature: true),
                TemplateStep(stepNumber: 2, name: "Engineering Review", requiresSignature: true),
            ],
            createdBy: managerUser.id,
            createdAt: Date().addingTimeInterval(-86400 * 30),
            updatedAt: Date().addingTimeInterval(-86400 * 10)
        )
    }()

    static let allTemplates: [Template] = [preJobSafetyTemplate, shiftHandoverTemplate, equipmentInspectionTemplate]

    // MARK: - Workflow Instances

    static let activeWorkflow: WorkflowInstance = {
        return WorkflowInstance(
            id: UUID(uuidString: "E0000001-0000-0000-0000-000000000001")!,
            organizationId: orgId,
            templateId: preJobSafetyTemplate.id,
            templateVersion: 3,
            name: "Platform A — Hot Work Permit #2847",
            siteId: nil,
            status: .inProgress,
            priority: .high,
            createdBy: managerUser.id,
            dueDate: Date().addingTimeInterval(3600 * 4),
            createdAt: Date().addingTimeInterval(-3600 * 2),
            completedAt: nil,
            pdfUrl: nil,
            pdfHash: nil
        )
    }()

    static let completedWorkflow: WorkflowInstance = {
        return WorkflowInstance(
            id: UUID(uuidString: "E0000002-0000-0000-0000-000000000002")!,
            organizationId: orgId,
            templateId: shiftHandoverTemplate.id,
            templateVersion: 2,
            name: "Night Shift Handover — March 9",
            siteId: nil,
            status: .complete,
            priority: .standard,
            createdBy: workerUser.id,
            dueDate: Date().addingTimeInterval(-86400),
            createdAt: Date().addingTimeInterval(-86400 * 2),
            completedAt: Date().addingTimeInterval(-86400),
            pdfUrl: "https://api.formflow.io/pdfs/handover-march9.pdf",
            pdfHash: "a3f2b8c1d4e5f67890abcdef12345678abcdef12345678abcdef1234567890ab"
        )
    }()

    static let overdueWorkflow: WorkflowInstance = {
        return WorkflowInstance(
            id: UUID(uuidString: "E0000003-0000-0000-0000-000000000003")!,
            organizationId: orgId,
            templateId: equipmentInspectionTemplate.id,
            templateVersion: 1,
            name: "Compressor C-102 Inspection",
            siteId: nil,
            status: .overdue,
            priority: .critical,
            createdBy: managerUser.id,
            dueDate: Date().addingTimeInterval(-3600 * 12),
            createdAt: Date().addingTimeInterval(-86400 * 3),
            completedAt: nil,
            pdfUrl: nil,
            pdfHash: nil
        )
    }()

    static let allWorkflows: [WorkflowInstance] = [activeWorkflow, completedWorkflow, overdueWorkflow]

    // MARK: - Step Assignments

    static let stepAssignments: [StepAssignment] = [
        // Active workflow steps
        StepAssignment(id: UUID(), workflowId: activeWorkflow.id, stepNumber: 1, stepName: "Worker Pre-Job Check", assignedTo: workerUser.id, assignedBy: managerUser.id, status: .complete, dueDate: Date().addingTimeInterval(3600 * 2), assignedAt: Date().addingTimeInterval(-3600 * 2), completedAt: Date().addingTimeInterval(-3600), isLocked: true, lockedAt: Date().addingTimeInterval(-3600)),
        StepAssignment(id: UUID(), workflowId: activeWorkflow.id, stepNumber: 2, stepName: "HSE Pre-Job Review", assignedTo: workerUser2.id, assignedBy: managerUser.id, status: .inProgress, dueDate: Date().addingTimeInterval(3600 * 3), assignedAt: Date().addingTimeInterval(-3600 * 2), completedAt: nil, isLocked: false, lockedAt: nil),
        StepAssignment(id: UUID(), workflowId: activeWorkflow.id, stepNumber: 3, stepName: "Supervisor Approval", assignedTo: managerUser.id, assignedBy: managerUser.id, status: .locked, dueDate: Date().addingTimeInterval(3600 * 4), assignedAt: Date().addingTimeInterval(-3600 * 2), completedAt: nil, isLocked: true, lockedAt: nil),
        // Overdue workflow steps
        StepAssignment(id: UUID(), workflowId: overdueWorkflow.id, stepNumber: 1, stepName: "Field Inspection", assignedTo: workerUser.id, assignedBy: managerUser.id, status: .inProgress, dueDate: Date().addingTimeInterval(-3600 * 12), assignedAt: Date().addingTimeInterval(-86400 * 3), completedAt: nil, isLocked: false, lockedAt: nil),
        StepAssignment(id: UUID(), workflowId: overdueWorkflow.id, stepNumber: 2, stepName: "Engineering Review", assignedTo: workerUser2.id, assignedBy: managerUser.id, status: .locked, dueDate: Date().addingTimeInterval(-3600 * 6), assignedAt: Date().addingTimeInterval(-86400 * 3), completedAt: nil, isLocked: true, lockedAt: nil),
    ]

    // MARK: - Audit Log

    static let auditEntries: [AuditLogEntry] = [
        AuditLogEntry(id: UUID(), workflowId: activeWorkflow.id, stepNumber: 1, actorId: managerUser.id, actorName: "Sarah Kim", actorRole: "manager", action: .workflowCreated, entityType: "workflow", entityId: activeWorkflow.id, metadata: "{}", timestamp: Date().addingTimeInterval(-3600 * 2), deviceId: "DEV-E5F6G7H8"),
        AuditLogEntry(id: UUID(), workflowId: activeWorkflow.id, stepNumber: 1, actorId: managerUser.id, actorName: "Sarah Kim", actorRole: "manager", action: .stepAssigned, entityType: "step", entityId: UUID(), metadata: "{\"step_number\": 1, \"assigned_to\": \"Mike Rodriguez\"}", timestamp: Date().addingTimeInterval(-3600 * 2 + 10), deviceId: "DEV-E5F6G7H8"),
        AuditLogEntry(id: UUID(), workflowId: activeWorkflow.id, stepNumber: 1, actorId: workerUser.id, actorName: "Mike Rodriguez", actorRole: "worker", action: .fieldResponseSubmitted, entityType: "response", entityId: UUID(), metadata: "{\"field\": \"Job Location\", \"value\": \"Platform A, Deck 3\"}", timestamp: Date().addingTimeInterval(-3600 * 1.5), deviceId: "DEV-I9J0K1L2"),
        AuditLogEntry(id: UUID(), workflowId: activeWorkflow.id, stepNumber: 1, actorId: workerUser.id, actorName: "Mike Rodriguez", actorRole: "worker", action: .fieldResponseSubmitted, entityType: "response", entityId: UUID(), metadata: "{\"field\": \"PPE Verified\", \"value\": \"Yes\"}", timestamp: Date().addingTimeInterval(-3600 * 1.4), deviceId: "DEV-I9J0K1L2"),
        AuditLogEntry(id: UUID(), workflowId: activeWorkflow.id, stepNumber: 1, actorId: workerUser.id, actorName: "Mike Rodriguez", actorRole: "worker", action: .fieldResponseSubmitted, entityType: "response", entityId: UUID(), metadata: "{\"field\": \"Atmospheric LEL Reading\", \"value\": \"3.2 %LEL\"}", timestamp: Date().addingTimeInterval(-3600 * 1.3), deviceId: "DEV-I9J0K1L2"),
        AuditLogEntry(id: UUID(), workflowId: activeWorkflow.id, stepNumber: 1, actorId: workerUser.id, actorName: "Mike Rodriguez", actorRole: "worker", action: .stepSigned, entityType: "signature", entityId: UUID(), metadata: "{\"hash\": \"a1b2c3d4...\"}", timestamp: Date().addingTimeInterval(-3600), deviceId: "DEV-I9J0K1L2"),
        AuditLogEntry(id: UUID(), workflowId: activeWorkflow.id, stepNumber: 2, actorId: workerUser2.id, actorName: "Chen Wei", actorRole: "worker", action: .fieldResponseSubmitted, entityType: "response", entityId: UUID(), metadata: "{\"field\": \"Hazards Identified & Mitigated\", \"value\": \"Yes\"}", timestamp: Date().addingTimeInterval(-1800), deviceId: "DEV-M3N4O5P6"),
        AuditLogEntry(id: UUID(), workflowId: completedWorkflow.id, stepNumber: 1, actorId: workerUser.id, actorName: "Mike Rodriguez", actorRole: "worker", action: .stepSigned, entityType: "signature", entityId: UUID(), metadata: "{\"hash\": \"e5f6g7h8...\"}", timestamp: Date().addingTimeInterval(-86400 - 3600), deviceId: "DEV-I9J0K1L2"),
        AuditLogEntry(id: UUID(), workflowId: completedWorkflow.id, stepNumber: 2, actorId: workerUser2.id, actorName: "Chen Wei", actorRole: "worker", action: .stepSigned, entityType: "signature", entityId: UUID(), metadata: "{\"hash\": \"i9j0k1l2...\"}", timestamp: Date().addingTimeInterval(-86400), deviceId: "DEV-M3N4O5P6"),
        AuditLogEntry(id: UUID(), workflowId: completedWorkflow.id, stepNumber: nil, actorId: workerUser2.id, actorName: "Chen Wei", actorRole: "worker", action: .workflowCompleted, entityType: "workflow", entityId: completedWorkflow.id, metadata: "{}", timestamp: Date().addingTimeInterval(-86400), deviceId: "DEV-M3N4O5P6"),
        AuditLogEntry(id: UUID(), workflowId: completedWorkflow.id, stepNumber: nil, actorId: managerUser.id, actorName: "Sarah Kim", actorRole: "manager", action: .pdfGenerated, entityType: "pdf", entityId: completedWorkflow.id, metadata: "{\"hash\": \"a3f2b8c1...\"}", timestamp: Date().addingTimeInterval(-86400 + 600), deviceId: "DEV-E5F6G7H8"),
    ]

    // MARK: - Task Items (computed from assignments)

    struct TaskItem: Identifiable {
        let id: UUID
        let workflowName: String
        let stepNumber: Int
        let totalSteps: Int
        let stepName: String
        let assignedBy: String
        let assignedAt: Date
        let dueDate: Date?
        let status: StepStatus
        let priority: WorkflowPriority
        let workflowId: UUID
    }

    static let myTasks: [TaskItem] = [
        TaskItem(
            id: UUID(),
            workflowName: "Platform A — Hot Work Permit #2847",
            stepNumber: 2,
            totalSteps: 3,
            stepName: "HSE Pre-Job Review",
            assignedBy: "Sarah Kim",
            assignedAt: Date().addingTimeInterval(-3600 * 2),
            dueDate: Date().addingTimeInterval(3600 * 3),
            status: .inProgress,
            priority: .high,
            workflowId: activeWorkflow.id
        ),
        TaskItem(
            id: UUID(),
            workflowName: "Compressor C-102 Inspection",
            stepNumber: 1,
            totalSteps: 2,
            stepName: "Field Inspection",
            assignedBy: "Sarah Kim",
            assignedAt: Date().addingTimeInterval(-86400 * 3),
            dueDate: Date().addingTimeInterval(-3600 * 12),
            status: .inProgress,
            priority: .critical,
            workflowId: overdueWorkflow.id
        ),
    ]
}
