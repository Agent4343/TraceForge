import Foundation

// MARK: - Template Service

class TemplateService {
    static let shared = TemplateService()

    func listTemplates(status: String? = nil, page: Int = 1, perPage: Int = 25) async throws -> [Template] {
        var endpoint = "templates?page=\(page)&per_page=\(perPage)"
        if let status = status {
            endpoint += "&status=\(status)"
        }
        return try await APIClient.shared.request(endpoint: endpoint)
    }

    func createTemplate(_ request: CreateTemplateRequest) async throws -> Template {
        return try await APIClient.shared.request(
            endpoint: "templates",
            method: .post,
            body: request
        )
    }

    func updateTemplate(id: UUID, request: UpdateTemplateRequest) async throws -> Template {
        return try await APIClient.shared.request(
            endpoint: "templates/\(id.uuidString)",
            method: .put,
            body: request
        )
    }

    func duplicateTemplate(id: UUID) async throws -> Template {
        return try await APIClient.shared.request(
            endpoint: "templates/\(id.uuidString)/duplicate",
            method: .post
        )
    }

    func archiveTemplate(id: UUID) async throws -> Template {
        return try await APIClient.shared.request(
            endpoint: "templates/\(id.uuidString)",
            method: .put,
            body: ["status": "archived"]
        )
    }
}

// MARK: - Request Types

struct CreateTemplateRequest: Encodable {
    let name: String
    let fields: [TemplateField]
    let steps: [TemplateStep]
}

struct UpdateTemplateRequest: Encodable {
    let name: String
    let fields: [TemplateField]
    let steps: [TemplateStep]
    let status: String?
}
