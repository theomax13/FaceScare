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

    // MARK: - Custom Sound Directory

    /// Default directory where the user can drop custom `scare*.mp3` files.
    /// Located at ~/Library/Application Support/FaceScare/
    static var defaultCustomSoundDirectory: URL {
        defaultCustomImageDirectory // Same directory
    }

    /// Discovers all `scare*.mp3` files in the given directory.
    /// If the custom directory has scare files, returns those.
    /// Otherwise falls back to bundle resources.
    static func resolveScareSoundURLs(customDirectory: URL? = nil) -> [URL] {
        let directory = customDirectory ?? defaultCustomSoundDirectory

        // Scan custom directory for scare*.mp3 files
        if let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) {
            let scareFiles = contents.filter { url in
                url.lastPathComponent.hasPrefix("scare") && url.pathExtension == "mp3"
            }
            if !scareFiles.isEmpty {
                return scareFiles
            }
        }

        // Fallback: look in the bundle
        guard let bundleURL = Bundle.main.url(forResource: "scare1", withExtension: "mp3") else {
            return []
        }
        return [bundleURL]
    }

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
        let soundURLs = ScareEngine.resolveScareSoundURLs()

        guard let url = soundURLs.randomElement() else {
            NSSound.beep()
            print("[FaceScare] No scare*.mp3 file found. Add files to ~/Library/Application Support/FaceScare/")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 1.0
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
