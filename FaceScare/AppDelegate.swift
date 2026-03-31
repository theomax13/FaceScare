import Cocoa
import SwiftUI
import AVFoundation

/// AppDelegate manages the app lifecycle for this menu-bar-only application.
///
/// Responsibilities:
/// - Request camera permission on launch
/// - Initialize and wire together FaceDetector, ScareEngine, and StatusBarController
/// - Start/stop face detection based on user preference
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Dependencies

    private var statusBarController: StatusBarController?
    private let faceDetector = FaceDetector()
    private let scareEngine = ScareEngine()
    private let statsStore = StatsStore()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestCameraPermission()

        // Wire up: when FaceDetector fires a proximity event, trigger the scare
        faceDetector.onFaceTooClose = { [weak self] in
            self?.scareEngine.triggerScare()
            self?.statsStore.recordScare()
        }

        // Build the menu bar UI, passing references so it can control settings
        statusBarController = StatusBarController(
            faceDetector: faceDetector,
            scareEngine: scareEngine,
            statsStore: statsStore
        )

        // Start detection by default
        faceDetector.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        faceDetector.stop()
    }

    // MARK: - Camera Permission

    private func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break // Already granted
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    DispatchQueue.main.async {
                        self.showCameraAlert()
                    }
                }
            }
        case .denied, .restricted:
            showCameraAlert()
        @unknown default:
            break
        }
    }

    private func showCameraAlert() {
        let alert = NSAlert()
        alert.messageText = "Camera Access Required"
        alert.informativeText = "FaceScare needs camera access to detect face proximity. Please grant access in System Settings → Privacy & Security → Camera."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Quit")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                NSWorkspace.shared.open(url)
            }
        } else {
            NSApp.terminate(nil)
        }
    }
}
