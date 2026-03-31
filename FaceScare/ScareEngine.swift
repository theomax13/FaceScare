import AVFoundation
import AppKit

/// ScareEngine handles the jump-scare effect: a loud scary sound + red screen flash.
///
/// It manages a cooldown timer to avoid spamming scares and picks a random sound
/// from the bundled set on each trigger.
final class ScareEngine {

    // MARK: - Configuration

    /// Cooldown between scares in seconds (default 10s).
    var cooldownInterval: TimeInterval = 10.0

    // MARK: - Internal State

    private var audioPlayer: AVAudioPlayer?
    private var lastScareTime: Date = .distantPast
    private var flashWindow: NSWindow?

    /// Counter for analytics / metrics tracking.
    private(set) var totalScaresTriggered: Int = 0

    // MARK: - Sound Files

    /// Bundled scary sound filenames.
    /// ⚠️ DROP YOUR REAL AUDIO FILES HERE:
    ///   1. Add scare1.mp3, scare2.mp3, scare3.mp3 to the FaceScare/Resources/ folder
    ///   2. Make sure they are included in the Xcode target's "Copy Bundle Resources" build phase
    ///   3. Recommended: short (1-3s), loud, startling sounds (scream, bang, horror sting)
    private let soundFileNames = ["scare1"]

    // MARK: - Public API

    /// Trigger a jump-scare if cooldown has elapsed.
    func triggerScare() {
        guard canScare() else { return }

        lastScareTime = Date()
        totalScaresTriggered += 1

        playRandomScarySound()
        flashScreen()
    }

    // MARK: - Cooldown

    private func canScare() -> Bool {
        Date().timeIntervalSince(lastScareTime) >= cooldownInterval
    }

    // MARK: - Sound Playback

    private func playRandomScarySound() {
        guard let randomName = soundFileNames.randomElement(),
              let url = Bundle.main.url(forResource: randomName, withExtension: "mp3")
        else {
            // Fallback: play the system alert sound if no audio files are bundled
            NSSound.beep()
            print("[FaceScare] ⚠️ No sound file found. Add scare1.mp3, scare2.mp3, scare3.mp3 to Resources/")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 1.0 // Maximum volume for maximum scare
            audioPlayer?.play()
        } catch {
            print("[FaceScare] Failed to play sound: \(error.localizedDescription)")
            NSSound.beep()
        }
    }

    // MARK: - Screen Flash

    /// Displays `jump-scare.png` full-screen for a brief moment (500ms).
    /// Falls back to a red overlay if the image is missing from the bundle.
    private func flashScreen() {
        guard let screen = NSScreen.main else { return }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver          // Above everything
        window.isOpaque = false
        window.ignoresMouseEvents = true      // Click-through
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        if let imageURL = Bundle.main.url(forResource: "jump-scare", withExtension: "png"),
           let image = NSImage(contentsOf: imageURL) {
            // Show the jump-scare image scaled to fill the entire screen
            let imageView = NSImageView(frame: screen.frame)
            imageView.image = image
            imageView.imageScaling = .scaleAxesIndependently
            imageView.imageAlignment = .alignCenter
            window.contentView = imageView
            window.backgroundColor = .black
        } else {
            // Fallback: red flash if jump-scare.png is missing
            window.backgroundColor = NSColor.red.withAlphaComponent(0.6)
            print("[FaceScare] ⚠️ jump-scare.png not found in bundle. Using red flash fallback.")
        }

        window.orderFrontRegardless()
        self.flashWindow = window

        // Dismiss after 500ms (slightly longer to let the image register)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.flashWindow?.orderOut(nil)
            self?.flashWindow = nil
        }
    }
}
