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

    // MARK: - Custom Image Directory

    /// Default directory where the user can drop a custom `jump-scare.png`.
    /// Located at ~/Library/Application Support/FaceScare/
    static var defaultCustomImageDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FaceScare")
    }

    /// Resolves the URL for `jump-scare.png`, checking the custom directory first, then the bundle.
    /// Returns `nil` if the image is not found in either location.
    static func resolveScareImageURL(customDirectory: URL? = nil) -> URL? {
        let directory = customDirectory ?? defaultCustomImageDirectory
        let customURL = directory.appendingPathComponent("jump-scare.png")

        if FileManager.default.fileExists(atPath: customURL.path) {
            return customURL
        }

        return Bundle.main.url(forResource: "jump-scare", withExtension: "png")
    }

    // MARK: - Screen Flash

    /// Displays `jump-scare.png` full-screen for a brief moment.
    /// Checks ~/Library/Application Support/FaceScare/ first, then falls back to the bundle.
    /// Falls back to a red overlay if the image is missing or unreadable.
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

        if let imageURL = ScareEngine.resolveScareImageURL(),
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
            window.backgroundColor = NSColor.red.withAlphaComponent(2.5)
            print("[FaceScare] jump-scare.png not found. Using red flash fallback.")
        }

        window.orderFrontRegardless()
        self.flashWindow = window

        // Dismiss after 2.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.flashWindow?.orderOut(nil)
            self?.flashWindow = nil
        }
    }
}
