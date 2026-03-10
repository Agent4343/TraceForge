import XCTest
@testable import FormFlow

final class KeychainServiceTests: XCTestCase {
    let keychain = KeychainService.shared

    override func tearDown() {
        super.tearDown()
        keychain.clearAll()
    }

    func testSaveAndReadToken() {
        let token = "test-jwt-token-12345"

        let saved = keychain.save(key: .accessToken, value: token)
        XCTAssertTrue(saved, "Save should succeed")

        let retrieved = keychain.read(key: .accessToken)
        XCTAssertEqual(retrieved, token)
    }

    func testSaveTokensAndRetrieve() {
        let access = "access-token-abc"
        let refresh = "refresh-token-xyz"

        keychain.saveTokens(access: access, refresh: refresh)

        XCTAssertEqual(keychain.getAccessToken(), access)
        XCTAssertEqual(keychain.getRefreshToken(), refresh)
    }

    func testDeleteToken() {
        keychain.save(key: .accessToken, value: "token")
        let deleted = keychain.delete(key: .accessToken)

        XCTAssertTrue(deleted)
        XCTAssertNil(keychain.read(key: .accessToken))
    }

    func testClearAll() {
        keychain.save(key: .accessToken, value: "access")
        keychain.save(key: .refreshToken, value: "refresh")

        keychain.clearAll()

        XCTAssertNil(keychain.getAccessToken())
        XCTAssertNil(keychain.getRefreshToken())
    }

    func testGetOrCreateDeviceId() {
        keychain.delete(key: .deviceId)

        let deviceId1 = keychain.getOrCreateDeviceId()
        XCTAssertFalse(deviceId1.isEmpty)
        XCTAssertTrue(deviceId1.hasPrefix("DEV-"))

        // Same device ID returned on second call
        let deviceId2 = keychain.getOrCreateDeviceId()
        XCTAssertEqual(deviceId1, deviceId2)
    }

    func testOverwriteExistingValue() {
        keychain.save(key: .accessToken, value: "old-token")
        keychain.save(key: .accessToken, value: "new-token")

        XCTAssertEqual(keychain.read(key: .accessToken), "new-token")
    }

    func testReadNonexistentKey() {
        keychain.delete(key: .accessToken)
        XCTAssertNil(keychain.read(key: .accessToken))
    }
}
