import CryptoKit
import Foundation
import EmoPetKit

public struct AuthService: Sendable {
    public init() {}

    public func register(displayName: String, password: String) throws -> UserAccount {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, password.count >= 4 else {
            throw AuthError.invalidInput
        }
        let salt = randomSalt()
        return UserAccount(
            displayName: trimmed,
            passwordSalt: salt,
            passwordHash: hash(password: password, salt: salt)
        )
    }

    public func verify(password: String, account: UserAccount) -> Bool {
        hash(password: password, salt: account.passwordSalt) == account.passwordHash
    }

    private func hash(password: String, salt: String) -> String {
        let input = Data((salt + password).utf8)
        let digest = SHA256.hash(data: input)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func randomSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }
}

public enum AuthError: Error, Sendable {
    case invalidInput
    case wrongPassword
}
