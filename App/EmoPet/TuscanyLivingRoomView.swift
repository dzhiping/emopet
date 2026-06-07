import EmoPetKit
import SwiftUI
import UIKit

/// 托斯卡纳客厅 2.5D 主场景：[全屏背景] → [宠物 + 环绕气泡] → [悬浮磨砂 UI]
struct TuscanyLivingRoomView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var roomClock = RoomClock()
    @State private var selectedModule: PetModuleTab = .physiological
    @State private var showSettings = false

    private var lang: PetLanguage { appState.uiLanguage }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                TuscanyRoomBackground(timeOfDay: roomClock.timeOfDay)

                fullScreenPetStage(in: geo)

                scenePropsOverlay(in: geo)

                HStack(alignment: .center, spacing: 0) {
                    leftActionColumn
                        .padding(.leading, 12)
                        .frame(width: 58)

                    Spacer(minLength: 0)

                    GlassStatPanel()
                        .environmentObject(appState)
                        .padding(.trailing, 10)
                        .frame(width: min(118, geo.size.width * 0.28))
                }
                .padding(.bottom, tabBarReservedHeight(in: geo))

                VStack {
                    speechStack
                        .padding(.top, 4)
                    Spacer()
                }
                .padding(.horizontal, 80)
                .padding(.bottom, tabBarReservedHeight(in: geo))
            }
            .overlay(alignment: .top) {
                topChrome
                    .padding(.horizontal, 16)
                    .padding(.top, geo.safeAreaInsets.top + 4)
            }
            .overlay(alignment: .bottom) {
                floatingTabBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 10))
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .onAppear {
            appState.petAssets.preload(species: appState.pet.speciesID)
            appState.petAssets.activatePlayback(with: appState.pet)
        }
        .onChange(of: appState.pet.speciesID) { species in
            appState.petAssets.preload(species: species)
            appState.petAssets.activatePlayback(with: appState.pet)
        }
        .onChange(of: appState.visualState) { _ in
            appState.petAssets.sync(snapshot: appState.pet)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                appState.petAssets.activatePlayback(with: appState.pet)
            }
        }
    }

    private func tabBarReservedHeight(in geo: GeometryProxy) -> CGFloat {
        max(geo.safeAreaInsets.bottom, 10) + 72
    }

    // MARK: - 顶栏：成长阶段居中 + 设置按钮右上

    private var topChrome: some View {
        ZStack {
            growthStageBadge

            HStack {
                Spacer()
                settingsButton
            }
        }
        .frame(minHeight: 40)
    }

    private var growthStageBadge: some View {
        VStack(spacing: 3) {
            if let owned = appState.activeOwnedPet {
                Text(owned.adoption.petName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary.opacity(0.78))
                    .lineLimit(1)
            }
            Text(L10n.text(appState.pet.stage.l10nKey, language: lang))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .glassCard(cornerRadius: 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.text(appState.pet.stage.l10nKey, language: lang))
    }

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.88))
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Circle()
                                .strokeBorder(Color.white.opacity(0.38), lineWidth: 0.8)
                        }
                }
        }
        .buttonStyle(SpringyButtonStyle())
        .accessibilityLabel(L10n.text("settings.title", language: lang))
    }

    // MARK: - 全屏宠物舞台

    private func fullScreenPetStage(in geo: GeometryProxy) -> some View {
        let screenW = geo.size.width
        let screenH = geo.size.height
        let heroSize = max(screenW, screenH) * 0.92
        let showVideo = appState.petAssets.hasVideoAsset || appState.petAssets.hasBundledVideo

        return ZStack {
            if showVideo {
                TransparentVideoPlayer(
                    player: appState.petAssets.queuePlayer,
                    allowsPetHitTesting: false,
                    fillScreen: true
                )
                .id(appState.petAssets.playbackRevision)
                .frame(width: screenW, height: screenH)
            } else {
                CartoonPetView(
                    species: appState.pet.speciesID,
                    state: appState.visualState,
                    size: heroSize
                )
                .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
            }
        }
        .frame(width: screenW, height: screenH)
        .clipped()
    }

    @ViewBuilder
    private func scenePropsOverlay(in geo: GeometryProxy) -> some View {
        ZStack {
            if appState.pet.wasteNeedsCleaning {
                WastePropView()
                    .offset(x: -geo.size.width * 0.1, y: geo.size.height * 0.1)
            }
            if appState.pet.stats.hunger < 40 {
                EmptyBowlPropView()
                    .offset(x: geo.size.width * 0.1, y: geo.size.height * 0.12)
            }
        }
    }

    @ViewBuilder
    private var speechStack: some View {
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
    }

    // MARK: - 左侧互动按钮列

    @ViewBuilder
    private var leftActionColumn: some View {
        VStack(spacing: 12) {
            switch selectedModule {
            case .physiological:
                actionBubble(icon: "fork.knife", tint: .orange) {
                    appState.perform(.feed(.regularMeal), oneShot: .feed)
                }
                actionBubble(icon: "carrot.fill", tint: .green) {
                    appState.perform(.feed(.snack), oneShot: .snack)
                }
                actionBubble(icon: "shower.fill", tint: .cyan) {
                    appState.perform(.bathe, oneShot: .bath)
                }
                actionBubble(icon: "trash.fill", tint: .brown) {
                    appState.perform(.cleanWaste, oneShot: .clean)
                }
                if appState.pet.sickness == .sick {
                    actionBubble(icon: "pills.fill", tint: .pink) {
                        appState.perform(.medicine, oneShot: .medicine)
                    }
                }
            case .interaction:
                actionBubble(icon: "hand.wave.fill", tint: .yellow) {
                    appState.perform(.pet, oneShot: .pet)
                }
                actionBubble(icon: "gamecontroller.fill", tint: .purple) {
                    appState.perform(.play, oneShot: .play)
                }
                if appState.pet.emotion.requiresApology {
                    actionBubble(icon: "heart.fill", tint: .red) {
                        appState.perform(.apologize, oneShot: .apologize)
                    }
                }
            case .dialogue:
                if appState.pet.unlocked.vocabularyBudding {
                    actionBubble(icon: "bubble.left.fill", tint: .mint) {
                        appState.speak(topic: .greeting)
                    }
                    actionBubble(icon: "clock.arrow.circlepath", tint: .indigo) {
                        appState.speak(topic: .memory)
                    }
                    actionBubble(icon: "leaf.fill", tint: .teal) {
                        appState.speak(topic: .comfort)
                    }
                }
            case .assistant:
                if appState.pet.unlocked.lifeAssistant {
                    actionBubble(icon: "alarm.fill", tint: .orange) {
                        appState.playAssistantAnimation(.alarm)
                    }
                    actionBubble(icon: "book.fill", tint: .blue) {
                        appState.playAssistantAnimation(.study)
                    }
                    actionBubble(icon: "checkmark.circle.fill", tint: .green) {
                        appState.playAssistantAnimation(.studyDone)
                    }
                    actionBubble(icon: "figure.run", tint: .cyan) {
                        appState.playAssistantAnimation(.exercise)
                    }
                }
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: selectedModule)
    }

    private func actionBubble(icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        PetActionBubble(icon: icon, tint: tint, size: 50, action: action)
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
        .zIndex(20)
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
        VStack(alignment: .trailing, spacing: 7) {
            ForEach(appState.pet.stats.indicatorItems()) { item in
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: item.level.iconName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(levelColor(item))
                        Text(L10n.text(item.kind.l10nKey, language: lang))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.88))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    HStack(spacing: 2) {
                        ForEach(0..<6, id: \.self) { i in
                            Capsule()
                                .fill(i <= item.level.rawValue ? levelColor(item) : Color.primary.opacity(0.12))
                                .frame(width: 9, height: 3.5)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 14)
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
