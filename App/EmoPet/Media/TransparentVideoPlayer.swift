import AVFoundation
import Combine
import EmoPetKit
import SwiftUI
import UIKit

// MARK: - 透明 HEVC 视频播放（Alpha 通道 .mov）

struct TransparentVideoPlayer: UIViewRepresentable {
    let player: AVQueuePlayer?
    var allowsPetHitTesting: Bool = false
    var fillScreen: Bool = false

    func makeUIView(context: Context) -> AlphaVideoPlayerUIView {
        let view = AlphaVideoPlayerUIView()
        view.backgroundColor = .clear
        view.playerLayer.videoGravity = fillScreen ? .resizeAspectFill : .resizeAspect
        view.allowsPetHitTesting = allowsPetHitTesting
        return view
    }

    func updateUIView(_ uiView: AlphaVideoPlayerUIView, context: Context) {
        uiView.player = player
        uiView.allowsPetHitTesting = allowsPetHitTesting
        uiView.playerLayer.videoGravity = fillScreen ? .resizeAspectFill : .resizeAspect
        if let player, player.rate == 0, player.currentItem != nil {
            player.play()
        }
    }
}

final class AlphaVideoPlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    var player: AVQueuePlayer? {
        get { playerLayer.player as? AVQueuePlayer }
        set {
            playerLayer.player = newValue
            playerLayer.backgroundColor = UIColor.clear.cgColor
        }
    }

    var allowsPetHitTesting = false

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    /// 透明视频全帧会拦截手势；默认仅中央宠物区域可点（或完全穿透）
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard allowsPetHitTesting, bounds.contains(point) else { return nil }
        let petZone = bounds.insetBy(
            dx: bounds.width * 0.18,
            dy: bounds.height * 0.22
        )
        return petZone.contains(point) ? self : nil
    }
}

// MARK: - 2.5D 宠物素材状态机

@MainActor
final class PetAssetManager: ObservableObject {
    @Published private(set) var queuePlayer = AVQueuePlayer()
    @Published private(set) var currentLoopState: PetLoopState = .idle
    @Published private(set) var hasVideoAsset = false
    @Published private(set) var useFallbackRenderer = true
    /// 递增以强制 SwiftUI 刷新 AVPlayerLayer
    @Published private(set) var playbackRevision = 0

    private var species: PetSpeciesID = .cat
    private var looper: AVPlayerLooper?
    private var preloadedAssets: [String: AVURLAsset] = [:]
    private var itemEndCancellable: AnyCancellable?
    private var isPlayingOneShot = false
    /// 物种目录内扫描到的任意视频（支持中文等非规范文件名）
    private var discoveredVideos: [PetSpeciesID: URL] = [:]

    init() {
        queuePlayer.automaticallyWaitsToMinimizeStalling = false
        configureAudioSession()
    }

    var hasBundledVideo: Bool {
        resolveURL(for: PetAnimationCatalog.idleLoop(species: species, state: .idle)) != nil
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func bumpPlaybackRevision() {
        playbackRevision &+= 1
    }

    func preload(species: PetSpeciesID) {
        self.species = species
        discoveredVideos[species] = discoverAnyVideo(for: species)
        for clip in PetAnimationCatalog.preloadClips(species: species) {
            guard let url = resolveURL(for: clip) else { continue }
            cacheAsset(url: url, clip: clip)
        }
        if let fallback = discoveredVideos[species] {
            cacheAsset(url: fallback, clip: nil)
        }
    }

    /// 进入主页或 App 回到前台时确保视频层可见并播放
    func activatePlayback(with snapshot: PetSnapshot) {
        species = snapshot.speciesID
        if discoveredVideos[species] == nil {
            discoveredVideos[species] = discoverAnyVideo(for: species)
        }
        let target = PetLoopState.from(visual: PetVisualStateResolver.resolve(snapshot: snapshot))
        if hasBundledVideo {
            if isPlayingOneShot {
                queuePlayer.play()
                useFallbackRenderer = false
                hasVideoAsset = true
            } else if !hasVideoAsset || useFallbackRenderer {
                startLoop(target)
            } else {
                queuePlayer.play()
            }
            bumpPlaybackRevision()
        } else if !isPlayingOneShot {
            useFallbackRenderer = true
            hasVideoAsset = false
        }
    }

    func sync(snapshot: PetSnapshot) {
        guard !isPlayingOneShot else { return }
        species = snapshot.speciesID
        let target = PetLoopState.from(visual: PetVisualStateResolver.resolve(snapshot: snapshot))
        if target != currentLoopState {
            transition(to: target)
        } else if useFallbackRenderer, hasBundledVideo {
            startLoop(target)
        }
    }

    func playOneShot(_ action: PetOneShotAction, resumeWith snapshot: PetSnapshot? = nil) {
        let clip = PetAnimationCatalog.oneShot(action, species: species)
        guard resolveURL(for: clip) != nil else { return }
        isPlayingOneShot = true
        playClip(clip) { [weak self] in
            guard let self else { return }
            self.isPlayingOneShot = false
            if let snapshot {
                self.sync(snapshot: snapshot)
            } else {
                self.startLoop(self.currentLoopState)
            }
        }
    }

    /// 播放对话/助手专用 Idle；`duration` 秒后回到生理状态循环
    func playSpecialLoop(_ loop: PetSpecialLoop, duration: TimeInterval = 4.0) {
        let clip = PetAnimationCatalog.specialLoop(loop, species: species)
        guard let url = resolveURL(for: clip) else { return }
        let resume = currentLoopState
        tearDownLooper()
        let item = AVPlayerItem(asset: asset(for: url, clip: clip))
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        queuePlayer.play()
        hasVideoAsset = true
        useFallbackRenderer = false
        bumpPlaybackRevision()
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            self?.startLoop(resume)
        }
    }

