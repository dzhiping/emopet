import AVFoundation
import Combine
import EmoPetKit
import SwiftUI
import UIKit

// MARK: - 透明 HEVC 视频播放（Alpha 通道 .mov）

struct TransparentVideoPlayer: UIViewRepresentable {
    let player: AVQueuePlayer?
    var allowsPetHitTesting: Bool = false

    func makeUIView(context: Context) -> AlphaVideoPlayerUIView {
        let view = AlphaVideoPlayerUIView()
        view.backgroundColor = .clear
        view.playerLayer.videoGravity = .resizeAspect
        view.allowsPetHitTesting = allowsPetHitTesting
        return view
    }

    func updateUIView(_ uiView: AlphaVideoPlayerUIView, context: Context) {
        uiView.player = player
        uiView.allowsPetHitTesting = allowsPetHitTesting
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

    private var species: PetSpeciesID = .cat
    private var looper: AVPlayerLooper?
    private var preloadedAssets: [String: AVURLAsset] = [:]
    private var endWatchTask: Task<Void, Never>?

    deinit {
        endWatchTask?.cancel()
    }

    func preload(species: PetSpeciesID) {
        self.species = species
        for clip in PetAnimationCatalog.preloadClips(species: species) {
            guard let url = resolveURL(for: clip) else { continue }
            let asset = AVURLAsset(url: url)
            preloadedAssets[clip.bundleSubpath] = asset
            Task {
                _ = try? await asset.load(.isPlayable)
            }
        }
    }

    func sync(snapshot: PetSnapshot) {
        species = snapshot.speciesID
        let target = PetLoopState.from(visual: PetVisualStateResolver.resolve(snapshot: snapshot))
        if target != currentLoopState {
            transition(to: target)
        }
    }

    func playOneShot(_ action: PetOneShotAction) {
        guard hasAsset(for: PetAnimationCatalog.oneShot(action, species: species)) else { return }
        let clip = PetAnimationCatalog.oneShot(action, species: species)
        playClip(clip, thenReturnToLoop: currentLoopState)
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
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            self?.startLoop(resume)
        }
    }

    func hasAsset(for clip: PetVideoClip) -> Bool {
        resolveURL(for: clip) != nil
    }

    func hasOneShot(_ action: PetOneShotAction) -> Bool {
        hasAsset(for: PetAnimationCatalog.oneShot(action, species: species))
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
    }

    private func playClip(_ clip: PetVideoClip, thenReturnToLoop state: PetLoopState) {
        playClip(clip) { [weak self] in
            self?.startLoop(state)
        }
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
        observeEnd(of: item, handler: onComplete)
        queuePlayer.play()
    }

    private func installLoop(url: URL) {
        tearDownLooper()
        let item = AVPlayerItem(asset: asset(for: url, clip: nil))
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        queuePlayer.play()
    }

    private func asset(for url: URL, clip: PetVideoClip?) -> AVURLAsset {
        if let clip, let cached = preloadedAssets[clip.bundleSubpath] { return cached }
        return AVURLAsset(url: url)
    }

    private func resolveURL(for clip: PetVideoClip) -> URL? {
        Bundle.main.url(
            forResource: clip.relativePath,
            withExtension: clip.fileExtension,
            subdirectory: "PetVideos"
        )
    }

    private func observeEnd(of item: AVPlayerItem, handler: @escaping () -> Void) {
        endWatchTask?.cancel()
        endWatchTask = Task { @MainActor in
            for await _ in NotificationCenter.default.notifications(
                named: .AVPlayerItemDidPlayToEndTime,
                object: item
            ) {
                guard !Task.isCancelled else { return }
                handler()
                break
            }
        }
    }

    private func tearDownLooper() {
        endWatchTask?.cancel()
        endWatchTask = nil
        looper?.disableLooping()
        looper = nil
        queuePlayer.pause()
        queuePlayer.removeAllItems()
    }

    private func stopPlayback() {
        tearDownLooper()
    }
}
