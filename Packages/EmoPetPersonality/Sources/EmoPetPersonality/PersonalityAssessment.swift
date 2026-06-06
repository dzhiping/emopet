import Foundation
import EmoPetKit

/// 用户个性维度：全部本地采集，用于匹配情感功能
public struct PersonalityProfile: Codable, Sendable, Equatable {
    public var consistency: Double      // 照料规律性
    public var affection: Double        // 抚摸/互动频率
    public var responsiveness: Double   // 对宠物需求的响应速度
    public var playfulness: Double      // 游戏/玩耍倾向
    public var discipline: Double     // 生活助手功能使用率

    public static let neutral = PersonalityProfile(
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

public enum PersonalityArchetype: String, Codable, Sendable {
    case gentleCaretaker   // 温柔照料型
    case playfulCompanion  // 活泼玩伴型
    case busyButLoving     // 忙碌但深情型
    case structuredPartner // 自律伙伴型
    case explorer          // 探索型（功能尝鲜）
}

public struct PersonalityAssessmentEngine: Sendable {
    private let learningRate: Double = 0.08

    public init() {}

    public mutating func observe(_ signal: PersonalitySignal, profile: inout PersonalityProfile) {
        switch signal {
        case .fedOnTime:
            profile.consistency = lerp(profile.consistency, 1.0)
        case .fedLate:
            profile.consistency = lerp(profile.consistency, 0.2)
        case .pettingSession(let seconds):
            let target = min(1.0, seconds / 30.0)
            profile.affection = lerp(profile.affection, target)
        case .respondedQuickly:
            profile.responsiveness = lerp(profile.responsiveness, 1.0)
        case .respondedSlowly:
            profile.responsiveness = lerp(profile.responsiveness, 0.3)
        case .playedMiniGame:
            profile.playfulness = lerp(profile.playfulness, 1.0)
        case .usedAssistantFeature:
            profile.discipline = lerp(profile.discipline, 1.0)
        case .ignoredNotification:
            profile.responsiveness = lerp(profile.responsiveness, 0.4)
        }
    }

    public func classify(_ profile: PersonalityProfile) -> PersonalityArchetype {
        if profile.discipline > 0.65 { return .structuredPartner }
        if profile.playfulness > 0.65 { return .playfulCompanion }
        if profile.affection > 0.65, profile.consistency < 0.45 { return .busyButLoving }
        if profile.affection > 0.55, profile.consistency > 0.55 { return .gentleCaretaker }
        return .explorer
    }

    /// 根据个性匹配情感功能权重
    public func featureEmphasis(for archetype: PersonalityArchetype) -> FeatureEmphasis {
        switch archetype {
        case .gentleCaretaker:
            return FeatureEmphasis(pettingBonus: 1.3, proactiveFrequency: 1.2, assistantPriority: 0.8)
        case .playfulCompanion:
            return FeatureEmphasis(pettingBonus: 1.0, proactiveFrequency: 1.5, assistantPriority: 0.6)
        case .busyButLoving:
            return FeatureEmphasis(pettingBonus: 1.4, proactiveFrequency: 0.8, assistantPriority: 1.0)
        case .structuredPartner:
            return FeatureEmphasis(pettingBonus: 0.9, proactiveFrequency: 1.0, assistantPriority: 1.5)
        case .explorer:
            return FeatureEmphasis(pettingBonus: 1.0, proactiveFrequency: 1.1, assistantPriority: 1.1)
        }
    }

    private func lerp(_ current: Double, _ target: Double) -> Double {
        (current + (target - current) * learningRate).clamped(to: 0...1)
    }
}

public enum PersonalitySignal: Sendable {
    case fedOnTime
    case fedLate
    case pettingSession(seconds: TimeInterval)
    case respondedQuickly
    case respondedSlowly
    case playedMiniGame
    case usedAssistantFeature
    case ignoredNotification
}

public struct FeatureEmphasis: Sendable {
    public let pettingBonus: Double
    public let proactiveFrequency: Double
    public let assistantPriority: Double
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
