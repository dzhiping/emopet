import Foundation

/// 文案轮换库：每类 5~8 条，避免用户识破"程序在说话"
public enum NotificationCategory: String, Codable, Sendable, CaseIterable {
    case hungerWarning
    case hungerDanger
    case cleanlinessWarning
    case cleanlinessDanger
    case emotionalInvite
    case neglect
    case illness
    case reunion
    case studyReminder
    case exerciseReminder
    case alarm
    case milestone
}

public struct RotatingCopyLibrary: Sendable {
    private let templates: [NotificationCategory: [String]]
    private var lastIndex: [NotificationCategory: Int] = [:]

    public init(templates: [NotificationCategory: [String]]) {
        self.templates = templates
    }

    public mutating func next(for category: NotificationCategory) -> String {
        guard let pool = templates[category], !pool.isEmpty else {
            return "……"
        }
        let idx = (lastIndex[category, default: -1] + 1) % pool.count
        lastIndex[category] = idx
        return pool[idx]
    }

    public func validate() -> [NotificationCategory] {
        templates.compactMap { category, lines in
            (lines.count < 5 || lines.count > 8) ? category : nil
        }
    }
}

public enum NotificationPriority: Int, Sendable, Comparable {
    case p0Urgent = 0
    case p1Important = 1
    case p2Routine = 2

    public static func < (lhs: NotificationPriority, rhs: NotificationPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum NotificationTimeSlot: String, Sendable {
    case morning    // 生理需求
    case afternoon  // 情感互动
    case evening    // 生活助手
}

public struct PendingNotification: Sendable, Identifiable {
    public let id: UUID
    public let category: NotificationCategory
    public let priority: NotificationPriority
    public let slot: NotificationTimeSlot
    public let body: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        category: NotificationCategory,
        priority: NotificationPriority,
        slot: NotificationTimeSlot,
        body: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.priority = priority
        self.slot = slot
        self.body = body
        self.createdAt = createdAt
    }
}

public struct NotificationSchedulerConfig: Sendable {
    public let dailyQuota: Int = 3
    public let smartDNDConsecutiveIgnores: Int = 3

    public init() {}
}

public struct NotificationScheduler {
    private let config: NotificationSchedulerConfig
    private var copyLibrary: RotatingCopyLibrary
    private var sentToday: [PendingNotification] = []
    private var ignoreStreak: [NotificationCategory: Int] = [:]

    public init(config: NotificationSchedulerConfig = NotificationSchedulerConfig(), copyLibrary: RotatingCopyLibrary) {
        self.config = config
        self.copyLibrary = copyLibrary
    }

    public mutating func resetDailyIfNeeded(now: Date, calendar: Calendar = .current) {
        guard let last = sentToday.last else { return }
        if !calendar.isDate(last.createdAt, inSameDayAs: now) {
            sentToday.removeAll()
        }
    }

    public mutating func enqueue(
        category: NotificationCategory,
        priority: NotificationPriority,
        slot: NotificationTimeSlot
    ) -> PendingNotification? {
        if priority != .p0Urgent, sentToday.count >= config.dailyQuota {
            return nil
        }
        if let streak = ignoreStreak[category], streak >= config.smartDNDConsecutiveIgnores, priority == .p2Routine {
            return nil
        }
        let body = copyLibrary.next(for: category)
        let notification = PendingNotification(category: category, priority: priority, slot: slot, body: body)
        sentToday.append(notification)
        return notification
    }

    public mutating func recordResponse(for category: NotificationCategory, responded: Bool) {
        if responded {
            ignoreStreak[category] = 0
        } else {
            ignoreStreak[category, default: 0] += 1
        }
    }
}
