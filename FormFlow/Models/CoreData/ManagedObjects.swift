import CoreData
import Foundation

// MARK: - Core Data Managed Object Subclasses
// These mirror the domain models and are used for local persistence and offline queue.

// MARK: - CDOrganization

class CDOrganization: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var plan: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
}

extension CDOrganization {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDOrganization"
        entity.managedObjectClassName = NSStringFromClass(CDOrganization.self)

        let id = NSAttributeDescription(); id.name = "id"; id.attributeType = .UUIDAttributeType
        let name = NSAttributeDescription(); name.name = "name"; name.attributeType = .stringAttributeType
        let plan = NSAttributeDescription(); plan.name = "plan"; plan.attributeType = .stringAttributeType
        let createdAt = NSAttributeDescription(); createdAt.name = "createdAt"; createdAt.attributeType = .dateAttributeType
        let updatedAt = NSAttributeDescription(); updatedAt.name = "updatedAt"; updatedAt.attributeType = .dateAttributeType

        entity.properties = [id, name, plan, createdAt, updatedAt]
        return entity
    }

    func toDomain() -> Organization {
        Organization(id: id, name: name, plan: plan, createdAt: createdAt, updatedAt: updatedAt)
    }
}

// MARK: - CDUser

class CDUser: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var organizationId: UUID
    @NSManaged var email: String
    @NSManaged var displayName: String
    @NSManaged var role: String
    @NSManaged var mfaEnabled: Bool
    @NSManaged var deviceId: String
    @NSManaged var isActive: Bool
    @NSManaged var createdAt: Date
    @NSManaged var lastActiveAt: Date?
}

extension CDUser {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDUser"
        entity.managedObjectClassName = NSStringFromClass(CDUser.self)

        let id = NSAttributeDescription(); id.name = "id"; id.attributeType = .UUIDAttributeType
        let orgId = NSAttributeDescription(); orgId.name = "organizationId"; orgId.attributeType = .UUIDAttributeType
        let email = NSAttributeDescription(); email.name = "email"; email.attributeType = .stringAttributeType
        let displayName = NSAttributeDescription(); displayName.name = "displayName"; displayName.attributeType = .stringAttributeType
        let role = NSAttributeDescription(); role.name = "role"; role.attributeType = .stringAttributeType
        let mfa = NSAttributeDescription(); mfa.name = "mfaEnabled"; mfa.attributeType = .booleanAttributeType
        let devId = NSAttributeDescription(); devId.name = "deviceId"; devId.attributeType = .stringAttributeType
        let active = NSAttributeDescription(); active.name = "isActive"; active.attributeType = .booleanAttributeType
        let created = NSAttributeDescription(); created.name = "createdAt"; created.attributeType = .dateAttributeType
        let lastActive = NSAttributeDescription(); lastActive.name = "lastActiveAt"; lastActive.attributeType = .dateAttributeType; lastActive.isOptional = true

        entity.properties = [id, orgId, email, displayName, role, mfa, devId, active, created, lastActive]
        return entity
    }

    func toDomain() -> FFUser {
        let parsedRole = UserRole(rawValue: role)
        if parsedRole == nil {
            print("[FormFlow] CDUser toDomain: unknown role '\(role)' for user \(id), defaulting to .worker")
        }
        return FFUser(
            id: id, organizationId: organizationId, email: email,
            displayName: displayName, role: parsedRole ?? .worker,
            mfaEnabled: mfaEnabled, deviceId: deviceId, isActive: isActive,
            createdAt: createdAt, lastActiveAt: lastActiveAt
        )
    }
}

// MARK: - CDTemplate

class CDTemplate: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var organizationId: UUID
    @NSManaged var name: String
    @NSManaged var status: String
    @NSManaged var version: Int32
    @NSManaged var fieldsJSON: Data?
    @NSManaged var stepsJSON: Data?
    @NSManaged var createdBy: UUID
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
}

extension CDTemplate {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDTemplate"
        entity.managedObjectClassName = NSStringFromClass(CDTemplate.self)

