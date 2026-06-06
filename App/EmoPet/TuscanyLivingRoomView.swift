import EmoPetKit
import SwiftUI
import UIKit

/// 托斯卡纳客厅 2.5D 主场景：[全屏背景] → [宠物 + 环绕气泡] → [悬浮磨砂 UI]
struct TuscanyLivingRoomView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var roomClock = RoomClock()
    @State private var selectedModule: PetModuleTab = .physiological

    private var lang: PetLanguage { appState.uiLanguage }

    var body: some View {
        GeometryReader { geo in
            let petSize = min(geo.size.width, geo.size.height) * 0.46

            ZStack {
                TuscanyRoomBackground(timeOfDay: roomClock.timeOfDay)

                VStack(spacing: 0) {
                    topHUD
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    Spacer()

                    ZStack {
                        petStage(in: geo, petSize: petSize)
                        moduleBubbleLayer(width: geo.size.width)
                    }
                    .frame(height: geo.size.height * 0.52)

                    Spacer(minLength: geo.size.height * 0.06)

                    floatingTabBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom, 16) + 8)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            appState.petAssets.preload(species: appState.pet.speciesID)
            appState.petAssets.sync(snapshot: appState.pet)
        }
        .onChange(of: appState.pet.speciesID) { species in
            appState.petAssets.preload(species: species)
            appState.petAssets.sync(snapshot: appState.pet)
        }
        .onChange(of: appState.visualState) { _ in
            appState.petAssets.sync(snapshot: appState.pet)
        }
    }

    // MARK: - 顶栏

    private var topHUD: some View {
        HStack(alignment: .top, spacing: 12) {
            if let owned = appState.activeOwnedPet {
                VStack(alignment: .leading, spacing: 2) {
                    Text(owned.adoption.petName)
                        .font(.title3.weight(.bold))
                    Text(L10n.text(appState.pet.stage.l10nKey, language: lang))
                        .font(.caption)
                        .opacity(0.82)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassCard(cornerRadius: 14)
            }
            Spacer(minLength: 8)
            GlassStatPanel()
                .environmentObject(appState)
        }
    }

    // MARK: - 宠物舞台（对齐地面透视线）

    private func petStage(in geo: GeometryProxy, petSize: CGFloat) -> some View {
        ZStack {
            if appState.petAssets.useFallbackRenderer {
                CartoonPetView(
                    species: appState.pet.speciesID,
                    state: appState.visualState,
                    size: petSize
                )
                .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 12)
            } else {
                TransparentVideoPlayer(
                    player: appState.petAssets.queuePlayer,
                    allowsPetHitTesting: false
                )
                .frame(width: petSize * 1.15, height: petSize * 1.15)
            }

            sceneProps
            speechStack(offsetY: -petSize * 0.62)
        }
        .offset(y: geo.size.height * 0.04)
    }

    @ViewBuilder
    private var sceneProps: some View {
        if appState.pet.wasteNeedsCleaning {
            WastePropView()
                .offset(x: -72, y: 64)
        }
        if appState.pet.stats.hunger < 40 {
            EmptyBowlPropView()
                .offset(x: 78, y: 72)
        }
    }

    @ViewBuilder
    private func speechStack(offsetY: CGFloat) -> some View {
        VStack(spacing: 8) {
            if let msg = appState.proactiveMessage {
                PetSpeechBubble(text: msg)
            }
            if !appState.lastDialogue.isEmpty {
                PetSpeechBubble(text: appState.lastDialogue)
            }
            if appState.pet.presence == .reunionPending {
                Button(L10n.text("button.reunion", language: lang)) {
                    appState.perform(.completeReunion)
                }
                .buttonStyle(SpringyButtonStyle())
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule(style: .continuous).fill(.ultraThinMaterial))
                .overlay(Capsule(style: .continuous).strokeBorder(Color.white.opacity(0.4), lineWidth: 0.8))
            }
        }
        .offset(y: offsetY)
    }

    // MARK: - 模块气泡层（环绕宠物）

    @ViewBuilder
    private func moduleBubbleLayer(width: CGFloat) -> some View {
        let radiusX = width * 0.38
        let radiusY = width * 0.22

        ZStack {
            switch selectedModule {
            case .physiological:
                bubble(icon: "fork.knife", tint: .orange, x: -radiusX, y: -radiusY * 0.5) {
                    appState.perform(.feed(.regularMeal), oneShot: .feed)
                }
                bubble(icon: "carrot.fill", tint: .green, x: -radiusX * 0.82, y: radiusY * 0.35) {
                    appState.perform(.feed(.snack), oneShot: .snack)
                }
                bubble(icon: "shower.fill", tint: .cyan, x: radiusX, y: -radiusY * 0.45) {
                    appState.perform(.bathe, oneShot: .bath)
                }
                bubble(icon: "trash.fill", tint: .brown, x: radiusX * 0.85, y: radiusY * 0.4) {
                    appState.perform(.cleanWaste, oneShot: .clean)
                }
                if appState.pet.sickness == .sick {
                    bubble(icon: "pills.fill", tint: .pink, x: 0, y: radiusY * 0.95) {
                        appState.perform(.medicine, oneShot: .medicine)
                    }
                }
            case .interaction:
                bubble(icon: "hand.wave.fill", tint: .yellow, x: -radiusX * 0.9, y: 0) {
                    appState.perform(.pet, oneShot: .pet)
                }
                bubble(icon: "gamecontroller.fill", tint: .purple, x: radiusX * 0.9, y: 0) {
                    appState.perform(.play, oneShot: .play)
                }
                if appState.pet.emotion.requiresApology {
                    bubble(icon: "heart.fill", tint: .red, x: 0, y: radiusY) {
                        appState.perform(.apologize, oneShot: .apologize)
                    }
                }
            case .dialogue:
                if appState.pet.unlocked.vocabularyBudding {
                    bubble(icon: "bubble.left.fill", tint: .mint, x: -radiusX * 0.75, y: -radiusY * 0.2) {
                        appState.speak(topic: .greeting)
                    }
                    bubble(icon: "clock.arrow.circlepath", tint: .indigo, x: radiusX * 0.75, y: -radiusY * 0.2) {
                        appState.speak(topic: .memory)
                    }
                    bubble(icon: "leaf.fill", tint: .teal, x: 0, y: radiusY * 0.85) {
                        appState.speak(topic: .comfort)
                    }
                }
            case .assistant:
                if appState.pet.unlocked.lifeAssistant {
                    bubble(icon: "alarm.fill", tint: .orange, x: -radiusX, y: -radiusY * 0.3) {
                        appState.playAssistantAnimation(.alarm)
                    }
                    bubble(icon: "book.fill", tint: .blue, x: -radiusX * 0.5, y: radiusY * 0.5) {
                        appState.playAssistantAnimation(.study)
                    }
                    bubble(icon: "checkmark.circle.fill", tint: .green, x: radiusX * 0.5, y: radiusY * 0.5) {
                        appState.playAssistantAnimation(.studyDone)
                    }
                    bubble(icon: "figure.run", tint: .cyan, x: radiusX, y: -radiusY * 0.3) {
                        appState.playAssistantAnimation(.exercise)
                    }
                }
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: selectedModule)
    }

    private func bubble(icon: String, tint: Color, x: CGFloat, y: CGFloat, action: @escaping () -> Void) -> some View {
        PetActionBubble(icon: icon, tint: tint, action: action)
            .offset(x: x, y: y)
    }

    // MARK: - 悬浮胶囊 TabBar

    private var floatingTabBar: some View {
        HStack(spacing: 4) {
            ForEach(PetModuleTab.allCases, id: \.self) { tab in
                FloatingModuleTab(
                    tab: tab,
                    isSelected: selectedModule == tab,
                    language: lang
                ) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                        selectedModule = tab
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.42), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
        }
    }
}

