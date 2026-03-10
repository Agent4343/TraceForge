import XCTest
@testable import FormFlow

final class APIClientTests: XCTestCase {

    // MARK: - APIError Tests

    func testAPIErrorDescriptions() {
        XCTAssertNotNil(APIError.unauthorized.errorDescription)
        XCTAssertNotNil(APIError.forbidden.errorDescription)
        XCTAssertNotNil(APIError.notFound.errorDescription)
        XCTAssertNotNil(APIError.tooManyRequests.errorDescription)
        XCTAssertNotNil(APIError.serverError(500).errorDescription)
        XCTAssertNotNil(APIError.invalidResponse.errorDescription)
        XCTAssertNotNil(APIError.timeout.errorDescription)

        // Error messages should be user-friendly
        XCTAssertTrue(APIError.unauthorized.errorDescription!.contains("session"))
        XCTAssertTrue(APIError.forbidden.errorDescription!.contains("permission"))
        XCTAssertTrue(APIError.tooManyRequests.errorDescription!.contains("wait"))
        XCTAssertTrue(APIError.serverError(500).errorDescription!.contains("saved locally"))
    }

    // MARK: - HTTPMethod Tests

    func testHTTPMethodRawValues() {
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.put.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.patch.rawValue, "PATCH")
        XCTAssertEqual(HTTPMethod.delete.rawValue, "DELETE")
    }

    // MARK: - Token Response Tests

    func testTokenResponseDecoding() throws {
        let json = """
        {
            "access_token": "jwt-access-123",
            "refresh_token": "jwt-refresh-456"
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)

        XCTAssertEqual(response.accessToken, "jwt-access-123")
        XCTAssertEqual(response.refreshToken, "jwt-refresh-456")
    }

    // MARK: - AnyEncodable Tests

    func testAnyEncodable() throws {
        let dict = ["key": "value"]
        let wrapped = AnyEncodable(dict)
        let data = try JSONEncoder().encode(wrapped)
        let decoded = try JSONDecoder().decode([String: String].self, from: data)

        XCTAssertEqual(decoded["key"], "value")
    }
}
