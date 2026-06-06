import Foundation

// MARK: - User Account

public struct UserAccount: Codable, Sendable, Equatable {
    public var displayName: String
    public var passwordSalt: String
    public var passwordHash: String
    public var registeredAt: Date

    public init(displayName: String, passwordSalt: String, passwordHash: String, registeredAt: Date = Date()) {
        self.displayName = displayName
        self.passwordSalt = passwordSalt
        self.passwordHash = passwordHash
        self.registeredAt = registeredAt
    }
}

// MARK: - Adoption Profile

public enum PetGender: String, Codable, Sendable, CaseIterable {
    case male
    case female
    case neutral

    public var labelKey: String { "gender.\(rawValue)" }
}

public enum ExpectedPetPersonality: String, Codable, Sendable, CaseIterable {
    case gentle
    case playful
    case quiet
    case clingy

    public var labelKey: String { "personality.\(rawValue)" }
}

public enum PetLanguage: String, Codable, Sendable, CaseIterable {
    case chinese = "zh"
    case english = "en"
    case japanese = "ja"

    public var labelKey: String { "language.\(rawValue)" }
}

public struct PetAdoptionProfile: Codable, Sendable, Equatable {
    public var petName: String
    public var speciesID: PetSpeciesID
    public var gender: PetGender
    public var expectedPersonality: ExpectedPetPersonality
    public var language: PetLanguage
    public var adoptedAt: Date

    public init(
        petName: String,
        speciesID: PetSpeciesID,
        gender: PetGender,
        expectedPersonality: ExpectedPetPersonality,
        language: PetLanguage,
        adoptedAt: Date = Date()
    ) {
        self.petName = petName
        self.speciesID = speciesID
        self.gender = gender
        self.expectedPersonality = expectedPersonality
        self.language = language
        self.adoptedAt = adoptedAt
    }
}

// MARK: - Owned Pet (max 2 per user, different species)

public struct OwnedPet: Codable, Sendable, Identifiable {
    public let id: UUID
    public var adoption: PetAdoptionProfile
    public var snapshot: PetSnapshot
    public var personality: PersonalityProfileData

    public init(
        id: UUID = UUID(),
        adoption: PetAdoptionProfile,
        snapshot: PetSnapshot? = nil,
        personality: PersonalityProfileData = .neutral
    ) {
        self.id = id
        self.adoption = adoption
        self.snapshot = snapshot ?? PetSnapshot(speciesID: adoption.speciesID)
        self.personality = personality
    }
}

/// 与 EmoPetPersonality 包解耦的轻量副本，便于 Kit 层序列化
public struct PersonalityProfileData: Codable, Sendable, Equatable {
    public var consistency: Double
    public var affection: Double
    public var responsiveness: Double
    public var playfulness: Double
    public var discipline: Double

    public static let neutral = PersonalityProfileData(
        consistency: 0.5, affection: 0.5, responsiveness: 0.5,
        playfulness: 0.5, discipline: 0.5
    )

    public init(consistency: Double, affection: Double, responsiveness: Double, playfulness: Double, discipline: Double) {
        self.consistency = consistency.clamped(to: 0...1)
        self.affection = affection.clamped(to: 0...1)
        self.responsiveness = responsiveness.clamped(to: 0...1)
        self.playfulness = playfulness.clamped(to: 0...1)
        self.discipline = discipline.clamped(to: 0...1)
    }
}

public struct UserSession: Codable, Sendable {
    public static let maxPets = 2

    public var account: UserAccount
    public var pets: [OwnedPet]
    public var activePetID: UUID?

    public init(account: UserAccount, pets: [OwnedPet] = [], activePetID: UUID? = nil) {
        self.account = account
        self.pets = pets
        self.activePetID = activePetID
    }

    public var activePet: OwnedPet? {
        guard let id = activePetID else { return pets.first }
        return pets.first { $0.id == id } ?? pets.first
    }

    public var adoptedSpecies: Set<PetSpeciesID> {
        Set(pets.map(\.adoption.speciesID))
    }

    public var canAdoptMore: Bool {
        pets.count < Self.maxPets
    }

    public func canAdopt(species: PetSpeciesID) -> Bool {
        canAdoptMore && !adoptedSpecies.contains(species)
    }

    public mutating func adopt(_ profile: PetAdoptionProfile) throws {
        guard canAdopt(species: profile.speciesID) else {
            throw UserSessionError.petLimitReached
        }
        let pet = OwnedPet(adoption: profile)
        pets.append(pet)
        if activePetID == nil { activePetID = pet.id }
    }
}

public enum UserSessionError: Error, Sendable {
    case petLimitReached
    case speciesAlreadyAdopted
    case invalidCredentials
    case accountAlreadyExists
}

public enum AppFlowPhase: Sendable, Equatable {
    case registration
    case login
    case adoption
    case home
}
