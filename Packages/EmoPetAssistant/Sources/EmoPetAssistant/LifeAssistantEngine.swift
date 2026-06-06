import Foundation
import EmoPetKit

/// 生活助手：成熟期解锁，以宠物视角呈现
public struct AssistantTask: Identifiable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var scheduledAt: Date
    public var kind: AssistantTaskKind
    public var isCompleted: Bool

    public init(id: UUID = UUID(), title: String, scheduledAt: Date, kind: AssistantTaskKind, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.scheduledAt = scheduledAt
        self.kind = kind
        self.isCompleted = isCompleted
    }
}

public enum AssistantTaskKind: String, Codable, Sendable {
    case alarm
    case studyFocus
    case exerciseCheckIn
    case scheduleReminder
}

public struct LifeAssistantEngine: Sendable {
    public init() {}

    public func petPresentation(for task: AssistantTask) -> AssistantPresentation {
        switch task.kind {
        case .alarm:
            return AssistantPresentation(
                animation: .alarmWake,
                inviteCopy: "起床啦……我们一起迎接新的一天",
                completionCopy: "耶……今天也准时了"
            )
        case .studyFocus:
            return AssistantPresentation(
                animation: .studyCompanion,
                inviteCopy: "学习时间到……我陪你一起",
                completionCopy: "好棒……今天也坚持下来了"
            )
        case .exerciseCheckIn:
            return AssistantPresentation(
                animation: .exerciseCompanion,
                inviteCopy: "今天……也要动起来哦",
                completionCopy: "一起运动……好开心"
            )
        case .scheduleReminder:
            return AssistantPresentation(
                animation: .walkToEdge,
                inviteCopy: "别忘了……\(task.title)",
                completionCopy: "完成啦……真可靠"
            )
        }
    }

    public func isAvailable(unlocked: UnlockedFeatures) -> Bool {
        unlocked.lifeAssistant
    }
}

public struct AssistantPresentation: Sendable {
    public let animation: PetAnimation
    public let inviteCopy: String
    public let completionCopy: String
}
