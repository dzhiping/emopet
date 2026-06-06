import EmoPetKit
import SwiftUI

/// 卡通宠物形象：SwiftUI 矢量绘制，不同状态有不同表情与姿态
struct CartoonPetView: View {
    let species: PetSpeciesID
    let state: PetVisualState
    var size: CGFloat = 140

    var body: some View {
        CartoonPetAvatar(species: species, state: state)
            .frame(width: size, height: size)
            .petSymbolBounce(trigger: state)
    }
}

struct CartoonPetPreview: View {
    let species: PetSpeciesID
    let state: PetVisualState
    var size: CGFloat = 120

    var body: some View {
        CartoonPetView(species: species, state: state, size: size)
    }
}

private struct CartoonPetAvatar: View {
    let species: PetSpeciesID
    let state: PetVisualState

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.secondary.opacity(0.08))
                .frame(width: 120, height: 24)
                .offset(y: 52)
            petBody
        }
    }

    @ViewBuilder
    private var petBody: some View {
        switch species {
        case .cat: catBody
        case .dog: dogBody
        }
    }

    private var catBody: some View {
        ZStack {
            // 身体
            RoundedRectangle(cornerRadius: 28)
                .fill(bodyColor)
                .frame(width: 88, height: 72)
                .offset(y: 18)
            // 头
            Circle()
                .fill(bodyColor)
                .frame(width: 76, height: 76)
                .offset(y: -18)
            // 耳朵
            HStack(spacing: 44) {
                ear(tilt: -18)
                ear(tilt: 18)
            }
            .offset(y: -48)
            faceFeatures
            stateOverlay
        }
    }

    private var dogBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(bodyColor)
                .frame(width: 92, height: 78)
                .offset(y: 20)
            Circle()
                .fill(bodyColor)
                .frame(width: 80, height: 80)
                .offset(y: -16)
            HStack(spacing: 50) {
                floppyEar(left: true)
                floppyEar(left: false)
            }
            .offset(y: -42)
            // 鼻子
            Circle()
                .fill(Color.black.opacity(0.75))
                .frame(width: 14, height: 10)
                .offset(y: -6)
            faceFeatures
            stateOverlay
        }
    }

    private func ear(tilt: Double) -> some View {
        Triangle()
            .fill(bodyColor.darker(by: 0.08))
            .frame(width: 22, height: 26)
            .rotationEffect(.degrees(tilt))
    }

    private func floppyEar(left: Bool) -> some View {
        Capsule()
            .fill(bodyColor.darker(by: 0.12))
            .frame(width: 22, height: 36)
            .rotationEffect(.degrees(left ? -25 : 25))
    }

    @ViewBuilder
    private var faceFeatures: some View {
        HStack(spacing: 22) {
            eye
            eye
        }
        .offset(y: -26)
        mouth
            .offset(y: -8)
    }

    private var eye: some View {
        Group {
            switch state {
            case .sleeping, .tired:
                Capsule().fill(Color.black.opacity(0.7)).frame(width: 14, height: 3)
            case .happy, .playing, .reunion:
                ArcSmile().stroke(Color.black.opacity(0.7), lineWidth: 2).frame(width: 12, height: 8)
            case .angry:
                Rectangle().fill(Color.black.opacity(0.7)).frame(width: 12, height: 3).rotationEffect(.degrees(-15))
            case .sick, .hungry:
                Circle().fill(Color.black.opacity(0.7)).frame(width: 8, height: 8)
            default:
                Circle().fill(Color.black.opacity(0.75)).frame(width: 10, height: 10)
            }
        }
    }

    @ViewBuilder
    private var mouth: some View {
        switch state {
        case .happy, .playing, .eating:
            ArcSmile().stroke(Color.black.opacity(0.65), lineWidth: 2).frame(width: 22, height: 12)
        case .angry, .cold:
            ArcFrown().stroke(Color.black.opacity(0.65), lineWidth: 2).frame(width: 20, height: 10)
        case .sick, .hungry:
            Circle().stroke(Color.black.opacity(0.5), lineWidth: 1.5).frame(width: 10, height: 10)
        case .sleeping:
            Text("z").font(.caption.bold()).foregroundStyle(.secondary)
        default:
            Capsule().fill(Color.black.opacity(0.4)).frame(width: 12, height: 2)
        }
    }

    @ViewBuilder
    private var stateOverlay: some View {
        switch state {
        case .sick:
            Image(systemName: "cross.case.fill")
                .foregroundStyle(.red)
                .offset(x: 42, y: -40)
        case .dirty:
            Image(systemName: "smoke.fill")
                .font(.caption)
                .foregroundStyle(.brown)
                .offset(x: -40, y: -36)
        case .hungry:
            Text("🍖").font(.caption).offset(x: 44, y: 0)
        case .reunion:
            Text("💕").font(.caption).offset(y: -58)
        case .sleeping:
            Text("💤").font(.caption).offset(x: 36, y: -44)
        default:
            EmptyView()
        }
    }

    private var bodyColor: Color {
        switch (species, state) {
        case (.cat, .angry): return Color(red: 1.0, green: 0.72, blue: 0.55)
        case (.cat, .sick): return Color(red: 0.92, green: 0.88, blue: 0.85)
        case (.cat, _): return Color(red: 1.0, green: 0.78, blue: 0.52)
        case (.dog, .angry): return Color(red: 0.82, green: 0.65, blue: 0.45)
        case (.dog, .sick): return Color(red: 0.88, green: 0.84, blue: 0.78)
        case (.dog, _): return Color(red: 0.90, green: 0.72, blue: 0.48)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct ArcSmile: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.minY), radius: rect.width / 2,
                 startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
        return p
    }
}

private struct ArcFrown: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.maxY), radius: rect.width / 2,
                 startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
        return p
    }
}

private extension Color {
    func darker(by amount: Double) -> Color {
        Color(red: max(0, amount), green: max(0, amount * 0.9), blue: max(0, amount * 0.85))
    }
}
