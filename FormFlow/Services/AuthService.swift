import Foundation

// MARK: - Auth Service

class AuthService {
    static let shared = AuthService()

    struct LoginRequest: Encodable {
        let email: String
        let password: String
        let deviceId: String
    }

    struct LoginResponse: Decodable {
        let user: FFUser
        let accessToken: String
        let refreshToken: String
        let requiresMFA: Bool

        enum CodingKeys: String, CodingKey {
            case user
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case requiresMFA = "requires_mfa"
        }
    }

    struct MFARequest: Encodable {
        let code: String
        let sessionToken: String

        enum CodingKeys: String, CodingKey {
            case code
            case sessionToken = "session_token"
        }
    }

    func login(email: String, password: String, deviceId: String) async throws -> LoginResponse {
        let body = LoginRequest(email: email, password: password, deviceId: deviceId)
        return try await APIClient.shared.request(
            endpoint: "auth/login",
            method: .post,
            body: body
        )
    }

    func verifyMFA(code: String, sessionToken: String) async throws -> LoginResponse {
        let body = MFARequest(code: code, sessionToken: sessionToken)
        return try await APIClient.shared.request(
            endpoint: "auth/mfa/verify",
            method: .post,
            body: body
        )
    }

    func logout() async throws {
        let _: EmptyResponse = try await APIClient.shared.request(
            endpoint: "auth/logout",
            method: .post
        )
        await APIClient.shared.clearTokens()
    }

    func requestPasswordReset(email: String) async throws {
        let _: EmptyResponse = try await APIClient.shared.request(
            endpoint: "auth/forgot-password",
            method: .post,
            body: ["email": email]
        )
    }
}

struct EmptyResponse: Decodable {}
