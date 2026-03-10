import Foundation

// MARK: - Workflow Service

class WorkflowService {
    static let shared = WorkflowService()

    // MARK: - Workflows

    func listWorkflows(status: String? = nil, page: Int = 1, perPage: Int = 25) async throws -> [WorkflowInstance] {
        var endpoint = "workflows?page=\(page)&per_page=\(perPage)"
        if let status = status {
            endpoint += "&status=\(status)"
        }
        return try await APIClient.shared.request(endpoint: endpoint)
    }

    func getWorkflow(id: UUID) async throws -> WorkflowInstance {
        return try await APIClient.shared.request(endpoint: "workflows/\(id.uuidString)")
    }

    func createWorkflow(_ request: CreateWorkflowRequest) async throws -> WorkflowInstance {
        return try await APIClient.shared.request(
            endpoint: "workflows",
            method: .post,
            body: request
        )
    }

    func updateStepStatus(workflowId: UUID, stepNumber: Int, status: String) async throws -> StepAssignment {
        return try await APIClient.shared.request(
            endpoint: "workflows/\(workflowId.uuidString)/steps/\(stepNumber)",
            method: .patch,
            body: ["status": status]
        )
    }

    func submitResponses(workflowId: UUID, stepNumber: Int, responses: [SubmitResponseRequest]) async throws -> [FormResponse] {
        return try await APIClient.shared.request(
            endpoint: "workflows/\(workflowId.uuidString)/steps/\(stepNumber)/responses",
            method: .post,
            body: responses
        )
    }

    func submitSignature(workflowId: UUID, stepNumber: Int, signature: SubmitSignatureRequest) async throws -> SignatureRecord {
        return try await APIClient.shared.request(
            endpoint: "workflows/\(workflowId.uuidString)/steps/\(stepNumber)/sign",
            method: .post,
            body: signature
        )
    }

    func initiateHandover(workflowId: UUID, request: HandoverAPIRequest) async throws -> StepAssignment {
        return try await APIClient.shared.request(
            endpoint: "workflows/\(workflowId.uuidString)/handover",
            method: .post,
            body: request
        )
    }

    func getAuditTrail(workflowId: UUID) async throws -> [AuditLogEntry] {
        return try await APIClient.shared.request(endpoint: "workflows/\(workflowId.uuidString)/audit")
    }

    func requestPDFExport(workflowId: UUID) async throws -> PDFExportResponse {
        return try await APIClient.shared.request(
            endpoint: "workflows/\(workflowId.uuidString)/export/pdf",
            method: .post
        )
    }

    func getMyTasks() async throws -> [StepAssignment] {
        return try await APIClient.shared.request(endpoint: "tasks/mine")
    }
}

// MARK: - Request/Response Types

struct CreateWorkflowRequest: Encodable {
    let templateId: UUID
    let name: String
    let siteId: UUID?
    let dueDate: Date?
    let priority: String
    let stepAssignments: [StepAssignmentRequest]

    enum CodingKeys: String, CodingKey {
        case templateId = "template_id"
        case name
        case siteId = "site_id"
        case dueDate = "due_date"
        case priority
        case stepAssignments = "step_assignments"
    }
}

struct StepAssignmentRequest: Encodable {
    let stepNumber: Int
    let assignedTo: UUID
    let dueDate: Date?

    enum CodingKeys: String, CodingKey {
        case stepNumber = "step_number"
        case assignedTo = "assigned_to"
        case dueDate = "due_date"
    }
}

struct SubmitResponseRequest: Encodable {
    let fieldId: UUID
    let value: String
    let timestamp: Date
    let deviceId: String

    enum CodingKeys: String, CodingKey {
        case fieldId = "field_id"
        case value, timestamp
        case deviceId = "device_id"
    }
}

struct SubmitSignatureRequest: Encodable {
    let signatureImageBase64: String
    let attestationText: String
    let timestamp: Date
    let deviceId: String
    let contentHash: String
    let mfaVerified: Bool

    enum CodingKeys: String, CodingKey {
        case signatureImageBase64 = "signature_image_base64"
        case attestationText = "attestation_text"
        case timestamp
        case deviceId = "device_id"
        case contentHash = "content_hash"
        case mfaVerified = "mfa_verified"
    }
}

struct HandoverAPIRequest: Encodable {
    let stepNumber: Int
    let toUserId: UUID
    let note: String
    let contextPhotoBase64: String?

    enum CodingKeys: String, CodingKey {
        case stepNumber = "step_number"
        case toUserId = "to_user_id"
        case note
        case contextPhotoBase64 = "context_photo_base64"
    }
}

struct PDFExportResponse: Decodable {
    let pdfUrl: String
    let pdfHash: String
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case pdfUrl = "pdf_url"
        case pdfHash = "pdf_hash"
        case generatedAt = "generated_at"
    }
}
