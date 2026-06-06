import Foundation
import EmoPetKit

/// 主动互动行为生成器：宠物"提需求"而非被动等待
public struct ProactiveInteractionGenerator: Sendable {
    public init() {}

    public func suggest(for snapshot: PetSnapshot) -> ProactiveInteraction? {
        if snapshot.presence == .reunionPending {
            return ProactiveInteraction(animation: .wakeUpReunion, message: "……你回来了", urgency: .high)
        }
        if snapshot.stats.hunger < 30 {
            return ProactiveInteraction(animation: .lieDown, message: "肚子……好饿", urgency: .high)
        }
        if snapshot.wasteNeedsCleaning {
            return ProactiveInteraction(animation: .walkToEdge, message: "……有点臭", urgency: .medium)
        }
        if snapshot.emotion == .cold || snapshot.emotion == .wronged {
            return ProactiveInteraction(animation: .pawScratch, message: "……好久没理我了", urgency: .medium)
        }
        if snapshot.stats.intimacy > 40, snapshot.emotion == .happy {
            return ProactiveInteraction(animation: .pawScratch, message: "来玩嘛", urgency: .low)
        }
        return nil
    }
}

public struct ProactiveInteraction: Sendable {
    public let animation: PetAnimation
    public let message: String
    public let urgency: Urgency

    public enum Urgency: Sendable {
        case low, medium, high
    }
}
