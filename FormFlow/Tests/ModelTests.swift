import XCTest
@testable import FormFlow

final class ModelTests: XCTestCase {

    // MARK: - UserRole Tests

    func testUserRoleHierarchy() {
        XCTAssertGreaterThan(UserRole.admin.hierarchyLevel, UserRole.manager.hierarchyLevel)
        XCTAssertGreaterThan(UserRole.manager.hierarchyLevel, UserRole.worker.hierarchyLevel)
        XCTAssertGreaterThan(UserRole.worker.hierarchyLevel, UserRole.viewer.hierarchyLevel)
    }

    func testUserRolePermissions() {
        // Admin can do everything
        XCTAssertTrue(UserRole.admin.canCreateTemplates)
        XCTAssertTrue(UserRole.admin.canCreateWorkflows)
        XCTAssertTrue(UserRole.admin.canManageUsers)
        XCTAssertTrue(UserRole.admin.canExportPDF)
        XCTAssertTrue(UserRole.admin.canViewAllWorkflows)

        // Manager can create but not manage users
        XCTAssertTrue(UserRole.manager.canCreateTemplates)
        XCTAssertTrue(UserRole.manager.canCreateWorkflows)
        XCTAssertFalse(UserRole.manager.canManageUsers)
        XCTAssertTrue(UserRole.manager.canExportPDF)

        // Worker has limited permissions
        XCTAssertFalse(UserRole.worker.canCreateTemplates)
        XCTAssertFalse(UserRole.worker.canCreateWorkflows)
        XCTAssertFalse(UserRole.worker.canManageUsers)
        XCTAssertFalse(UserRole.worker.canExportPDF)

        // Viewer is read-only
        XCTAssertFalse(UserRole.viewer.canCreateTemplates)
        XCTAssertFalse(UserRole.viewer.canCreateWorkflows)
        XCTAssertFalse(UserRole.viewer.canManageUsers)
        XCTAssertFalse(UserRole.viewer.canExportPDF)
    }

    // MARK: - FFUser Tests

    func testUserAvatarInitials() {
        let user1 = FFUser(
            id: UUID(), organizationId: UUID(), email: "test@test.com",
            displayName: "John Doe", role: .worker, mfaEnabled: false,
            deviceId: "test", isActive: true, createdAt: Date()
        )
        XCTAssertEqual(user1.avatarInitials, "JD")

        let user2 = FFUser(
            id: UUID(), organizationId: UUID(), email: "test@test.com",
            displayName: "Sarah", role: .worker, mfaEnabled: false,
            deviceId: "test", isActive: true, createdAt: Date()
        )
        XCTAssertEqual(user2.avatarInitials, "SA")
    }

    // MARK: - FieldType Tests

    func testFieldTypeIsInputField() {
        XCTAssertTrue(FieldType.text.isInputField)
        XCTAssertTrue(FieldType.number.isInputField)
        XCTAssertTrue(FieldType.yesNo.isInputField)
        XCTAssertTrue(FieldType.signature.isInputField)
        XCTAssertTrue(FieldType.photo.isInputField)

        XCTAssertFalse(FieldType.divider.isInputField)
        XCTAssertFalse(FieldType.infoText.isInputField)
    }

    func testFieldTypeDisplayNames() {
        XCTAssertEqual(FieldType.text.displayName, "Short Text")
        XCTAssertEqual(FieldType.longText.displayName, "Long Text")
        XCTAssertEqual(FieldType.yesNo.displayName, "Yes / No")
        XCTAssertEqual(FieldType.multiSelect.displayName, "Multi-Select")
        XCTAssertEqual(FieldType.dateTime.displayName, "Date & Time")
    }

