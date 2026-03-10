import Foundation

// MARK: - User Service

class UserService {
    static let shared = UserService()

    func listUsers(role: String? = nil) async throws -> [FFUser] {
        var endpoint = "users"
        if let role = role {
            endpoint += "?role=\(role)"
        }
        return try await APIClient.shared.request(endpoint: endpoint)
    }

    func inviteUsers(_ request: InviteUsersRequest) async throws -> InviteResponse {
        return try await APIClient.shared.request(
            endpoint: "users/invite",
            method: .post,
            body: request
        )
    }

    func updateUserRole(userId: UUID, role: String) async throws -> FFUser {
        return try await APIClient.shared.request(
            endpoint: "users/\(userId.uuidString)",
            method: .patch,
            body: ["role": role]
        )
    }

    func deactivateUser(userId: UUID) async throws -> FFUser {
        return try await APIClient.shared.request(
            endpoint: "users/\(userId.uuidString)",
            method: .patch,
            body: ["is_active": false]
        )
    }

    func reactivateUser(userId: UUID) async throws -> FFUser {
        return try await APIClient.shared.request(
            endpoint: "users/\(userId.uuidString)",
            method: .patch,
            body: ["is_active": true]
        )
    }

    func updateDeviceToken(_ token: String) async throws {
        let _: EmptyResponse = try await APIClient.shared.request(
            endpoint: "users/me/device-token",
            method: .patch,
            body: ["device_token": token]
        )
    }

    func resetMFA(userId: UUID) async throws {
        let _: EmptyResponse = try await APIClient.shared.request(
            endpoint: "users/\(userId.uuidString)/mfa/reset",
            method: .post
        )
    }
}

// MARK: - Request/Response Types

struct InviteUsersRequest: Encodable {
    let invites: [InviteEntry]
    let customMessage: String?

    enum CodingKeys: String, CodingKey {
        case invites
        case customMessage = "custom_message"
    }
}

struct InviteEntry: Encodable {
    let email: String
    let role: String
}

struct InviteResponse: Decodable {
    let sent: Int
    let failed: [String]?
}
