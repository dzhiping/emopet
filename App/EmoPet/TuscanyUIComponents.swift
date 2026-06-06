import EmoPetKit
import SwiftUI

// MARK: - 磨砂玻璃卡片

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.38), lineWidth: 0.8)
                    }
                    .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 8)
            }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Q 弹点击

struct SpringyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.62), value: configuration.isPressed)
    }
}

// MARK: - 环绕宠物的圆形交互气泡

struct PetActionBubble: View {
    let icon: String
    let tint: Color
    var size: CGFloat = 56
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Circle()
                                .strokeBorder(Color.white.opacity(0.45), lineWidth: 0.9)
                        }
                        .shadow(color: .black.opacity(0.16), radius: 10, y: 5)
                }
        }
        .buttonStyle(SpringyButtonStyle())
    }
}

struct PetActionBubbleWithLabel: View {
    let icon: String
    let label: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            PetActionBubble(icon: icon, tint: tint, action: action)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        }
    }
}

/// 按偏移量环绕宠物摆放气泡
struct PetBubbleRing<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content
        }
    }
}

// MARK: - 悬浮胶囊 Tab 项

struct FloatingModuleTab: View {
    let tab: PetModuleTab
    let isSelected: Bool
    let language: PetLanguage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon(for: tab))
                    .font(.system(size: 18, weight: .semibold))
                Text(L10n.text(tab.l10nKey, language: language))
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color(red: 0.95, green: 0.55, blue: 0.28) : Color.primary.opacity(0.72))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.22))
                }
            }
        }
        .buttonStyle(SpringyButtonStyle())
    }

    private func icon(for tab: PetModuleTab) -> String {
        switch tab {
        case .physiological: return "heart.text.square.fill"
        case .interaction: return "hand.wave.fill"
        case .dialogue: return "bubble.left.and.bubble.right.fill"
        case .assistant: return "alarm.fill"
        }
    }
}