        let id = NSAttributeDescription(); id.name = "id"; id.attributeType = .UUIDAttributeType
        let orgId = NSAttributeDescription(); orgId.name = "organizationId"; orgId.attributeType = .UUIDAttributeType
        let name = NSAttributeDescription(); name.name = "name"; name.attributeType = .stringAttributeType
        let status = NSAttributeDescription(); status.name = "status"; status.attributeType = .stringAttributeType
        let version = NSAttributeDescription(); version.name = "version"; version.attributeType = .integer32AttributeType
        let fieldsJSON = NSAttributeDescription(); fieldsJSON.name = "fieldsJSON"; fieldsJSON.attributeType = .binaryDataAttributeType; fieldsJSON.isOptional = true
        let stepsJSON = NSAttributeDescription(); stepsJSON.name = "stepsJSON"; stepsJSON.attributeType = .binaryDataAttributeType; stepsJSON.isOptional = true
        let createdBy = NSAttributeDescription(); createdBy.name = "createdBy"; createdBy.attributeType = .UUIDAttributeType
        let created = NSAttributeDescription(); created.name = "createdAt"; created.attributeType = .dateAttributeType
        let updated = NSAttributeDescription(); updated.name = "updatedAt"; updated.attributeType = .dateAttributeType

        entity.properties = [id, orgId, name, status, version, fieldsJSON, stepsJSON, createdBy, created, updated]
        return entity
    }

    func toDomain() -> Template? {
        let decoder = JSONDecoder()
        guard let fields = fieldsJSON.flatMap({ try? decoder.decode([TemplateField].self, from: $0) }),
              let steps = stepsJSON.flatMap({ try? decoder.decode([TemplateStep].self, from: $0) }) else {
            return nil
        }
        return Template(
            id: id, organizationId: organizationId, name: name,
            status: TemplateStatus(rawValue: status) ?? .draft,
            version: Int(version), fields: fields, steps: steps,
            createdBy: createdBy, createdAt: createdAt, updatedAt: updatedAt
        )
    }
}

// MARK: - CDWorkflowInstance

class CDWorkflowInstance: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var organizationId: UUID
    @NSManaged var templateId: UUID
    @NSManaged var templateVersion: Int32
    @NSManaged var name: String
    @NSManaged var siteId: UUID?
    @NSManaged var status: String
    @NSManaged var priority: String
    @NSManaged var createdBy: UUID
    @NSManaged var dueDate: Date?
    @NSManaged var createdAt: Date
    @NSManaged var completedAt: Date?
    @NSManaged var pdfUrl: String?
    @NSManaged var pdfHash: String?
}

extension CDWorkflowInstance {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDWorkflowInstance"
        entity.managedObjectClassName = NSStringFromClass(CDWorkflowInstance.self)

        let id = NSAttributeDescription(); id.name = "id"; id.attributeType = .UUIDAttributeType
        let orgId = NSAttributeDescription(); orgId.name = "organizationId"; orgId.attributeType = .UUIDAttributeType
        let templateId = NSAttributeDescription(); templateId.name = "templateId"; templateId.attributeType = .UUIDAttributeType
        let templateVer = NSAttributeDescription(); templateVer.name = "templateVersion"; templateVer.attributeType = .integer32AttributeType
        let name = NSAttributeDescription(); name.name = "name"; name.attributeType = .stringAttributeType
        let siteId = NSAttributeDescription(); siteId.name = "siteId"; siteId.attributeType = .UUIDAttributeType; siteId.isOptional = true
        let status = NSAttributeDescription(); status.name = "status"; status.attributeType = .stringAttributeType
        let priority = NSAttributeDescription(); priority.name = "priority"; priority.attributeType = .stringAttributeType
        let createdBy = NSAttributeDescription(); createdBy.name = "createdBy"; createdBy.attributeType = .UUIDAttributeType
        let dueDate = NSAttributeDescription(); dueDate.name = "dueDate"; dueDate.attributeType = .dateAttributeType; dueDate.isOptional = true
        let created = NSAttributeDescription(); created.name = "createdAt"; created.attributeType = .dateAttributeType
        let completed = NSAttributeDescription(); completed.name = "completedAt"; completed.attributeType = .dateAttributeType; completed.isOptional = true
        let pdfUrl = NSAttributeDescription(); pdfUrl.name = "pdfUrl"; pdfUrl.attributeType = .stringAttributeType; pdfUrl.isOptional = true
        let pdfHash = NSAttributeDescription(); pdfHash.name = "pdfHash"; pdfHash.attributeType = .stringAttributeType; pdfHash.isOptional = true

