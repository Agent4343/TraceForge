import Foundation
import Security

// MARK: - Keychain Service
// Thread-safe: Keychain APIs (SecItem*) are thread-safe per Apple docs

final class KeychainService: Sendable {
    static let shared = KeychainService()

    private let serviceName = "com.formflow.app"

    // MARK: - Keys

    enum Key: String {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case deviceId = "device_id"
    }

    // MARK: - Save

    @discardableResult
    func save(key: Key, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(key: key.rawValue, data: data)
    }

    @discardableResult
    func save(key: String, data: Data) -> Bool {
        // Delete existing item first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Read

    func read(key: Key) -> String? {
        guard let data = readData(key: key.rawValue) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func readData(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    // MARK: - Delete

    @discardableResult
    func delete(key: Key) -> Bool {
        return delete(key: key.rawValue)
    }

    @discardableResult
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Clear All

    func clearAll() {
        for key in [Key.accessToken, .refreshToken, .deviceId] {
            delete(key: key)
        }
    }

    // MARK: - Token Management

    func saveTokens(access: String, refresh: String) {
        save(key: .accessToken, value: access)
        save(key: .refreshToken, value: refresh)
    }

    func getAccessToken() -> String? {
        read(key: .accessToken)
    }

    func getRefreshToken() -> String? {
        read(key: .refreshToken)
    }

    // MARK: - Device ID

    func getOrCreateDeviceId() -> String {
        if let existing = read(key: .deviceId) {
            return existing
        }
        let newId = "DEV-\(UUID().uuidString.prefix(8).uppercased())"
        save(key: .deviceId, value: newId)
        return newId
    }
}
