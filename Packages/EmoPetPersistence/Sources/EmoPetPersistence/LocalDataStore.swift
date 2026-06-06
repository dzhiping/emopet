import Foundation
import EmoPetKit
import EmoPetCore
import EmoPetPersonality

/// 本地数据持久化 + 导出/导入备份
public struct EmoPetBackup: Codable, Sendable {
    public let version: Int
    public let exportedAt: Date
    public var session: UserSession

    public init(version: Int = 2, exportedAt: Date = Date(), session: UserSession) {
        self.version = version
        self.exportedAt = exportedAt
        self.session = session
    }
}

public struct NotificationBackupState: Codable, Sendable {
    public var lastSentIndices: [String: Int]
}

public enum PersistenceError: Error, Sendable {
    case encodingFailed
    case decodingFailed
    case fileNotFound
}

public struct LocalDataStore: Sendable {
    private let fileManager: FileManager
    private let directoryURL: URL

    public init(directoryURL: URL, fileManager: FileManager = .default) {
        self.directoryURL = directoryURL
        self.fileManager = fileManager
    }

    public static func defaultStore() throws -> LocalDataStore {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("EmoPet", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return LocalDataStore(directoryURL: base)
    }

    private var sessionURL: URL { directoryURL.appendingPathComponent("user_session.json") }

    public func save(session: UserSession) throws {
        try JSONEncoder.emopet.encode(session).write(to: sessionURL, options: .atomic)
    }

    public func loadSession() throws -> UserSession {
        guard fileManager.fileExists(atPath: sessionURL.path) else {
            throw PersistenceError.fileNotFound
        }
        return try JSONDecoder.emopet.decode(UserSession.self, from: Data(contentsOf: sessionURL))
    }

    public func hasSession() -> Bool {
        fileManager.fileExists(atPath: sessionURL.path)
    }

    public func exportBackup(session: UserSession) throws -> Data {
        try JSONEncoder.emopet.encode(EmoPetBackup(session: session))
    }

    public func importBackup(from data: Data) throws -> EmoPetBackup {
        try JSONDecoder.emopet.decode(EmoPetBackup.self, from: data)
    }

    public func exportToFile(session: UserSession, url: URL) throws {
        let data = try exportBackup(session: session)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Legacy migration helpers

    public func migrateLegacyIfNeeded(into session: inout UserSession) {
        let legacyPetURL = directoryURL.appendingPathComponent("pet_snapshot.json")
        guard session.pets.isEmpty, fileManager.fileExists(atPath: legacyPetURL.path) else { return }
        if let data = try? Data(contentsOf: legacyPetURL),
           let snapshot = try? JSONDecoder.emopet.decode(PetSnapshot.self, from: data) {
            let profile = PetAdoptionProfile(
                petName: snapshot.speciesID == .cat ? "咪咪" : "旺财",
                speciesID: snapshot.speciesID,
                gender: .neutral,
                expectedPersonality: .gentle,
                language: .chinese
            )
            session.pets.append(OwnedPet(adoption: profile, snapshot: snapshot))
            session.activePetID = session.pets.first?.id
        }
    }
}

extension PersonalityProfile {
    public var asData: PersonalityProfileData {
        PersonalityProfileData(
            consistency: consistency, affection: affection,
            responsiveness: responsiveness, playfulness: playfulness,
            discipline: discipline
        )
    }

    public init(from data: PersonalityProfileData) {
        self.init(
            consistency: data.consistency, affection: data.affection,
            responsiveness: data.responsiveness, playfulness: data.playfulness,
            discipline: data.discipline
        )
    }
}

extension JSONEncoder {
    static let emopet: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
}

extension JSONDecoder {
    static let emopet: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
