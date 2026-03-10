import CoreData

// MARK: - Core Data Stack

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    @Published var loadError: Error?

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FormFlow")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                // Log the error and set state — do NOT crash in production
                print("[FormFlow] Core Data failed to load: \(error.localizedDescription)")
                self?.loadError = error

                // Attempt recovery: destroy and recreate the store
                if let storeURL = self?.container.persistentStoreDescriptions.first?.url {
                    try? FileManager.default.removeItem(at: storeURL)
                    self?.container.loadPersistentStores { _, retryError in
                        if let retryError = retryError {
                            print("[FormFlow] Core Data recovery failed: \(retryError.localizedDescription)")
                        }
                    }
                }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Background Context

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: - Save

    func save(context: NSManagedObjectContext? = nil) {
        let ctx = context ?? viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            let nsError = error as NSError
            print("Core Data save error: \(nsError), \(nsError.userInfo)")
        }
    }

    // MARK: - Preview

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.viewContext

        // Seed preview data
        let org = CDOrganization(context: ctx)
        org.id = MockData.orgId
        org.name = "Acme Oil & Gas"
        org.plan = "pro"
        org.createdAt = Date().addingTimeInterval(-86400 * 365)
        org.updatedAt = Date()

        for mockUser in MockData.allUsers {
            let user = CDUser(context: ctx)
            user.id = mockUser.id
            user.organizationId = mockUser.organizationId
            user.email = mockUser.email
            user.displayName = mockUser.displayName
            user.role = mockUser.role.rawValue
            user.mfaEnabled = mockUser.mfaEnabled
            user.deviceId = mockUser.deviceId
            user.isActive = mockUser.isActive
            user.createdAt = mockUser.createdAt
            user.lastActiveAt = mockUser.lastActiveAt
        }

        for mockTemplate in MockData.allTemplates {
            let template = CDTemplate(context: ctx)
            template.id = mockTemplate.id
            template.organizationId = mockTemplate.organizationId
            template.name = mockTemplate.name
            template.status = mockTemplate.status.rawValue
            template.version = Int32(mockTemplate.version)
            template.createdBy = mockTemplate.createdBy
            template.createdAt = mockTemplate.createdAt
            template.updatedAt = mockTemplate.updatedAt

            if let fieldsData = try? JSONEncoder().encode(mockTemplate.fields) {
                template.fieldsJSON = fieldsData
            }
            if let stepsData = try? JSONEncoder().encode(mockTemplate.steps) {
                template.stepsJSON = stepsData
            }
        }

        for mockWorkflow in MockData.allWorkflows {
            let workflow = CDWorkflowInstance(context: ctx)
            workflow.id = mockWorkflow.id
            workflow.organizationId = mockWorkflow.organizationId
            workflow.templateId = mockWorkflow.templateId
            workflow.templateVersion = Int32(mockWorkflow.templateVersion)
            workflow.name = mockWorkflow.name
            workflow.status = mockWorkflow.status.rawValue
            workflow.priority = mockWorkflow.priority.rawValue
            workflow.createdBy = mockWorkflow.createdBy
            workflow.dueDate = mockWorkflow.dueDate
            workflow.createdAt = mockWorkflow.createdAt
            workflow.completedAt = mockWorkflow.completedAt
        }

        for mockStep in MockData.stepAssignments {
            let step = CDStepAssignment(context: ctx)
            step.id = mockStep.id
            step.workflowId = mockStep.workflowId
            step.stepNumber = Int32(mockStep.stepNumber)
            step.stepName = mockStep.stepName
            step.assignedTo = mockStep.assignedTo
            step.assignedBy = mockStep.assignedBy
            step.status = mockStep.status.rawValue
            step.dueDate = mockStep.dueDate
            step.assignedAt = mockStep.assignedAt
            step.completedAt = mockStep.completedAt
            step.isLocked = mockStep.isLocked
            step.lockedAt = mockStep.lockedAt
        }

        for mockEntry in MockData.auditEntries {
            let entry = CDAuditLogEntry(context: ctx)
            entry.id = mockEntry.id
            entry.workflowId = mockEntry.workflowId
            entry.stepNumber = Int32(mockEntry.stepNumber ?? 0)
            entry.actorId = mockEntry.actorId
            entry.actorName = mockEntry.actorName
            entry.actorRole = mockEntry.actorRole
            entry.action = mockEntry.action.rawValue
            entry.entityType = mockEntry.entityType
            entry.entityId = mockEntry.entityId
            entry.metadata = mockEntry.metadata
            entry.timestamp = mockEntry.timestamp
            entry.deviceId = mockEntry.deviceId
        }

        controller.save()
        return controller
    }()
}
