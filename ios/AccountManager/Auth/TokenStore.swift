import Foundation
import Security

protocol TokenStore: Sendable {
    func save(_ tokens: TokenPair) throws
    func load() throws -> TokenPair?
    func clear() throws
}

struct KeychainError: Error {
    let status: OSStatus
}

/// Keeps the session in the iOS Keychain, readable only on this device after first unlock.
final class KeychainTokenStore: TokenStore {
    private let service = "com.arunk.accountmanager.session"
    private let account = "tokens"

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    func save(_ tokens: TokenPair) throws {
        try clear()
        var query = baseQuery
        query[kSecValueData as String] = try JSONEncoder().encode(tokens)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    func load() throws -> TokenPair? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else { throw KeychainError(status: status) }
        return try JSONDecoder().decode(TokenPair.self, from: data)
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status: status) }
    }
}
