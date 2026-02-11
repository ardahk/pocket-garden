import Foundation
import AVFoundation
import Observation

enum AmbientSoundType: String, CaseIterable, Identifiable {
    case nature = "Nature"
    case rain = "Rain"
    case whiteNoise = "White Noise"
    case lofi = "Lofi"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .nature:
            return "leaf.fill"
        case .rain:
            return "cloud.rain.fill"
        case .whiteNoise:
            return "waveform"
        case .lofi:
            return "headphones"
        }
    }

    // Base filenames in the app bundle (without extension)
    // Multiple entries allow alternating tracks for the same button (e.g. lofi)
    var fileNames: [String] {
        switch self {
        case .nature:
            // @/Users/arda/pocket-garden/music/nature.mp3
            return ["nature"]
        case .rain:
            // @/Users/arda/pocket-garden/music/rain.mp3
            return ["rain"]
        case .whiteNoise:
            // @/Users/arda/pocket-garden/music/white_noise.mp3
            return ["white_noise"]
        case .lofi:
            // @/Users/arda/pocket-garden/music/lofi1.mp3 and lofi2.mp3
            return ["lofi1", "lofi2"]
        }
    }
}

@Observable
class AmbientSoundService {
    private var audioPlayer: AVAudioPlayer?
    private(set) var isPlaying: Bool = false
    private(set) var currentSound: AmbientSoundType?

    // Volume control (0.0–1.0)
    var volume: Float = 0.5 {
        didSet {
            audioPlayer?.volume = volume
        }
    }

    // Fade + track rotation state
    private var fadeTask: Task<Void, Never>?
    private var nextIndexes: [AmbientSoundType: Int] = [:]

    init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    // MARK: - Public control

    func play(_ soundType: AmbientSoundType) {
        // Immediately stop any current sound (we'll fade in the new one)
        stop(immediate: true)

        guard let soundURL = nextURL(for: soundType) else {
            print("Sound file not found for \(soundType.rawValue)")
            currentSound = soundType
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 0.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            isPlaying = true
            currentSound = soundType

            // Gentle fade-in to target volume
            fade(to: volume, duration: 1.5)
        } catch {
            print("Failed to play sound: \(error)")
        }
    }

    func stop() {
        stop(immediate: false)
    }

    func toggle(_ soundType: AmbientSoundType) {
        if currentSound == soundType && isPlaying {
            stop()
        } else {
            play(soundType)
        }
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    func resume() {
        audioPlayer?.play()
        isPlaying = true
    }

    // Fade out and stop (for graceful exits)
    func fadeOutAndStop(duration: TimeInterval = 1.2) {
        stop(immediate: false)
    }

    // Immediate stop (for app lifecycle)
    func stopImmediate() {
        stop(immediate: true)
    }

    // MARK: - Helpers

    private func nextURL(for soundType: AmbientSoundType) -> URL? {
        let names = soundType.fileNames
        guard !names.isEmpty else { return nil }

        // Rotate through available files for this sound type (e.g. lofi1, lofi2)
        let index = nextIndexes[soundType, default: 0]
        let name = names[min(index, names.count - 1)]
        nextIndexes[soundType] = (index + 1) % names.count

        return Bundle.main.url(forResource: name, withExtension: "mp3")
    }

    private func stop(immediate: Bool) {
        guard let player = audioPlayer else { return }

        if immediate {
            fadeTask?.cancel()
            player.stop()
            audioPlayer = nil
            isPlaying = false
            currentSound = nil
            return
        }

        // Gentle fade-out, then stop
        fade(to: 0.0, duration: 1.2) { [weak self] in
            guard let self, let player = self.audioPlayer else { return }
            player.stop()
            self.audioPlayer = nil
            self.isPlaying = false
            self.currentSound = nil
        }
    }

    private func fade(to targetVolume: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        fadeTask?.cancel()

        guard let player = audioPlayer else {
            completion?()
            return
        }

        let startVolume = player.volume
        let startTime = Date()

        if duration <= 0 || startVolume == targetVolume {
            player.volume = targetVolume
            completion?()
            return
        }

        fadeTask = Task { @MainActor in
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(elapsed / duration, 1.0)
                
                let newVolume = startVolume + Float(progress) * (targetVolume - startVolume)
                player.volume = newVolume
                
                if progress >= 1.0 {
                    completion?()
                    break
                }
                
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }
}
