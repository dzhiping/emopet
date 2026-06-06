import Foundation

// MARK: - Core Numerical System

public enum StatZone: String, Codable, Sendable {
    case safe
    case warning
    case danger
}

public struct PetStats: Codable, Sendable, Equatable {
    public var hunger: Double
    public var cleanliness: Double
    public var health: Double
    public var intimacy: Double
    public var emotion: Double
    public var growthXP: Double

    public static let initial = PetStats(
        hunger: 80, cleanliness: 80, health: 100,
        intimacy: 0, emotion: 70, growthXP: 0
    )

    public init(hunger: Double, cleanliness: Double, health: Double, intimacy: Double, emotion: Double, growthXP: Double) {
        self.hunger = hunger.clamped(to: 0...100)
        self.cleanliness = cleanliness.clamped(to: 0...100)
        self.health = health.clamped(to: 0...100)
        self.intimacy = intimacy.clamped(to: 0...100)
        self.emotion = emotion.clamped(to: 0...100)
        self.growthXP = max(0, growthXP)
    }

    public func zone(for stat: StatKind) -> StatZone {
        let value: Double
        switch stat {
        case .hunger, .cleanliness, .health, .emotion, .intimacy:
            value = self[keyPath: stat.keyPath]
        }
        switch value {
        case 60...100: return .safe
        case 30..<60: return .warning
        default: return .danger
        }
    }
}

public enum StatKind: String, Codable, Sendable, CaseIterable {
    case hunger, cleanliness, health, emotion, intimacy

    var keyPath: WritableKeyPath<PetStats, Double> {
        switch self {
        case .hunger: \.hunger
        case .cleanliness: \.cleanliness
        case .health: \.health
        case .emotion: \.emotion
        case .intimacy: \.intimacy
        }
    }
}

// MARK: - Growth Stages

public enum GrowthStage: Int, Codable, Sendable, Comparable, CaseIterable {
    case cub = 1       // 幼崽期 0-21天
    case growth = 2    // 成长期 22-45天
    case youth = 3     // 青年期 46-90天
    case mature = 4    // 成熟期 90+天

    public static func < (lhs: GrowthStage, rhs: GrowthStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static func from(ageDays: Int) -> GrowthStage {
        switch ageDays {
        case 0...21: return .cub
        case 22...45: return .growth
        case 46...90: return .youth
        default: return .mature
        }
    }
}

public struct UnlockedFeatures: Codable, Sendable, Equatable {
    public var vocabularyBudding: Bool = false   // 亲密度≥60 + 成长期
    public var fullDialogue: Bool = false        // 亲密度≥75 + 青年期
    public var lifeAssistant: Bool = false       // 亲密度≥85 + 成熟期

    public init() {}

    /// 解锁不可逆：只升不降
    public mutating func applyUnlocks(stage: GrowthStage, intimacy: Double, ageDays: Int) {
        if intimacy >= 60, ageDays >= 22 { vocabularyBudding = true }
        if intimacy >= 75, ageDays >= 46 { fullDialogue = true }
        if intimacy >= 85, stage == .mature { lifeAssistant = true }
    }
}

// MARK: - Emotion State Machine

public enum EmotionState: String, Codable, Sendable, CaseIterable {
    case happy
    case normal
    case wronged
    case angry
    case cold

    public var allowsPetting: Bool {
        switch self {
        case .happy, .normal, .wronged: return true
        case .angry: return false
        case .cold: return false
        }
    }

    public var requiresApology: Bool {
        self == .angry || self == .cold
    }
}

public struct MemoryTag: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let category: MemoryCategory
    public let summary: String
    public let createdAt: Date
    public var weight: Double

    public init(id: UUID = UUID(), category: MemoryCategory, summary: String, createdAt: Date = Date(), weight: Double = 1.0) {
        self.id = id
        self.category = category
        self.summary = summary
        self.createdAt = createdAt
        self.weight = weight
    }
}

public enum MemoryCategory: String, Codable, Sendable {
    case forgotFeeding
    case longPlaySession
    case gentleApology
    case neglectInteraction
    case milestone
    case reunion
    case studyTogether
    case exerciseTogether
}

// MARK: - Sleep Mode & Offline Protection

public enum PetPresenceMode: String, Codable, Sendable {
    case active
    case sleepWaiting   // 48h+ 未打开，数值冻结，等待主人
    case reunionPending // 主人回归，待触发重逢剧情
}

public struct OfflinePolicy: Sendable {
    public let sleepModeThreshold: TimeInterval = 48 * 3600
    public let deepFreezeThreshold: TimeInterval = 72 * 3600
    public let hungerGraceWindow: TimeInterval = 4 * 3600
    public let cleanlinessGraceWindow: TimeInterval = 12 * 3600
    public let sicknessPersistThreshold: TimeInterval = 6 * 3600

    public init() {}
}

// MARK: - Food & Care Actions

public enum FoodType: String, Codable, Sendable, CaseIterable {
    case regularMeal
    case snack
    case medicine

    public var hungerRestore: Double {
        switch self {
        case .regularMeal: 35
        case .snack: 15
        case .medicine: 5
        }
    }

    public var healthDelta: Double {
        switch self {
        case .regularMeal: 2
        case .snack: -3
        case .medicine: 10
        }
    }

    public var emotionDelta: Double {
        switch self {
        case .regularMeal: 3
        case .snack: 8
        case .medicine: -2
        }
    }
}

public enum SicknessPhase: String, Codable, Sendable {
    case healthy
    case subHealthy
    case sick
    case treating       // 已喂药，观察中
    case recovering
}

// MARK: - Helpers

extension Double {
    public func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

public struct PetSnapshot: Codable, Sendable {
    public var stats: PetStats
    public var speciesID: PetSpeciesID
    public var ageDays: Int
    public var stage: GrowthStage
    public var unlocked: UnlockedFeatures
    public var emotion: EmotionState
    public var sickness: SicknessPhase
    public var presence: PetPresenceMode
    public var memoryTags: [MemoryTag]
    public var wasteNeedsCleaning: Bool
    public var lastUpdatedAt: Date
    public var lastOpenedAt: Date
    public var hungerDangerSince: Date?
    public var cleanlinessDangerSince: Date?
    public var lowStatsSince: Date?
    public var createdAt: Date

    public init(
        stats: PetStats = .initial,
        speciesID: PetSpeciesID,
        ageDays: Int = 0,
        stage: GrowthStage = .cub,
        unlocked: UnlockedFeatures = UnlockedFeatures(),
        emotion: EmotionState = .normal,
        sickness: SicknessPhase = .healthy,
        presence: PetPresenceMode = .active,
        memoryTags: [MemoryTag] = [],
        wasteNeedsCleaning: Bool = false,
        lastUpdatedAt: Date = Date(),
        lastOpenedAt: Date = Date(),
        hungerDangerSince: Date? = nil,
        cleanlinessDangerSince: Date? = nil,
        lowStatsSince: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.stats = stats
        self.speciesID = speciesID
        self.ageDays = ageDays
        self.stage = stage
        self.unlocked = unlocked
        self.emotion = emotion
        self.sickness = sickness
        self.presence = presence
        self.memoryTags = memoryTags
        self.wasteNeedsCleaning = wasteNeedsCleaning
        self.lastUpdatedAt = lastUpdatedAt
        self.lastOpenedAt = lastOpenedAt
        self.hungerDangerSince = hungerDangerSince
        self.cleanlinessDangerSince = cleanlinessDangerSince
        self.lowStatsSince = lowStatsSince
        self.createdAt = createdAt
    }
}
