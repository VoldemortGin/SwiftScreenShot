//
//  SoundManager.swift
//  SwiftScreenShot
//
//  Sound feedback manager for screenshot capture
//

import AppKit
import AVFoundation

class SoundManager {
    static let shared = SoundManager()

    private var captureSound: NSSound?

    private init() {
        setupCaptureSound()
    }

    /// Setup capture sound effect
    private func setupCaptureSound() {
        // Use macOS system camera shutter sound
        // Path: /System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/begin_record.caf
        if let soundURL = Bundle.main.url(forResource: "capture", withExtension: "aiff") {
            captureSound = NSSound(contentsOf: soundURL, byReference: true)
        } else {
            // Fallback to system sound
            captureSound = NSSound(named: "Pop")
        }

        // Configure sound properties
        captureSound?.volume = 0.5 // Moderate volume
    }

    /// Play screenshot capture sound
    func playCapture() {
        AppLogger.shared.debug("Playing capture sound", category: .sound)
        // Play on background thread to avoid blocking
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let sound = self?.captureSound else {
                AppLogger.shared.warning("Capture sound not available", category: .sound)
                return
            }

            // Reset sound to beginning if it was playing
            sound.stop()

            // Play the sound
            sound.play()
        }
    }

    /// Alternative implementation using AVAudioPlayer for more control
    private var audioPlayer: AVAudioPlayer?

    func playSystemShutterSound() {
        // Use system camera shutter sound path
        let systemSoundPath = "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/begin_record.caf"

        if FileManager.default.fileExists(atPath: systemSoundPath) {
            let soundURL = URL(fileURLWithPath: systemSoundPath)

            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.volume = 0.4
                audioPlayer?.prepareToPlay()

                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.audioPlayer?.play()
                }
            } catch {
                AppLogger.shared.error("Failed to play system shutter sound", category: .sound, error: error)
                fallbackToNSSound()
            }
        } else {
            fallbackToNSSound()
        }
    }

    /// Fallback to NSSound if system sound is not available
    private func fallbackToNSSound() {
        captureSound?.play()
    }

    /// Play capture sound based on user preference
    func playCaptureIfEnabled(enabled: Bool) {
        guard enabled else {
            AppLogger.shared.debug("Capture sound disabled in settings", category: .sound)
            return
        }

        // Try system shutter sound first, fallback to NSSound
        if FileManager.default.fileExists(atPath: "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/begin_record.caf") {
            playSystemShutterSound()
        } else {
            playCapture()
        }
    }
}