// MARK: - 全屏背景

struct TuscanyRoomBackground: View {
    let timeOfDay: RoomTimeOfDay

    var body: some View {
        Group {
            if UIImage(named: "tuscany_living_room_bg") != nil {
                Image("tuscany_living_room_bg")
                    .resizable()
                    .scaledToFill()
            } else if UIImage(named: timeOfDay.backgroundAssetName) != nil {
                Image(timeOfDay.backgroundAssetName)
                    .resizable()
                    .scaledToFill()
            } else {
                TuscanySoftFallbackBackground(timeOfDay: timeOfDay)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }
}

/// 无美术资源时的柔和单色暖调兜底（无三段断层）
struct TuscanySoftFallbackBackground: View {
    let timeOfDay: RoomTimeOfDay

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay {
            RadialGradient(
                colors: [Color.white.opacity(0.18), Color.clear],
                center: .init(x: 0.5, y: 0.35),
                startRadius: 20,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }

    private var gradientColors: [Color] {
        switch timeOfDay {
        case .day:
            return [
                Color(red: 0.72, green: 0.84, blue: 0.94),
                Color(red: 0.88, green: 0.78, blue: 0.66),
                Color(red: 0.78, green: 0.62, blue: 0.48),
            ]
        case .dusk:
            return [
                Color(red: 0.55, green: 0.38, blue: 0.52),
                Color(red: 0.82, green: 0.52, blue: 0.38),
                Color(red: 0.62, green: 0.42, blue: 0.36),
            ]
        case .night:
            return [
                Color(red: 0.14, green: 0.16, blue: 0.28),
                Color(red: 0.22, green: 0.20, blue: 0.32),
                Color(red: 0.28, green: 0.22, blue: 0.26),
            ]
        }
    }
}

struct PetSpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .multilineTextAlignment(.center)
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .glassCard(cornerRadius: 18)
            .frame(maxWidth: 260)
    }
}

struct WastePropView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        PetActionBubble(icon: "leaf.fill", tint: .brown, size: 48) {
            appState.perform(.cleanWaste, oneShot: .clean)
        }
        .accessibilityLabel("清理粪便")
    }
}

struct EmptyBowlPropView: View {
    var body: some View {
        Image(systemName: "bowl.fill")
            .font(.title2)
            .foregroundStyle(.orange.opacity(0.85))
            .padding(10)
            .background(Circle().fill(.ultraThinMaterial))
    }
}

/// 磨砂玻璃状态面板
struct GlassStatPanel: View {
    @EnvironmentObject var appState: AppState
    private var lang: PetLanguage { appState.uiLanguage }

    var body: some View {
        VStack(alignment: .trailing, spacing: 9) {
            ForEach(appState.pet.stats.indicatorItems()) { item in
                HStack(spacing: 7) {
                    Image(systemName: item.level.iconName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(levelColor(item))
                    Text(L10n.text(item.kind.l10nKey, language: lang))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.primary.opacity(0.88))
                    HStack(spacing: 3) {
                        ForEach(0..<6, id: \.self) { i in
                            Capsule()
                                .fill(i <= item.level.rawValue ? levelColor(item) : Color.primary.opacity(0.12))
                                .frame(width: 11, height: 4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 16)
    }

    private func levelColor(_ item: StatIndicatorItem) -> Color {
        let c = item.level.rgb
        return Color(red: c.red, green: c.green, blue: c.blue)
    }
}

@MainActor
final class RoomClock: ObservableObject {
    @Published var timeOfDay: RoomTimeOfDay = .current()

    init() {
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.timeOfDay = .current() }
        }
    }
}
