import Foundation

// MARK: - API Client

actor APIClient {
    static let shared = APIClient()

    private var baseURL: URL
    private var accessToken: String?
    private var refreshToken: String?
    private let session: URLSession
    private let maxRetries = 3

    private init() {
        self.baseURL = URL(string: "https://api.formflow.io/api/v1")!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    func configure(baseURL: String) {
        if let url = URL(string: baseURL) {
            self.baseURL = url
        }
    }

    func setTokens(access: String, refresh: String) {
        self.accessToken = access
        self.refreshToken = refresh
    }

    func clearTokens() {
        self.accessToken = nil
        self.refreshToken = nil
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        retryCount: Int = 0
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            case 401:
                if retryCount == 0, let _ = refreshToken {
                    // Attempt token refresh
                    try await refreshAccessToken()
                    return try await self.request(endpoint: endpoint, method: method, body: body, retryCount: retryCount + 1)
                }
                throw APIError.unauthorized
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.notFound
            case 429:
                throw APIError.tooManyRequests
            case 500...599:
                throw APIError.serverError(httpResponse.statusCode)
            default:
                throw APIError.unexpected(httpResponse.statusCode)
            }
        } catch let error as APIError {
            throw error
        } catch {
            if retryCount < maxRetries {
                let delay = pow(2.0, Double(retryCount))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await self.request(endpoint: endpoint, method: method, body: body, retryCount: retryCount + 1)
            }
            throw APIError.networkError(error)
        }
    }

    private func refreshAccessToken() async throws {
        guard let refresh = refreshToken else { throw APIError.unauthorized }
        let url = baseURL.appendingPathComponent("auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["refresh_token": refresh])

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.unauthorized
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        self.accessToken = tokenResponse.accessToken
        self.refreshToken = tokenResponse.refreshToken
    }
}

// MARK: - Types

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case tooManyRequests
    case serverError(Int)
    case unexpected(Int)
    case networkError(Error)
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server."
        case .unauthorized: return "Your session has expired. Please sign in again."
        case .forbidden: return "You don't have permission to perform this action."
        case .notFound: return "This item may have been deleted or you don't have access."
        case .tooManyRequests: return "Too many requests. Please wait a moment."
        case .serverError: return "Something went wrong on our end. Your changes have been saved locally and will sync when resolved."
        case .unexpected(let code): return "Unexpected error (HTTP \(code))."
        case .networkError: return "The request is taking longer than expected. You can continue working offline."
        case .timeout: return "The request timed out. You can continue working offline."
        }
    }
}

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

// MARK: - AnyEncodable Helper

struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ value: Encodable) {
        self.encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