        entity.properties = [id, orgId, templateId, templateVer, name, siteId, status, priority, createdBy, dueDate, created, completed, pdfUrl, pdfHash]
        return entity
    }

    func toDomain() -> WorkflowInstance {
        let parsedStatus = WorkflowStatus(rawValue: status)
        let parsedPriority = WorkflowPriority(rawValue: priority)
        if parsedStatus == nil {
            print("[FormFlow] CDWorkflowInstance toDomain: unknown status '\(status)' for workflow \(id), defaulting to .draft")
        }
        if parsedPriority == nil {
            print("[FormFlow] CDWorkflowInstance toDomain: unknown priority '\(priority)' for workflow \(id), defaulting to .standard")
        }
        return WorkflowInstance(
            id: id, organizationId: organizationId, templateId: templateId,
            templateVersion: Int(templateVersion), name: name, siteId: siteId,
            status: parsedStatus ?? .draft,
            priority: parsedPriority ?? .standard,
            createdBy: createdBy, dueDate: dueDate, createdAt: createdAt,
            completedAt: completedAt, pdfUrl: pdfUrl, pdfHash: pdfHash
        )
    }
}

// MARK: - CDStepAssignment

class CDStepAssignment: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var workflowId: UUID
    @NSManaged var stepNumber: Int32
    @NSManaged var stepName: String
    @NSManaged var assignedTo: UUID
    @NSManaged var assignedBy: UUID
    @NSManaged var status: String
    @NSManaged var dueDate: Date?
    @NSManaged var assignedAt: Date
    @NSManaged var completedAt: Date?
    @NSManaged var isLocked: Bool
    @NSManaged var lockedAt: Date?
}

extension CDStepAssignment {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDStepAssignment"
        entity.managedObjectClassName = NSStringFromClass(CDStepAssignment.self)

        let id = NSAttributeDescription(); id.name = "id"; id.attributeType = .UUIDAttributeType
        let wfId = NSAttributeDescription(); wfId.name = "workflowId"; wfId.attributeType = .UUIDAttributeType
        let stepNum = NSAttributeDescription(); stepNum.name = "stepNumber"; stepNum.attributeType = .integer32AttributeType
        let stepName = NSAttributeDescription(); stepName.name = "stepName"; stepName.attributeType = .stringAttributeType
        let assignedTo = NSAttributeDescription(); assignedTo.name = "assignedTo"; assignedTo.attributeType = .UUIDAttributeType
        let assignedBy = NSAttributeDescription(); assignedBy.name = "assignedBy"; assignedBy.attributeType = .UUIDAttributeType
        let status = NSAttributeDescription(); status.name = "status"; status.attributeType = .stringAttributeType
        let dueDate = NSAttributeDescription(); dueDate.name = "dueDate"; dueDate.attributeType = .dateAttributeType; dueDate.isOptional = true
        let assignedAt = NSAttributeDescription(); assignedAt.name = "assignedAt"; assignedAt.attributeType = .dateAttributeType
        let completedAt = NSAttributeDescription(); completedAt.name = "completedAt"; completedAt.attributeType = .dateAttributeType; completedAt.isOptional = true
        let locked = NSAttributeDescription(); locked.name = "isLocked"; locked.attributeType = .booleanAttributeType
        let lockedAt = NSAttributeDescription(); lockedAt.name = "lockedAt"; lockedAt.attributeType = .dateAttributeType; lockedAt.isOptional = true

        entity.properties = [id, wfId, stepNum, stepName, assignedTo, assignedBy, status, dueDate, assignedAt, completedAt, locked, lockedAt]
        return entity
    }

    func toDomain() -> StepAssignment {
        let parsedStatus = StepStatus(rawValue: status)
        if parsedStatus == nil {
            print("[FormFlow] CDStepAssignment toDomain: unknown status '\(status)' for step \(id), defaulting to .locked")
        }
        return StepAssignment(
            id: id, workflowId: workflowId, stepNumber: Int(stepNumber),
            stepName: stepName, assignedTo: assignedTo, assignedBy: assignedBy,
            status: parsedStatus ?? .locked,
            dueDate: dueDate, assignedAt: assignedAt, completedAt: completedAt,
            isLocked: isLocked, lockedAt: lockedAt
        )
    }
}

// MARK: - CDFormResponse

class CDFormResponse: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var workflowId: UUID
    @NSManaged var stepNumber: Int32
    @NSManaged var fieldId: UUID
    @NSManaged var fieldLabel: String
    @NSManaged var value: String
    @NSManaged var respondedBy: UUID
    @NSManaged var deviceId: String
    @NSManaged var timestamp: Date
    @NSManaged var synced: Bool
    @NSManaged var syncAttemptedAt: Date?
}

extension CDFormResponse {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDFormResponse"
        entity.managedObjectClassName = NSStringFromClass(CDFormResponse.self)

