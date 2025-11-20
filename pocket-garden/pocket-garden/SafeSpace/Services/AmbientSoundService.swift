import Foundation
import AVFoundation
import Observation

enum AmbientSoundType: String, CaseIterable, Identifiable {
    case nature = "Nature"
    case music = "Music"
    case night = "Night"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .nature: return "leaf.fill"
        case .music: return "music.note"
        case .night: return "moon.zzz.fill"
        }
    }

    // Filename in Resources/Sounds/ directory (without extension)
    var fileName: String {
        switch self {
        case .nature: return "ambient-nature"
        case .music: return "ambient-music"
        case .night: return "ambient-night"
        }
    }
}

@Observable
class AmbientSoundService {
    private var audioPlayer: AVAudioPlayer?
    private(set) var isPlaying: Bool = false
    private(set) var currentSound: AmbientSoundType?
    var volume: Float = 0.5 {
        didSet {
            audioPlayer?.volume = volume
        }
    }

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

    func play(_ soundType: AmbientSoundType) {
        // Stop current sound if playing
        stop()

        // Get sound file
        let fileName = soundType.fileName
        guard let soundURL = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Sound file not found for \(soundType.rawValue)")
            // User needs to add sound files - continue silently
            currentSound = soundType
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            isPlaying = true
            currentSound = soundType
        } catch {
            print("Failed to play sound: \(error)")
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentSound = nil
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
}
