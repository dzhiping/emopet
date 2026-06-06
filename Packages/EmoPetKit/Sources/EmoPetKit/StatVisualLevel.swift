import Foundation

/// 对用户隐藏具体数值，仅通过颜色与图标传达状态
public enum StatVisualLevel: Int, Sendable, Comparable, CaseIterable {
    case black = 0    // 0–20  危急
    case purple = 1   // 20–40 很差
    case red = 2      // 40–60 偏差
    case orange = 3   // 60–80 一般
    case yellow = 4   // 80–90 良好
    case green = 5    // 90+   优秀

    public static func < (lhs: StatVisualLevel, rhs: StatVisualLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static func from(value: Double) -> StatVisualLevel {
        let v = value.clamped(to: 0...100)
        switch v {
        case 90...100: return .green
        case 80..<90: return .yellow
        case 60..<80: return .orange
        case 40..<60: return .red
        case 20..<40: return .purple
        default: return .black
        }
    }

    public var iconName: String {
        switch self {
        case .green: return "checkmark.circle.fill"
        case .yellow: return "minus.circle.fill"
        case .orange: return "exclamationmark.circle.fill"
        case .red: return "exclamationmark.triangle.fill"
        case .purple: return "exclamationmark.octagon.fill"
        case .black: return "xmark.circle.fill"
        }
    }

    public var hintKey: String {
        switch self {
        case .green: return "stat.hint.excellent"
        case .yellow: return "stat.hint.good"
        case .orange: return "stat.hint.fair"
        case .red: return "stat.hint.low"
        case .purple: return "stat.hint.poor"
        case .black: return "stat.hint.critical"
        }
    }

    public var rgb: StatVisualColor {
        switch self {
        case .green: return StatVisualColor(red: 0.2, green: 0.78, blue: 0.35)
        case .yellow: return StatVisualColor(red: 1.0, green: 0.8, blue: 0.0)
        case .orange: return StatVisualColor(red: 1.0, green: 0.55, blue: 0.1)
        case .red: return StatVisualColor(red: 0.95, green: 0.25, blue: 0.25)
        case .purple: return StatVisualColor(red: 0.6, green: 0.2, blue: 0.8)
        case .black: return StatVisualColor(red: 0.15, green: 0.15, blue: 0.18)
        }
    }
}

public struct StatVisualColor: Sendable {
    public let red, green, blue: Double
    public init(red: Double, green: Double, blue: Double) {
        self.red = red; self.green = green; self.blue = blue
    }
}

public struct StatIndicatorItem: Sendable, Identifiable {
    public let id: StatKind
    public let kind: StatKind
    public let level: StatVisualLevel

    public init(kind: StatKind, value: Double) {
        self.id = kind
        self.kind = kind
        self.level = StatVisualLevel.from(value: value)
    }
}

public extension PetStats {
    func indicatorItems() -> [StatIndicatorItem] {
        StatKind.allCases.map { StatIndicatorItem(kind: $0, value: self[keyPath: $0.keyPath]) }
    }
}