        let id = NSAttributeDescription(); id.name = "id"; id.attributeType = .UUIDAttributeType
        let wfId = NSAttributeDescription(); wfId.name = "workflowId"; wfId.attributeType = .UUIDAttributeType
        let stepNum = NSAttributeDescription(); stepNum.name = "stepNumber"; stepNum.attributeType = .integer32AttributeType
        let fieldId = NSAttributeDescription(); fieldId.name = "fieldId"; fieldId.attributeType = .UUIDAttributeType
        let fieldLabel = NSAttributeDescription(); fieldLabel.name = "fieldLabel"; fieldLabel.attributeType = .stringAttributeType
        let value = NSAttributeDescription(); value.name = "value"; value.attributeType = .stringAttributeType
        let respondedBy = NSAttributeDescription(); respondedBy.name = "respondedBy"; respondedBy.attributeType = .UUIDAttributeType
        let devId = NSAttributeDescription(); devId.name = "deviceId"; devId.attributeType = .stringAttributeType
        let timestamp = NSAttributeDescription(); timestamp.name = "timestamp"; timestamp.attributeType = .dateAttributeType
        let synced = NSAttributeDescription(); synced.name = "synced"; synced.attributeType = .booleanAttributeType
        let syncAt = NSAttributeDescription(); syncAt.name = "syncAttemptedAt"; syncAt.attributeType = .dateAttributeType; syncAt.isOptional = true

        entity.properties = [id, wfId, stepNum, fieldId, fieldLabel, value, respondedBy, devId, timestamp, synced, syncAt]
        return entity
    }
}

// MARK: - CDSignatureRecord

class CDSignatureRecord: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var workflowId: UUID
    @NSManaged var stepNumber: Int32
    @NSManaged var signerId: UUID
    @NSManaged var signerName: String
    @NSManaged var signerRole: String
    @NSManaged var signatureImageData: Data
    @NSManaged var attestationText: String
    @NSManaged var deviceId: String
    @NSManaged var timestamp: Date
    @NSManaged var ipAddress: String?
    @NSManaged var mfaVerified: Bool
    @NSManaged var contentHash: String
    @NSManaged var synced: Bool
}

extension CDSignatureRecord {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDSignatureRecord"
        entity.managedObjectClassName = NSStringFromClass(CDSignatureRecord.self)

        let id = NSAttributeDescription(); id.name = "id"; id.attributeType = .UUIDAttributeType
        let wfId = NSAttributeDescription(); wfId.name = "workflowId"; wfId.attributeType = .UUIDAttributeType
        let stepNum = NSAttributeDescription(); stepNum.name = "stepNumber"; stepNum.attributeType = .integer32AttributeType
        let signerId = NSAttributeDescription(); signerId.name = "signerId"; signerId.attributeType = .UUIDAttributeType
        let signerName = NSAttributeDescription(); signerName.name = "signerName"; signerName.attributeType = .stringAttributeType
        let signerRole = NSAttributeDescription(); signerRole.name = "signerRole"; signerRole.attributeType = .stringAttributeType
        let sigData = NSAttributeDescription(); sigData.name = "signatureImageData"; sigData.attributeType = .binaryDataAttributeType; sigData.allowsExternalBinaryDataStorage = true
        let attest = NSAttributeDescription(); attest.name = "attestationText"; attest.attributeType = .stringAttributeType
        let devId = NSAttributeDescription(); devId.name = "deviceId"; devId.attributeType = .stringAttributeType
        let timestamp = NSAttributeDescription(); timestamp.name = "timestamp"; timestamp.attributeType = .dateAttributeType
        let ip = NSAttributeDescription(); ip.name = "ipAddress"; ip.attributeType = .stringAttributeType; ip.isOptional = true
        let mfa = NSAttributeDescription(); mfa.name = "mfaVerified"; mfa.attributeType = .booleanAttributeType
        let hash = NSAttributeDescription(); hash.name = "contentHash"; hash.attributeType = .stringAttributeType
        let synced = NSAttributeDescription(); synced.name = "synced"; synced.attributeType = .booleanAttributeType

        entity.properties = [id, wfId, stepNum, signerId, signerName, signerRole, sigData, attest, devId, timestamp, ip, mfa, hash, synced]
        return entity
    }
}

// MARK: - CDSyncOperation

class CDSyncOperation: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var type: String
    @NSManaged var entityType: String
    @NSManaged var entityId: UUID
    @NSManaged var fieldId: UUID?
    @NSManaged var value: String?
    @NSManaged var timestamp: Date
    @NSManaged var deviceId: String
    @NSManaged var synced: Bool
    @NSManaged var syncAttemptedAt: Date?
    @NSManaged var errorMessage: String?
}

