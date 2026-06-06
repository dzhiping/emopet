import Foundation
import Security

/// 本地 Keychain 保存登录凭据（仅本机、设备解锁后可读）
public struct KeychainCredentialStore: Sendable {
    private let service = "com.emopet.app.login"
    private let accountKey = "primary"

    public init() {}

    public func save(displayName: String, password: String) throws {
        let payload = StoredCredential(displayName: displayName, password: password)
        let data = try JSONEncoder().encode(payload)
        delete()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.operationFailed(status)
        }
    }

    public func load() -> StoredCredential? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(StoredCredential.self, from: data)
    }

    public func clear() {
        delete()
    }

    private func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountKey,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

public struct StoredCredential: Codable, Sendable {
    public let displayName: String
    public let password: String
}

public enum KeychainError: Error, Sendable {
    case operationFailed(OSStatus)
}