    func hasAsset(for clip: PetVideoClip) -> Bool {
        resolveURL(for: clip) != nil
    }

    func hasOneShot(_ action: PetOneShotAction) -> Bool {
        resolveURL(for: PetAnimationCatalog.oneShot(action, species: species)) != nil
    }

    func transition(to newState: PetLoopState) {
        let fromState = currentLoopState
        guard fromState != newState else { return }

        if let trans = PetAnimationCatalog.transition(from: fromState, to: newState, species: species),
           resolveURL(for: trans) != nil {
            playClip(trans) { [weak self] in
                self?.startLoop(newState)
            }
        } else {
            startLoop(newState)
        }
    }

    func startLoop(_ state: PetLoopState) {
        currentLoopState = state
        let clip = PetAnimationCatalog.idleLoop(species: species, state: state)
        guard let url = resolveURL(for: clip) else {
            hasVideoAsset = false
            useFallbackRenderer = true
            stopPlayback()
            return
        }
        hasVideoAsset = true
        useFallbackRenderer = false
        installLoop(url: url)
        bumpPlaybackRevision()
    }

    private func playClip(_ clip: PetVideoClip, onComplete: @escaping () -> Void) {
        guard let url = resolveURL(for: clip) else {
            onComplete()
            return
        }
        tearDownLooper()
        let item = AVPlayerItem(asset: asset(for: url, clip: clip))
        queuePlayer.removeAllItems()
        queuePlayer.insert(item, after: nil)
        hasVideoAsset = true
        useFallbackRenderer = false
        bumpPlaybackRevision()
        observeEnd(of: item, handler: onComplete)
        queuePlayer.play()
    }

    private func installLoop(url: URL) {
        tearDownLooper()
        let item = AVPlayerItem(asset: asset(for: url, clip: nil))
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        queuePlayer.play()
        bumpPlaybackRevision()
    }

    private func asset(for url: URL, clip: PetVideoClip?) -> AVURLAsset {
        if let clip, let cached = preloadedAssets[clip.bundleSubpath] { return cached }
        let key = url.lastPathComponent
        if let cached = preloadedAssets[key] { return cached }
        return AVURLAsset(url: url)
    }

    private func cacheAsset(url: URL, clip: PetVideoClip?) {
        let asset = AVURLAsset(url: url)
        if let clip {
            preloadedAssets[clip.bundleSubpath] = asset
        } else {
            preloadedAssets[url.lastPathComponent] = asset
        }
        Task {
            _ = try? await asset.load(.isPlayable)
        }
    }

    /// 精确命名 → 同物种 Idle 默认 → 文件夹内任意 .mov/.mp4
    private func resolveURL(for clip: PetVideoClip) -> URL? {
        if let url = PetAnimationCatalog.resolveBundledURL(for: clip, species: species) {
            return url
        }
        if let stateClip = stateSpecificURL(for: clip) {
            return stateClip
        }
        return discoveredVideos[species] ?? discoverAnyVideo(for: species)
    }

    ///  hungry/happy 等状态片缺失时，尝试同物种其他 Idle 循环
    private func stateSpecificURL(for clip: PetVideoClip) -> URL? {
        guard clip.relativePath.hasPrefix("\(species.rawValue)/Idle_") else { return nil }
        for state in PetLoopState.allCases {
            let candidate = PetAnimationCatalog.idleLoop(species: species, state: state)
            if candidate.relativePath == clip.relativePath { continue }
            if let url = PetAnimationCatalog.resolveBundledURL(
                for: candidate,
                species: species,
                allowSpeciesFallback: false
            ) {
                return url
            }
        }
        return nil
    }

    private func discoverAnyVideo(for species: PetSpeciesID) -> URL? {
        guard let folder = Bundle.main.url(
            forResource: species.rawValue,
            withExtension: nil,
            subdirectory: "PetVideos"
        ) else { return nil }

        guard let items = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        return items
            .filter { ["mov", "mp4"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .first
    }

    private func observeEnd(of item: AVPlayerItem, handler: @escaping () -> Void) {
        itemEndCancellable?.cancel()
        itemEndCancellable = NotificationCenter.default.publisher(
            for: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
        .first()
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.itemEndCancellable = nil
            handler()
        }
    }

    private func tearDownLooper() {
        itemEndCancellable?.cancel()
        itemEndCancellable = nil
        looper?.disableLooping()
        looper = nil
        queuePlayer.pause()
        queuePlayer.removeAllItems()
    }

    private func stopPlayback() {
        tearDownLooper()
    }
}
