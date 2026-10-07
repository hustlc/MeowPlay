import AVFoundation
import Combine
import Foundation

enum AudioPlaybackError: LocalizedError {
    case assetMissing(String)
    case cannotPlay(String)

    var errorDescription: String? {
        switch self {
        case .assetMissing(let name):
            "Audio coming soon. The production asset \(name) is not in this build."
        case .cannotPlay(let detail):
            "This sound could not be played: \(detail)"
        }
    }
}

@MainActor
final class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var playingSoundID: String?
    @Published private(set) var cooldownSoundID: String?
    @Published var errorMessage: String?

    private var player: AVAudioPlayer?
    private var cooldownTask: Task<Void, Never>?
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        cooldownTask?.cancel()
    }

    func play(_ card: SoundCard) -> Bool {
        guard cooldownSoundID != card.id else { return false }
        stop()

        let asset = card.assetName as NSString
        let fileExtension = asset.pathExtension
        let baseName = asset.deletingPathExtension
        guard let url = bundle.url(
            forResource: baseName,
            withExtension: fileExtension.isEmpty ? nil : fileExtension,
            subdirectory: "Audio"
        ) ?? bundle.url(forResource: baseName, withExtension: fileExtension.isEmpty ? nil : fileExtension) else {
            errorMessage = AudioPlaybackError.assetMissing(card.assetName).localizedDescription
            return false
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)

            let nextPlayer = try AVAudioPlayer(contentsOf: url)
            nextPlayer.delegate = self
            nextPlayer.numberOfLoops = 0
            nextPlayer.prepareToPlay()
            guard nextPlayer.play() else {
                throw AudioPlaybackError.cannotPlay("The device declined playback.")
            }
            player = nextPlayer
            playingSoundID = card.id
            errorMessage = nil
            beginCooldown(for: card.id)
            return true
        } catch {
            errorMessage = error.localizedDescription
            playingSoundID = nil
            return false
        }
    }

    func stop() {
        player?.stop()
        player = nil
        playingSoundID = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
        playingSoundID = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let rawValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawValue),
            type == .began
        else { return }
        stop()
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard
            let rawValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: rawValue),
            reason == .oldDeviceUnavailable
        else { return }
        stop()
    }

    private func beginCooldown(for soundID: String) {
        cooldownTask?.cancel()
        cooldownSoundID = soundID
        cooldownTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            self?.cooldownSoundID = nil
        }
    }
}