    func testFieldTypeIcons() {
        // Every field type should have an SF Symbol icon
        for type in FieldType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "\(type) should have an icon")
        }
    }

    // MARK: - WorkflowStatus Tests

    func testWorkflowStatusDisplayNames() {
        XCTAssertEqual(WorkflowStatus.draft.displayName, "Draft")
        XCTAssertEqual(WorkflowStatus.inProgress.displayName, "In Progress")
        XCTAssertEqual(WorkflowStatus.complete.displayName, "Complete")
        XCTAssertEqual(WorkflowStatus.overdue.displayName, "Overdue")
    }

    // MARK: - StepStatus Tests

    func testStepStatusDisplayNames() {
        XCTAssertEqual(StepStatus.locked.displayName, "Locked")
        XCTAssertEqual(StepStatus.todo.displayName, "To Do")
        XCTAssertEqual(StepStatus.inProgress.displayName, "In Progress")
        XCTAssertEqual(StepStatus.signed.displayName, "Signed")
        XCTAssertEqual(StepStatus.complete.displayName, "Complete")
    }

    // MARK: - AuditAction Tests

    func testAuditActionCategories() {
        XCTAssertEqual(AuditAction.stepSigned.category, .signature)
        XCTAssertEqual(AuditAction.fieldResponseSubmitted.category, .fieldChange)
        XCTAssertEqual(AuditAction.handoverInitiated.category, .handover)
        XCTAssertEqual(AuditAction.handoverCompleted.category, .handover)
        XCTAssertEqual(AuditAction.workflowCreated.category, .system)
        XCTAssertEqual(AuditAction.pdfGenerated.category, .system)
    }

    // MARK: - SubscriptionPlan Tests

    func testSubscriptionPlanLimits() {
        XCTAssertEqual(SubscriptionPlan.free.maxTemplates, 3)
        XCTAssertEqual(SubscriptionPlan.free.maxWorkflowsPerMonth, 25)
        XCTAssertEqual(SubscriptionPlan.free.maxUsers, 2)

        XCTAssertEqual(SubscriptionPlan.proMonthly.maxTemplates, Int.max)
        XCTAssertEqual(SubscriptionPlan.proMonthly.maxUsers, 10)

        XCTAssertEqual(SubscriptionPlan.businessMonthly.maxUsers, Int.max)
    }

    // MARK: - Codable Tests

    func testTemplateFieldCodable() throws {
        let field = TemplateField(
            stepNumber: 1,
            type: .number,
            label: "Pressure Reading",
            helpText: "Read the gauge",
            required: true,
            order: 1,
            minValue: 0,
            maxValue: 500,
            unit: "PSI"
        )

        let data = try JSONEncoder().encode(field)
        let decoded = try JSONDecoder().decode(TemplateField.self, from: data)

        XCTAssertEqual(decoded.id, field.id)
        XCTAssertEqual(decoded.label, "Pressure Reading")
        XCTAssertEqual(decoded.type, .number)
        XCTAssertEqual(decoded.minValue, 0)
        XCTAssertEqual(decoded.maxValue, 500)
        XCTAssertEqual(decoded.unit, "PSI")
        XCTAssertTrue(decoded.required)
    }

    func testTemplateStepCodable() throws {
        let step = TemplateStep(
            stepNumber: 1,
            name: "Safety Check",
            requiresSignature: true,
            attestationText: "I confirm safety."
        )

        let data = try JSONEncoder().encode(step)
        let decoded = try JSONDecoder().decode(TemplateStep.self, from: data)

        XCTAssertEqual(decoded.name, "Safety Check")
        XCTAssertTrue(decoded.requiresSignature)
        XCTAssertEqual(decoded.attestationText, "I confirm safety.")
    }

    // MARK: - MockData Tests

    func testMockDataConsistency() {
        // All users belong to the same org
        for user in MockData.allUsers {
            XCTAssertEqual(user.organizationId, MockData.orgId)
        }

        // All templates belong to the same org
        for template in MockData.allTemplates {
            XCTAssertEqual(template.organizationId, MockData.orgId)
        }

        // All workflows reference valid templates
        for workflow in MockData.allWorkflows {
            XCTAssertTrue(
                MockData.allTemplates.contains { $0.id == workflow.templateId },
                "Workflow \(workflow.name) references invalid template"
            )
        }

        // All step assignments reference valid workflows
        for step in MockData.stepAssignments {
            XCTAssertTrue(
                MockData.allWorkflows.contains { $0.id == step.workflowId },
                "Step \(step.stepName) references invalid workflow"
            )
        }
    }

    func testMockDataUsersHaveDistinctRoles() {
        let roles = Set(MockData.allUsers.map { $0.role })
        XCTAssertTrue(roles.contains(.admin))
        XCTAssertTrue(roles.contains(.manager))
        XCTAssertTrue(roles.contains(.worker))
        XCTAssertTrue(roles.contains(.viewer))
    }

    func testMockDataWorkflowsHaveDistinctStatuses() {
        let statuses = Set(MockData.allWorkflows.map { $0.status })
        XCTAssertTrue(statuses.contains(.inProgress))
        XCTAssertTrue(statuses.contains(.complete))
        XCTAssertTrue(statuses.contains(.overdue))
    }
}