extension CDSyncOperation {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDSyncOperation"
        entity.managedObjectClassName = NSStringFromClass(CDSyncOperation.self)

        let id = NSAttributeDescription(); id.name = "id"; id.attributeType = .UUIDAttributeType
        let type = NSAttributeDescription(); type.name = "type"; type.attributeType = .stringAttributeType
        let entityType = NSAttributeDescription(); entityType.name = "entityType"; entityType.attributeType = .stringAttributeType
        let entityId = NSAttributeDescription(); entityId.name = "entityId"; entityId.attributeType = .UUIDAttributeType
        let fieldId = NSAttributeDescription(); fieldId.name = "fieldId"; fieldId.attributeType = .UUIDAttributeType; fieldId.isOptional = true
        let value = NSAttributeDescription(); value.name = "value"; value.attributeType = .stringAttributeType; value.isOptional = true
        let timestamp = NSAttributeDescription(); timestamp.name = "timestamp"; timestamp.attributeType = .dateAttributeType
        let devId = NSAttributeDescription(); devId.name = "deviceId"; devId.attributeType = .stringAttributeType
        let synced = NSAttributeDescription(); synced.name = "synced"; synced.attributeType = .booleanAttributeType
        let syncAt = NSAttributeDescription(); syncAt.name = "syncAttemptedAt"; syncAt.attributeType = .dateAttributeType; syncAt.isOptional = true
        let error = NSAttributeDescription(); error.name = "errorMessage"; error.attributeType = .stringAttributeType; error.isOptional = true

        entity.properties = [id, type, entityType, entityId, fieldId, value, timestamp, devId, synced, syncAt, error]
        return entity
    }
}

// MARK: - CDAuditLogEntry

class CDAuditLogEntry: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var workflowId: UUID
    @NSManaged var stepNumber: Int32
    @NSManaged var actorId: UUID
    @NSManaged var actorName: String
    @NSManaged var actorRole: String
    @NSManaged var action: String
    @NSManaged var entityType: String
    @NSManaged var entityId: UUID
    @NSManaged var metadata: String
    @NSManaged var timestamp: Date
    @NSManaged var deviceId: String
}

extension CDAuditLogEntry {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CDAuditLogEntry"
        entity.managedObjectClassName = NSStringFromClass(CDAuditLogEntry.self)

        let id = NSAttributeDescription(); id.name = "id"; id.attributeType = .UUIDAttributeType
        let wfId = NSAttributeDescription(); wfId.name = "workflowId"; wfId.attributeType = .UUIDAttributeType
        let stepNum = NSAttributeDescription(); stepNum.name = "stepNumber"; stepNum.attributeType = .integer32AttributeType
        let actorId = NSAttributeDescription(); actorId.name = "actorId"; actorId.attributeType = .UUIDAttributeType
        let actorName = NSAttributeDescription(); actorName.name = "actorName"; actorName.attributeType = .stringAttributeType
        let actorRole = NSAttributeDescription(); actorRole.name = "actorRole"; actorRole.attributeType = .stringAttributeType
        let action = NSAttributeDescription(); action.name = "action"; action.attributeType = .stringAttributeType
        let entityType = NSAttributeDescription(); entityType.name = "entityType"; entityType.attributeType = .stringAttributeType
        let entityIdAttr = NSAttributeDescription(); entityIdAttr.name = "entityId"; entityIdAttr.attributeType = .UUIDAttributeType
        let metadata = NSAttributeDescription(); metadata.name = "metadata"; metadata.attributeType = .stringAttributeType
        let timestamp = NSAttributeDescription(); timestamp.name = "timestamp"; timestamp.attributeType = .dateAttributeType
        let devId = NSAttributeDescription(); devId.name = "deviceId"; devId.attributeType = .stringAttributeType

        entity.properties = [id, wfId, stepNum, actorId, actorName, actorRole, action, entityType, entityIdAttr, metadata, timestamp, devId]
        return entity
    }
}

// MARK: - Programmatic Model

extension PersistenceController {
    static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.entities = [
            CDOrganization.entityDescription(),
            CDUser.entityDescription(),
            CDTemplate.entityDescription(),
            CDWorkflowInstance.entityDescription(),
            CDStepAssignment.entityDescription(),
            CDFormResponse.entityDescription(),
            CDSignatureRecord.entityDescription(),
            CDSyncOperation.entityDescription(),
            CDAuditLogEntry.entityDescription(),
        ]
        return model
    }
}
